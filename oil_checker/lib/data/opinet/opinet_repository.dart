import 'dart:math' as math;

import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/data/db/app_database.dart';

/// Opinet 저장소 — 오프라인 우선 (PLAN §6.3)
///
/// 흐름: 캐시 조회(즉시) → TTL 만료 시에만 Opinet 호출 → DB 갱신 → 반환
/// 캐시 TTL: 가격 갱신 시각(1/2/9/12/16/19시) 직후 1회 호출 → 익일 갱신까지 사용
///
/// 위치 캐시 정책:
/// 캐시된 `distanceM`은 **조회 시점의 위치 기준 상대 거리**라 위치 이동 시 왜곡된다.
/// 따라서 캐시에서 읽을 때는 절대 좌표(gisX/gisY, KATEC 미터)와 현재 위치(x, y)로
/// 거리를 재계산하고, 요청 반경을 벗어난 주유소는 걸러낸다.
/// (KATEC은 미터 단위 평면좌표라 유클리드 거리 = 실제 미터 거리)
class OpinetRepository {
  OpinetRepository({
    required OpinetClient client,
    required AppDatabase db,
    required this.cacheTtl,
  })  : _client = client,
        _db = db;

  final OpinetClient _client;
  final AppDatabase _db;
  final Duration cacheTtl;

  /// 반경 내 주유소 조회 (캐시 우선)
  ///
  /// - 캐시가 유효하면 캐시 반환 (API 미호출) — 위치 기준 거리 재계산
  /// - 캐시 만료면 API 호출 → DB 갱신 → 반환
  /// - API 실패 시 캐시 폴백 (오프라인 우선), 캐시도 없으면 예외
  Future<List<OpinetStation>> getStationsAround({
    required double x,
    required double y,
    int radiusM = 5000,
    String productCode = OpinetClient.productGasoline,
    int sort = 1,
  }) async {
    // 1) 캐시가 유효하면 즉시 반환 (현재 위치 기준 거리 재계산)
    final cached = await _readFreshCache(
      x: x,
      y: y,
      radiusM: radiusM,
      productCode: productCode,
    );
    if (cached != null) return cached;

    // 2) API 호출 → DB 갱신
    try {
      final fresh = await _client.fetchStationsAround(
        x: x,
        y: y,
        radiusM: radiusM,
        productCode: productCode,
        sort: sort,
      );
      await _storeCache(fresh, productCode);
      return fresh;
    } on OpinetException {
      // 3) API 실패 → 캐시 폴백 (만료됐더라도) — 현재 위치 기준 재계산
      final stale = await _readStaleCache(
        x: x,
        y: y,
        radiusM: radiusM,
        productCode: productCode,
      );
      if (stale != null) return stale;
      rethrow;
    }
  }

  /// 유효(TTL 내) 캐시 조회 — 없으면 null
  Future<List<OpinetStation>?> _readFreshCache({
    required double x,
    required double y,
    required int radiusM,
    required String productCode,
  }) async {
    final latest = await _db.getLatestCacheTime(productCode: productCode);
    if (latest == null) return null;
    final age = DateTime.now().difference(latest);
    if (age > cacheTtl) return null;
    return _readStaleCache(
      x: x,
      y: y,
      radiusM: radiusM,
      productCode: productCode,
    );
  }

  /// 만료 여부와 무관하게 저장된 캐시 조회 — 없으면 null
  ///
  /// [x], [y]가 주어지면 KATEC 절대좌표(gisX/gisY)로 거리를 재계산하고
  /// [radiusM] 밖 주유소는 제외한다. 위치 이동 시에도 잘못된 상대 거리를
  /// 쓰지 않도록 하는 핵심 로직.
  Future<List<OpinetStation>?> _readStaleCache({
    required double x,
    required double y,
    required int radiusM,
    required String productCode,
  }) async {
    final rows = await _db.getCachedStations(productCode: productCode);
    if (rows.isEmpty) return null;
    final stations = <OpinetStation>[];
    for (final r in rows) {
      final distanceM = _katcDistance(x: x, y: y, gisX: r.gisX, gisY: r.gisY);
      if (distanceM > radiusM) continue; // 요청 반경 밖 — 제외
      stations.add(
        OpinetStation(
          uniId: r.uniId,
          brandCode: r.brandCode,
          name: r.name,
          price: r.price,
          distanceM: distanceM,
          gisX: r.gisX,
          gisY: r.gisY,
        ),
      );
    }
    return stations.isEmpty ? null : stations;
  }

  /// KATEC 평면좌표(미터) 사이의 유클리드 거리 (m)
  static double _katcDistance({
    required double x,
    required double y,
    required double gisX,
    required double gisY,
  }) {
    final dx = x - gisX;
    final dy = y - gisY;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// API 결과를 캐시 테이블에 저장 (전체 교체)
  Future<void> _storeCache(
    List<OpinetStation> stations,
    String productCode,
  ) async {
    final now = DateTime.now();
    // 기존 캐시 삭제 후 새로 저장 (좌표 변경 대응)
    await (_db.delete(_db.stationCache)
          ..where((t) => t.productCode.equals(productCode)))
        .go();

    if (stations.isEmpty) return;

    await _db.upsertStationCache(
      stations
          .map(
            (s) => StationCacheCompanion.insert(
              uniId: s.uniId,
              brandCode: s.brandCode,
              name: s.name,
              price: s.price,
              distanceM: s.distanceM,
              gisX: s.gisX,
              gisY: s.gisY,
              productCode: productCode,
              fetchedAt: now,
            ),
          )
          .toList(),
    );
  }
}
