import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';

/// 실제 Opinet 응답 형식 기반 샘플 (2026-08-02 실측)
const String kSampleResponse = '''
{
  "RESULT": {
    "OIL": [
      {
        "UNI_ID": "A0000232",
        "POLL_DIV_CD": "HDO",
        "OS_NM": "HD현대오일뱅크㈜직영 갈월동주유소",
        "PRICE": 1887,
        "DISTANCE": 2169.5,
        "GIS_X_COOR": 309369.84370,
        "GIS_Y_COOR": 549923.27130
      },
      {
        "UNI_ID": "A0009071",
        "POLL_DIV_CD": "HDO",
        "OS_NM": "HD현대오일뱅크㈜직영 장원주유소",
        "PRICE": 1911,
        "DISTANCE": 2860.7,
        "GIS_X_COOR": 312642.36970,
        "GIS_Y_COOR": 550902.45880
      }
    ]
  }
}
''';

/// 빈 응답 (반경 내 주유소 없음)
const String kEmptyResponse = '''
{
  "RESULT": {
    "OIL": []
  }
}
''';

/// 주유소 상세 응답 (detailById.do — 2026-08-02 실측 형식)
const String kDetailResponse = '''
{
  "RESULT": {
    "OIL": [
      {
        "UNI_ID": "A0001257",
        "POLL_DIV_CO": "GSC",
        "OS_NM": "에너지플러스허브 삼방주유소",
        "VAN_ADR": "서울 노원구 공릉동7가 137",
        "NEW_ADR": "서울 노원구 동일로 27 (공릉동7가)",
        "TEL": "02-953-1448",
        "SIGUNCD": "0105",
        "LPG_YN": "N",
        "MAINT_YN": "N",
        "CAR_WASH_YN": "Y",
        "KPETRO_YN": "N",
        "CVS_YN": "N",
        "GIS_X_COOR": 313874.79321,
        "GIS_Y_COOR": 553300.33345,
        "OIL_PRICE": [
          {"PRODCD": "B027", "PRICE": 1840, "TRADE_DT": "20260802", "TRADE_TM": "105953"},
          {"PRODCD": "D047", "PRICE": 1819, "TRADE_DT": "20260802", "TRADE_TM": "105938"}
        ]
      }
    ]
  }
}
''';

