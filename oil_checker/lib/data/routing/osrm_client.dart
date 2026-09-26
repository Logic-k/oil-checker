import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import 'routing_client.dart';

/// OSRM API 호출 실패 시 던지는 예외 — RoutingException 구현
class OsrmException implements RoutingException {
  const OsrmException(this.message, {this.cause});

  @override
  final String message;
  @override
  final Object? cause;

  @override
  String toString() => 'OsrmException: $message';
}

/// 주소지 간 도로 이동 결과 (거리 + 예상 시간)
class RouteLeg {
  const RouteLeg({
    required this.distanceM,
    required this.durationSec,
  });

  /// 실제 도로 거리 (m)
  final double distanceM;

  /// 예상 주행 시간 (초) — 혼잡 미반영 기본값
  final double durationSec;

  /// 예상 주행 시간 (분)
  double get durationMin => durationSec / 60;
}

/// OSRM (Open Source Routing Machine) 공개 라우팅 API 클라이언트
///
/// - 공개 데모 서버: 무료·API 키 불필요·전세계 도로망(OSM 기반)
/// - CORS `*` 허용이라 웹에서 직접 호출 가능 (Opinet과 달리 프록시 불필요)
/// - 사용 정책: 비상업적·1 req/s 이하 (개인용 앱 수준에서 충분)
///
/// `table` 서비스: 한 번의 호출로 N개 좌표 간 **전체 거리/시간 행렬**을
/// 얻는다. 개별 라우팅 N회 대신 1회 호출로 처리해 rate limit을 아낀다.
///
/// 클라이언트 부담 경감:
/// - [minInterval] 이내 연속 호출을 지연시켜 데모 서버 정책(1 req/s)을 준수
/// - 같은 좌표 조합에 대한 행렬을 [cacheTtl] 동안 메모리에 캐시해 재요청 차단
class OsrmClient implements RoutingClient {
  OsrmClient({
    required Dio dio,
    this.baseUrl = defaultBaseUrl,
    this.minInterval = const Duration(seconds: 1),
    this.cacheTtl = const Duration(minutes: 30),
  }) : _dio = dio;

  final Dio _dio;

  /// OSRM 공개 데모 서버 엔드포인트.
  ///
  /// 개인 서버 운영 시 `https://your-host` 로 교체 가능 (동일 API 규격).
  static const String defaultBaseUrl = 'https://router.project-osrm.org';

  final String baseUrl;

  /// 연속 요청 최소 간격 — 데모 서버 정책(1 req/s) 준수용
  final Duration minInterval;

  /// 행렬 결과 캐시 TTL — 같은 좌표 조합의 재요청을 막는다
  final Duration cacheTtl;

  DateTime? _lastRequestAt;
  final Map<String, _CachedMatrix> _cache = {};

  /// N개 좌표 간 거리(m)와 시간(초) 행렬.
  ///
  /// [points]의 인덱스 i→j 행렬이 반환된다. 대칭이 아니므로
  /// 왕복 우회거리는 `dist[i][0] + dist[0][i]`처럼 인덱스를 명시적으로 사용.
  ///
  /// 반환: `(distances, durations)` — 각각 `List<List<double>>`.
  @override
  Future<({List<List<double>> distances, List<List<double>> durations})>
      table({
    required List<LatLng> points,
  }) async {
    if (points.length < 2) {
      throw const OsrmException('최소 2개 좌표가 필요합니다.');
    }

    // 좌표 시그니처 (소수 5자리) — 캐시 키이자 재요청 판별 기준
    final signature = points
        .map((p) =>
            '${p.longitude.toStringAsFixed(5)},${p.latitude.toStringAsFixed(5)}')
        .join(';');

    // 캐시 히트 시 네트워크 호출 없이 즉시 반환
    final now = DateTime.now();
    final cached = _cache[signature];
    if (cached != null && now.difference(cached.fetchedAt) < cacheTtl) {
      return cached.matrix;
    }

    // 스로틀: minInterval 미만 경과 시 남은 시간만큼 대기
    final last = _lastRequestAt;
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < minInterval) {
        await Future<void>.delayed(minInterval - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();

    final coordinates =
        points.map((p) => '${p.longitude},${p.latitude}').join(';');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/table/v1/driving/$coordinates',
        queryParameters: const {
          'annotations': 'distance,duration',
        },
      );

      final code = response.data?['code'] as String?;
      if (code != 'Ok') {
        throw OsrmException('OSRM 응답 오류: code=$code');
      }

      final distances = _parseMatrix(response.data?['distances']);
      final durations = _parseMatrix(response.data?['durations']);
      final matrix = (distances: distances, durations: durations);
      _cache[signature] = _CachedMatrix(matrix, DateTime.now());
      return matrix;
    } on DioException catch (e) {
      throw OsrmException('OSRM API 호출 실패: ${e.message}', cause: e);
    }
  }

  List<List<double>> _parseMatrix(dynamic raw) {
    if (raw is! List) {
      throw const OsrmException('OSRM 행렬 응답이 없습니다.');
    }
    return raw
        .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
        .toList();
  }
}

/// 캐시 엔트리 — 행렬 + 가져온 시각
class _CachedMatrix {
  _CachedMatrix(this.matrix, this.fetchedAt);

  final ({List<List<double>> distances, List<List<double>> durations}) matrix;
  final DateTime fetchedAt;
}
