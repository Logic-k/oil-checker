import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/data/db/app_database.dart';
import 'package:oil_checker/data/opinet/opinet_repository.dart';

const String kSampleResponse = '''
{
  "RESULT": {
    "OIL": [
      {
        "UNI_ID": "A0000232",
        "POLL_DIV_CD": "HDO",
        "OS_NM": "갈월동주유소",
        "PRICE": 1887,
        "DISTANCE": 2169.5,
        "GIS_X_COOR": 309369.84370,
        "GIS_Y_COOR": 549923.27130
      },
      {
        "UNI_ID": "A0009071",
        "POLL_DIV_CD": "HDO",
        "OS_NM": "장원주유소",
        "PRICE": 1911,
        "DISTANCE": 2860.7,
        "GIS_X_COOR": 312642.36970,
        "GIS_Y_COOR": 550902.45880
      }
    ]
  }
}
''';

const String kEmptyResponse = '{"RESULT": {"OIL": []}}';

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.responseBody, {this.statusCode = 200});

  final String responseBody;
  final int statusCode;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('OpinetRepository.getStationsAround', () {
    test('캐시가 없으면 API를 호출하고 결과를 캐시에 저장한다', () async {
      final adapter = _CountingAdapter(kSampleResponse);
      final client = OpinetClient(
        dio: Dio()..httpClientAdapter = adapter,
        apiCode: 'TEST_API_KEY',
      );
      final repo = OpinetRepository(
        client: client,
        db: db,
        cacheTtl: const Duration(hours: 6),
      );

      final stations = await repo.getStationsAround(x: 310000, y: 552000);

      expect(adapter.callCount, 1);
      expect(stations, hasLength(2));
      // 캐시에 저장됨
      final cached = await db.getCachedStations(productCode: 'B027');
      expect(cached, hasLength(2));
    });

    test('캐시가 유효(TTL 내)하면 API를 재호출하지 않는다 (S5)', () async {
      final adapter = _CountingAdapter(kSampleResponse);
      final client = OpinetClient(
        dio: Dio()..httpClientAdapter = adapter,
        apiCode: 'TEST_API_KEY',
      );
      final repo = OpinetRepository(
        client: client,
        db: db,
        cacheTtl: const Duration(hours: 6),
      );

      await repo.getStationsAround(x: 310000, y: 552000);
      final second = await repo.getStationsAround(x: 310000, y: 552000);

      expect(adapter.callCount, 1); // 재호출 없음
      expect(second, hasLength(2));
    });

    test('캐시 TTL이 만료되면 API를 재호출한다', () async {
      final adapter = _CountingAdapter(kSampleResponse);
      final client = OpinetClient(
        dio: Dio()..httpClientAdapter = adapter,
        apiCode: 'TEST_API_KEY',
      );
      final repo = OpinetRepository(
        client: client,
        db: db,
        cacheTtl: const Duration(hours: 1),
      );

      await repo.getStationsAround(x: 310000, y: 552000);
      // 캐시 시각을 2시간 전으로 조작
      await db.upsertStationCache([
        StationCacheCompanion.insert(
          uniId: 'A0000232',
          brandCode: 'HDO',
          name: '갈월동주유소',
          price: 1887,
          distanceM: 2169.5,
          gisX: 309369.84370,
          gisY: 549923.27130,
          productCode: 'B027',
          fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        StationCacheCompanion.insert(
          uniId: 'A0009071',
          brandCode: 'HDO',
          name: '장원주유소',
          price: 1911,
          distanceM: 2860.7,
          gisX: 312642.36970,
          gisY: 550902.45880,
          productCode: 'B027',
          fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ]);

      final stations = await repo.getStationsAround(x: 310000, y: 552000);

      expect(adapter.callCount, 2); // 재호출됨
      expect(stations, hasLength(2));
    });

    test('API 실패 시 캐시 폴백으로 데이터를 반환한다 (S2)', () async {
      // 먼저 정상 호출로 캐시 저장
      final goodAdapter = _CountingAdapter(kSampleResponse);
      final goodClient = OpinetClient(
        dio: Dio()..httpClientAdapter = goodAdapter,
        apiCode: 'TEST_API_KEY',
      );
      final repo = OpinetRepository(
        client: goodClient,
        db: db,
        cacheTtl: const Duration(hours: 6),
      );
      await repo.getStationsAround(x: 310000, y: 552000);

      // 그 후 API가 실패하는 클라이언트로 교체 (캐시 만료 상태 만들기 위해 TTL 짧게)
      final badAdapter = _CountingAdapter('err', statusCode: 500);
      final badClient = OpinetClient(
        dio: Dio()..httpClientAdapter = badAdapter,
        apiCode: 'TEST_API_KEY',
      );
      final failingRepo = OpinetRepository(
        client: badClient,
        db: db,
        cacheTtl: Duration.zero, // 즉시 만료
      );

      final stations = await failingRepo.getStationsAround(x: 310000, y: 552000);
      expect(stations, hasLength(2)); // 캐시 폴백
    });

    test('캐시를 읽을 때 현재 위치 기준으로 distanceM을 재계산한다', () async {
      // (310000, 552000) 위치에서 저장된 캐시 — API 거리는 2169.5m/2860.7m
      final adapter = _CountingAdapter(kSampleResponse);
      final client = OpinetClient(
        dio: Dio()..httpClientAdapter = adapter,
        apiCode: 'TEST_API_KEY',
      );
      final repo = OpinetRepository(
        client: client,
        db: db,
        cacheTtl: const Duration(hours: 6),
      );
      await repo.getStationsAround(x: 310000, y: 552000);

      // 위치를 (310000, 552000) 근처의 다른 지점으로 변경해 조회
      // 캐시가 유효하므로 API는 재호출되지 않고, 거리는 KATEC 좌표로 재계산된다.
      final moved = await repo.getStationsAround(x: 310010, y: 552010);

      expect(adapter.callCount, 1); // 캐시 재사용 (API 재호출 없음)
      expect(moved, hasLength(2));
      // distanceM이 저장값과 다른 재계산된 값이다 (저장: 2169.5)
      expect(moved[0].distanceM, isNot(closeTo(2169.5, 0.5)));
    });

    test('요청 반경을 벗어난 캐시 주유소는 제외한다', () async {
      final adapter = _CountingAdapter(kSampleResponse);
      final client = OpinetClient(
        dio: Dio()..httpClientAdapter = adapter,
        apiCode: 'TEST_API_KEY',
      );
      final repo = OpinetRepository(
        client: client,
        db: db,
        cacheTtl: const Duration(hours: 6),
      );
      await repo.getStationsAround(x: 310000, y: 552000);

      // 반경을 100m로 줄이면 모든 캐시 주유소가 범위 밖 → 캐시 무효 → API 재호출
      final tiny = await repo.getStationsAround(
        x: 310000,
        y: 552000,
        radiusM: 100,
      );

      expect(adapter.callCount, 2); // 캐시가 무효화되어 재호출
      expect(tiny, hasLength(2)); // 새 응답 기준
    });
  });
}
