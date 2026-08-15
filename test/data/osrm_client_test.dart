import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:oil_checker/data/routing/osrm_client.dart';

void main() {
  group('OsrmClient.table', () {
    test('좌표 배열을 세미콜론 좌표 문자열로 변환해 호출한다', () async {
      final dio = Dio(
        BaseOptions(
          // 가짜 어댑터로 네트워크 차단
          baseUrl: 'https://example.invalid',
        ),
      );
      RequestOptions? captured;
      dio.httpClientAdapter = _MockAdapter((request) {
        captured = request;
        return _tableResponse();
      });

      final client = OsrmClient(dio: dio);
      final result = await client.table(
        points: const [
          LatLng(37.5665, 126.978),
          LatLng(37.54, 127.0),
        ],
      );
      expect(captured!.uri.path,
          '/table/v1/driving/126.978,37.5665;127.0,37.54');
      expect(captured!.queryParameters['annotations'], 'distance,duration');
      expect(result.distances[0][1], closeTo(5500, 0.001));
      expect(result.durations[1][0], closeTo(438, 0.001));
    });

    test('2개 미만 좌표는 예외', () {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.httpClientAdapter = _MockAdapter((_) => _tableResponse());
      final client = OsrmClient(dio: dio);
      expect(
        () => client.table(points: const [LatLng(37.5, 126.9)]),
        throwsA(isA<OsrmException>()),
      );
    });

    test('code가 Ok가 아니면 예외', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.httpClientAdapter = _MockAdapter((_) async {
        return Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
          data: {'code': 'InvalidQuery'},
        );
      });
      final client = OsrmClient(dio: dio);
      expect(
        () => client.table(
          points: const [LatLng(37.5, 126.9), LatLng(37.54, 127.0)],
        ),
        throwsA(isA<OsrmException>()),
      );
    });

    test('같은 좌표 조합은 캐시되어 네트워크를 재호출하지 않는다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      var networkCalls = 0;
      dio.httpClientAdapter = _MockAdapter((_) {
        networkCalls++;
        return _tableResponse();
      });

      final client = OsrmClient(
        dio: dio,
        // 캐시/스로틀 검증이므로 간격 지연은 비활성화
        minInterval: Duration.zero,
      );
      const points = [
        LatLng(37.5665, 126.978),
        LatLng(37.54, 127.0),
      ];

      final first = await client.table(points: points);
      final second = await client.table(points: points);
      expect(networkCalls, 1);
      expect(first.distances[0][1], closeTo(5500, 0.001));
      expect(second.distances[0][1], closeTo(5500, 0.001));
    });

    test('minInterval 이내 연속 호출은 지연되어 정책(1 req/s)을 준수한다',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.httpClientAdapter = _MockAdapter((_) => _tableResponse());

      final client = OsrmClient(
        dio: dio,
        minInterval: const Duration(milliseconds: 300),
      );
      const pointsA = [LatLng(37.5665, 126.978), LatLng(37.54, 127.0)];
      const pointsB = [LatLng(37.57, 126.99), LatLng(37.55, 127.01)];

      final stopwatch = Stopwatch()..start();
      await client.table(points: pointsA);
      await client.table(points: pointsB);
      stopwatch.stop();

      // 두 번째 호출은 minInterval(300ms) 이상 기다려야 한다
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(250));
    });
  });
}

/// Dio 요청을 가로채 미리 정의된 응답을 반환하는 테스트 어댑터.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final FutureOr<Response<dynamic>> Function(RequestOptions request) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await _handler(options);
    return ResponseBody.fromString(
      response.data == null ? '' : jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Response<dynamic> _tableResponse() {
  return Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: 200,
    data: {
      'code': 'Ok',
      'distances': [
        [0, 5500],
        [5600, 0],
      ],
      'durations': [
        [0, 420],
        [438, 0],
      ],
    },
  );
}