/// 커스텀 HttpClientAdapter — 네트워크 없이 Opinet 응답을 재현
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(
    this.responseBody, {
    this.statusCode = 200,
    this.contentType = 'application/json',
  });

  final String responseBody;
  final int statusCode;
  final String contentType;
  RequestOptions? capturedOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedOptions = options;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {Headers.contentTypeHeader: [contentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('OpinetStation.fromJson', () {
    test('실제 응답 JSON을 파싱한다', () {
      final json = (jsonDecode(kSampleResponse) as Map<String, dynamic>)['RESULT']
          as Map<String, dynamic>;
      final list = (json['OIL'] as List)
          .map((e) => OpinetStation.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list, hasLength(2));
      expect(list[0].uniId, 'A0000232');
      expect(list[0].brandCode, 'HDO');
      expect(list[0].name, 'HD현대오일뱅크㈜직영 갈월동주유소');
      expect(list[0].price, 1887);
      expect(list[0].distanceM, closeTo(2169.5, 0.001));
      expect(list[0].gisX, closeTo(309369.84370, 0.00001));
      expect(list[0].gisY, closeTo(549923.27130, 0.00001));
    });
  });

  group('OpinetClient.fetchStationsAround', () {
    test('code 파라미터와 KATEC 좌표/반경을 쿼리에 포함한다', () async {
      final adapter = _FakeAdapter(kSampleResponse);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      final stations = await client.fetchStationsAround(
        x: 310000,
        y: 552000,
        radiusM: 5000,
      );

      expect(stations, hasLength(2));
      final qp = adapter.capturedOptions!.queryParameters;
      expect(qp['code'], 'TEST_API_KEY');
      expect(qp['x'], 310000);
      expect(qp['y'], 552000);
      expect(qp['radius'], 5000);
      expect(qp['prodcd'], 'B027'); // 기본값 휘발유
      expect(qp['sort'], 1);
      expect(qp['out'], 'json');
      // URL 확인
      expect(adapter.capturedOptions!.path, contains('aroundAll.do'));
    });

    test('apiCode가 null이면 code 파라미터를 생략한다 (웹 프록시 주입 경로)', () async {
      final adapter = _FakeAdapter(kSampleResponse);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: null);

      final stations = await client.fetchStationsAround(x: 310000, y: 552000);

      expect(stations, hasLength(2));
      final qp = adapter.capturedOptions!.queryParameters;
      expect(qp.containsKey('code'), isFalse);
      expect(qp['x'], 310000);
    });

    test('빈 OIL 배열이면 빈 리스트를 반환한다', () async {
      final adapter = _FakeAdapter(kEmptyResponse);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      final stations = await client.fetchStationsAround(x: 1, y: 1);

      expect(stations, isEmpty);
    });

    test('HTTP 오류 시 OpinetException을 던진다', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(kSampleResponse, statusCode: 500);
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      expect(
        () => client.fetchStationsAround(x: 1, y: 1),
        throwsA(isA<OpinetException>()),
      );
    });

    test('text/html Content-Type 응답도 JSON으로 파싱한다 (실기기 회귀)', () async {
      // Opinet은 out=json이어도 Content-Type: text/html; charset=utf-8로 응답한다 (실측).
      // Dio 기본 ResponseType.json은 JSON이 아닌 Content-Type에 대해 디코딩을
      // 생략하고 String을 반환해 Map 캐스팅이 실패했다. ResponseType.plain +
      // 수동 jsonDecode로 해결됐는지 검증한다.
      final adapter = _FakeAdapter(
        kSampleResponse,
        contentType: 'text/html; charset=utf-8',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      final stations = await client.fetchStationsAround(
        x: 310000,
        y: 552000,
      );

      expect(stations, hasLength(2));
      expect(stations.first.name, 'HD현대오일뱅크㈜직영 갈월동주유소');
      // 본문을 raw string으로 받아 직접 파싱해야 한다.
      expect(adapter.capturedOptions!.responseType, ResponseType.plain);
    });
  });

  group('OpinetStationDetail.fromJson', () {
    test('실제 상세 응답 JSON을 파싱한다 (주소·전화·부가서비스·가격)', () {
      final json =
          (jsonDecode(kDetailResponse) as Map<String, dynamic>)['RESULT']
              as Map<String, dynamic>;
      final oil = (json['OIL'] as List).first as Map<String, dynamic>;

      final detail = OpinetStationDetail.fromJson(oil);

      expect(detail.uniId, 'A0001257');
      expect(detail.brandCode, 'GSC'); // POLL_DIV_CO 파싱
      expect(detail.name, '에너지플러스허브 삼방주유소');
      expect(detail.newAddress, '서울 노원구 동일로 27 (공릉동7가)');
      expect(detail.vanAddress, '서울 노원구 공릉동7가 137');
      expect(detail.displayAddress, detail.newAddress); // 도로명 우선
      expect(detail.tel, '02-953-1448');
      expect(detail.hasCarWash, isTrue);
      expect(detail.hasMaintenance, isFalse);
      expect(detail.hasConvenienceStore, isFalse);
      expect(detail.isQualityCertified, isFalse);
      expect(detail.prices['B027'], 1840);
      expect(detail.prices['D047'], 1819);
    });

    test('POLL_DIV_CD가 있으면 우선 사용한다', () {
      final detail = OpinetStationDetail.fromJson({
        'UNI_ID': 'X',
        'POLL_DIV_CD': 'SKE',
        'POLL_DIV_CO': 'GSC',
        'OS_NM': '테스트',
        'VAN_ADR': '',
        'NEW_ADR': '',
        'TEL': '',
        'MAINT_YN': 'N',
        'CAR_WASH_YN': 'N',
        'CVS_YN': 'N',
        'KPETRO_YN': 'N',
        'GIS_X_COOR': 0,
        'GIS_Y_COOR': 0,
        'OIL_PRICE': [],
      });
      expect(detail.brandCode, 'SKE');
    });
  });

  group('OpinetClient.fetchStationDetail', () {
    test('id 파라미터로 detailById.do를 호출한다', () async {
      final adapter = _FakeAdapter(kDetailResponse);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      final detail = await client.fetchStationDetail(uniId: 'A0001257');

      expect(detail, isNotNull);
      expect(detail!.name, '에너지플러스허브 삼방주유소');
      final qp = adapter.capturedOptions!.queryParameters;
      expect(qp['code'], 'TEST_API_KEY');
      expect(qp['id'], 'A0001257');
      expect(qp['out'], 'json');
      expect(adapter.capturedOptions!.path, contains('detailById.do'));
    });

    test('빈 OIL이면 null을 반환한다', () async {
      final adapter = _FakeAdapter(kEmptyResponse);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      final detail = await client.fetchStationDetail(uniId: 'INVALID');

      expect(detail, isNull);
    });

    test('text/html Content-Type 응답도 상세를 파싱한다 (실기기 회귀)', () async {
      final adapter = _FakeAdapter(
        kDetailResponse,
        contentType: 'text/html; charset=utf-8',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = OpinetClient(dio: dio, apiCode: 'TEST_API_KEY');

      final detail = await client.fetchStationDetail(uniId: 'A0001257');

      expect(detail, isNotNull);
      expect(detail!.name, '에너지플러스허브 삼방주유소');
      expect(adapter.capturedOptions!.responseType, ResponseType.plain);
    });
  });
}
