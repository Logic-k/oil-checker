/// 거리 표시 포맷 헬퍼
///
/// 1000m 미만은 미터 단위(`840m`), 이상은 킬로미터 단위(`1.2km`)로 표시한다.
/// 사용자 요청: "m나 km 단위를 잘 구분" — 거리 값의 크기에 따라 단위를 바꾼다.
library;

/// 미터 → 사람이 읽기 좋은 문자열
///
/// - `formatDistance(840)` → `'840m'`
/// - `formatDistance(1000)` → `'1.0km'`
/// - `formatDistance(1234)` → `'1.2km'`
String formatDistance(num meters) {
  final m = meters.toDouble();
  if (m < 1000) {
    return '${m.round()}m';
  }
  final km = m / 1000;
  return '${km.toStringAsFixed(1)}km';
}
