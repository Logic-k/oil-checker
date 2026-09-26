import 'package:latlong2/latlong.dart';

/// 라우팅 추상화 인터페이스 — Phase 2 ADR-1
///
/// `OsrmClient`는 이 인터페이스의 구현체 중 하나.
/// 자가 OSRM, Kakao 다중 경유지 등으로 교체 가능하도록 추상화.
/// `providers.dart`의 `economyRankingProvider`는 이 인터페이스에만 의존.

abstract interface class RoutingClient {
  /// N개 좌표 간 거리(m)와 시간(초) 행렬.
  ///
  /// [points]의 인덱스 i→j 행렬이 반환된다.
  /// 반환: `(distances, durations)` — 각각 `List<List<double>>`.
  Future<({List<List<double>> distances, List<List<double>> durations})> table({
    required List<LatLng> points,
  });
}

/// 라우팅 실패 시 던지는 공통 예외 (OsrmException 등 구현체가 상속/구현).
class RoutingException implements Exception {
  const RoutingException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'RoutingException: $message';
}
