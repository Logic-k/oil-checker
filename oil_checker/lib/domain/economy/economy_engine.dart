// ignore_for_file: dangling_library_doc_comments
/// 경제성 계산 엔진 (PLAN §4 공식 기반 + 실도로·혼잡 확장)
///
/// - 절약액(원) = (기준 주유소 가격 - 후보 주유소 가격) × 주유량(L)
/// - 연료비용(원) = 우회거리(km) ÷ 연비(km/L) × 후보 주유소 가격(원/L)
///   - 우회거리는 **실제 도로 거리**(OSRM) 기준 (기존 직선거리 → 도로거리)
/// - 시간비용(원) = 예상 우회 시간(분) × 시간 가치(원/분)
///   - 예상 우회 시간에는 시간대별 **교통 혼잡 가중치** 반영
/// - 우회비용(원) = 연료비용 + 시간비용
/// - 경제성 점수(원) = 절약액 - 우회비용 (양수일 때만 "절약")
///
/// 우회거리 규칙:
/// - 목적지 설정 시: 내위치→후보→목적지 (편도)
/// - 목적지 미설정 시: 내위치→후보→복귀 (왕복 2배)

/// 경제성 점수를 가진 객체의 공통 인터페이스 — 타입 안정 정렬용.
abstract interface class HasScore {
  double get score;
}

class EconomyResult implements HasScore {
  /// 내부 생성자 — 팩토리 [calculateEconomy]를 통해 만들 것.
  const EconomyResult._({
    required this.savingAmount,
    required this.detourKm,
    required this.driveTimeMin,
    required this.fuelCost,
    required this.timeCost,
  });

  /// 절약액 (원) = (기준가 - 후보가) × 주유량
  final double savingAmount;

  /// 실제 도로 기준 우회거리 (km)
  final double detourKm;

  /// 혼잡 반영 예상 우회 시간 (분)
  final double driveTimeMin;

  /// 연료비용 = (우회거리 ÷ 연비) × 후보 가격
  final double fuelCost;

  /// 시간비용 = 예상 우회 시간(분) × 시간 가치
  final double timeCost;

  /// 우회비용 (원) = 연료비용 + 시간비용
  double get detourCost => fuelCost + timeCost;

  /// 경제성 점수 = 절약액 - 우회비용
  @override
  double get score => savingAmount - detourCost;

  /// 스코어가 양수일 때만 실제 "절약"
  bool get isSavings => score > 0;
}

/// 경제성 점수 계산
///
/// [baselinePrice]: 기준 주유소 가격 (원/L, 보통 현재 가장 가까운 곳)
/// [candidatePrice]: 후보 주유소 가격 (원/L)
/// [fillUpLiters]: 주유량 (L)
/// [detourKm]: 우회거리 (km) — 실제 도로 기준, [computeDetourKm] 결과
/// [driveTimeMin]: 혼잡 반영 예상 우회 시간 (분) — [applyCongestion] 결과
/// [fuelEfficiency]: 차량 연비 (km/L)
/// [timeValueWonPerMin]: 시간 가치 (원/분, 기본 0 = 시간 비용 미반영)
EconomyResult calculateEconomy({
  required int baselinePrice,
  required int candidatePrice,
  required double fillUpLiters,
  required double detourKm,
  required double driveTimeMin,
  required double fuelEfficiency,
  double timeValueWonPerMin = 0,
}) {
  final savingAmount =
      (baselinePrice - candidatePrice) * fillUpLiters;
  final fuelCost = fuelEfficiency <= 0
      ? 0.0
      : (detourKm / fuelEfficiency) * candidatePrice.toDouble();
  final timeCost = driveTimeMin * timeValueWonPerMin;
  return EconomyResult._(
    savingAmount: savingAmount,
    detourKm: detourKm,
    driveTimeMin: driveTimeMin,
    fuelCost: fuelCost,
    timeCost: timeCost,
  );
}

/// 예상 우회 시간에 시간대별 혼잡 가중치를 적용한다.
///
/// [baseDriveMin]: 원활 상태 도로 시간 (분, OSRM duration 기준)
/// [congestionFactor]: [CongestionModel.factorAt] 결과 (1.0~1.5)
double applyCongestion({
  required double baseDriveMin,
  required double congestionFactor,
}) {
  return baseDriveMin * congestionFactor;
}

/// 우회거리 계산
///
/// [fromToStationKm]: 내 위치 → 후보 주유소 거리 (km)
/// [stationToDestinationKm]: 후보 주유소 → 목적지 거리 (km)
///   - null이면 목적지 미설정 → 왕복 2배로 계산
double computeDetourKm({
  required double fromToStationKm,
  double? stationToDestinationKm,
}) {
  final detour = fromToStationKm + (stationToDestinationKm ?? fromToStationKm);
  return detour;
}

/// 경제성 점수 내림차순 정렬 — HasScore 구현체만 허용 (타입 안정).
List<T> rankByEconomy<T extends HasScore>(List<T> stations) {
  final ranked = List<T>.of(stations);
  ranked.sort((a, b) => b.score.compareTo(a.score));
  return ranked;
}
