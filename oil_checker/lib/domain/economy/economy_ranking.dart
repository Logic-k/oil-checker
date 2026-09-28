import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/traffic/congestion.dart';
import 'package:oil_checker/domain/economy/economy_engine.dart';

/// 경제성 랭킹의 순수 계산부 — 네트워크(OSRM) 결과는 [StationTrip]으로 주입한다.
///
/// 절약액의 두 가지 가정을 화면에 그대로 드러낼 수 있게 값으로 들고 다닌다.
/// - **비교 기준 가격**: 주변 시세(반경 내 가격 중앙값, 기본) 또는 가장 가까운 곳.
///   가장 가까운 한 곳만 기준으로 삼으면 그곳이 비쌀 때 모든 절약액이 부풀려진다.
/// - **1회 주유량**: 최근 주유 기록 평균, 기록이 없으면 40L(탱크가 더 작으면 탱크).
///   탱크 가득을 가정하면 절약액이 최대치로 과장된다.
///
/// 우회비용은 "가장 가까운 주유소를 오가는 비용"보다 **더 드는** 이동비만 센다.
/// 어디서 넣든 주유소까지는 가야 하기 때문이다. 순위(총비용 최소 순)는 비교 기준과
/// 무관하게 같고, 기준은 표시되는 절약액의 크기만 바꾼다.

/// 운전자의 시간 가치 (원/분)
///
/// 0이면 시간 비용 미반영(연료비만). 개인 설정 기능 전까지 상수로 둔다.
/// 참고: 최저시급(2025년 10,030원/시) 기준 약 167원/분.
const double kTimeValueWonPerMin = 80;

/// 주유 기록이 없을 때 쓰는 1회 주유량 (L). 탱크가 더 작으면 탱크 용량.
const double kDefaultFillUpLiters = 40;

/// 주유량 평균에 쓰는 최근 기록 수
const int kFillUpSampleCount = 5;

/// 도로 경로가 없을 때 직선거리로 시간을 추정하는 도심 평균 속도 (km/h)
const double kFallbackSpeedKmh = 40;

/// 절약액 비교 기준
enum SavingsBaseline {
  /// 주변 시세 — 반경 내 주유소 가격의 중앙값 (기본)
  areaMedian,

  /// 가장 가까운 주유소 가격
  nearest,
}

/// 1회 주유량의 근거
enum FillUpBasis {
  /// 최근 주유 기록 평균
  recentHistory,

  /// 기록이 없어 기본값(40L 또는 탱크 용량) 사용
  defaultAmount,
}

/// 절약액 계산에 쓰는 1회 주유량
class FillUpPlan {
  const FillUpPlan({
    required this.liters,
    required this.basis,
    this.sampleCount = 0,
  });

  final double liters;
  final FillUpBasis basis;

  /// [FillUpBasis.recentHistory]일 때 평균에 쓴 기록 수
  final int sampleCount;
}

/// 1회 주유량 결정 — 최근 기록 평균(최대 [kFillUpSampleCount]건) → 기본값.
///
/// [recentLiters]는 최신순. 0 이하·비정상 값은 건너뛴다.
FillUpPlan planFillUp({
  required double tankSizeL,
  Iterable<double> recentLiters = const [],
}) {
  final samples = recentLiters
      .where((l) => l.isFinite && l > 0)
      .take(kFillUpSampleCount)
      .toList();
  if (samples.isNotEmpty) {
    final average = samples.reduce((a, b) => a + b) / samples.length;
    return FillUpPlan(
      liters: average,
      basis: FillUpBasis.recentHistory,
      sampleCount: samples.length,
    );
  }
  final liters = tankSizeL > 0 && tankSizeL < kDefaultFillUpLiters
      ? tankSizeL
      : kDefaultFillUpLiters;
  return FillUpPlan(liters: liters, basis: FillUpBasis.defaultAmount);
}

/// 가격 중앙값 (원/L). 0 이하 가격은 제외, 짝수 개면 가운데 두 값의 평균(반올림).
/// 유효한 가격이 없으면 0.
int medianPrice(Iterable<int> prices) {
  final sorted = prices.where((p) => p > 0).toList()..sort();
  if (sorted.isEmpty) return 0;
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// 직선거리 기준 가장 가까운 주유소 (Opinet DISTANCE)
OpinetStation nearestStation(List<OpinetStation> stations) =>
    stations.reduce((a, b) => a.distanceM <= b.distanceM ? a : b);

/// 주유소까지의 이동 (목적지 없으면 왕복, 있으면 내위치→주유소→목적지)
class StationTrip {
  const StationTrip({
    required this.detourKm,
    required this.driveTimeMin,
    this.isRoad = false,
  });

  /// 이동 거리 (km)
  final double detourKm;

  /// 혼잡 반영 예상 시간 (분)
  final double driveTimeMin;

  /// 실제 도로(OSRM) 기준인지 — false면 직선거리 추정
  final bool isRoad;
}

/// 직선거리 왕복 추정 — 도로 경로를 못 구했을 때의 폴백
StationTrip straightLineTrip(
  OpinetStation station, {
  required double congestionFactor,
}) {
  final detourKm = computeDetourKm(fromToStationKm: station.distanceM / 1000);
  final baseDriveMin = detourKm / kFallbackSpeedKmh * 60;
  return StationTrip(
    detourKm: detourKm,
    driveTimeMin: applyCongestion(
      baseDriveMin: baseDriveMin,
      congestionFactor: congestionFactor,
    ),
  );
}

/// 이동비 (원) = 연료비(거리 ÷ 연비 × 가격) + 시간비
double tripCostWon({
  required StationTrip trip,
  required int pricePerLiter,
  required double fuelEfficiency,
  required double timeValueWonPerMin,
}) {
  final fuel = fuelEfficiency <= 0
      ? 0.0
      : trip.detourKm / fuelEfficiency * pricePerLiter;
  return fuel + trip.driveTimeMin * timeValueWonPerMin;
}

/// 경제성 랭킹 엔트리 — 주유소 + 계산 결과
class EconomyRankingEntry implements HasScore {
  const EconomyRankingEntry({
    required this.station,
    required this.result,
    this.isRoadTrip = false,
  });

  final OpinetStation station;
  final EconomyResult result;

  /// 이동거리가 실제 도로(OSRM) 기준인지 — false면 직선거리 추정
  final bool isRoadTrip;

  @override
  double get score => result.score;
}

/// 경제성 랭킹 결과 — 정렬된 목록과 절약액 계산의 가정들
class EconomyRankingResult {
  const EconomyRankingResult({
    required this.fuelEfficiency,
    required this.isRealEfficiency,
    required this.ranked,
    required this.congestionLevel,
    required this.baselinePrice,
    required this.fillUpLiters,
    this.baselineKind = SavingsBaseline.areaMedian,
    this.areaMedianPrice,
    this.nearestStation,
    this.referenceTripCost = 0,
    this.fillUpBasis = FillUpBasis.defaultAmount,
    this.stationCount = 0,
  });

  /// 계산에 사용된 연비 (km/L) — 실연비 우선, 없으면 수동/표시연비
  final double fuelEfficiency;

  /// [fuelEfficiency]가 실제 주행 기록 기반 실연비인지 여부
  final bool isRealEfficiency;

  /// 경제성 점수 내림차순 정렬된 주유소 목록 (가장 가까운 곳 포함)
  final List<EconomyRankingEntry> ranked;

  /// 계산 시점의 도로 혼잡 단계 (UI 표시용)
  final CongestionLevel congestionLevel;

  /// 비교 기준 가격 (원/L) — [baselineKind]에 따라 주변 시세 또는 가장 가까운 곳
  final int baselinePrice;

  /// 1회 주유량 (L) — 카드별 총절약액 계산에 쓰임
  final double fillUpLiters;

  /// 비교 기준 종류
  final SavingsBaseline baselineKind;

  /// 주변 시세 (반경 내 가격 중앙값, 원/L)
  final int? areaMedianPrice;

  /// 직선거리 기준 가장 가까운 주유소
  final OpinetStation? nearestStation;

  /// 어차피 드는 이동비 (원) — 가장 가까운 곳을 오가는 비용
  final double referenceTripCost;

  /// [fillUpLiters]의 근거
  final FillUpBasis fillUpBasis;

  /// 계산에 쓴 주유소 수 (시세 표본 수)
  final int stationCount;

  /// 가장 경제적인 주유소 (1위) — 없으면 null
  EconomyRankingEntry? get best => ranked.isEmpty ? null : ranked.first;
}

/// 주유소 목록 → 경제성 랭킹.
///
/// - 비교 기준 가격: [baseline]에 따라 주변 시세(중앙값) 또는 가장 가까운 곳
/// - 기준 이동비: 가장 가까운 곳의 이동을 기준 가격으로 환산한 비용
/// - 순위: 점수 내림차순, 같으면 가까운 순 (결정적)
///
/// [stations]는 비어 있으면 안 된다. [tripFor]는 주유소별 이동(도로 또는 직선).
EconomyRankingResult rankStations({
  required List<OpinetStation> stations,
  required StationTrip Function(OpinetStation station) tripFor,
  required SavingsBaseline baseline,
  required FillUpPlan fillUp,
  required double fuelEfficiency,
  required bool isRealEfficiency,
  required CongestionLevel congestionLevel,
  double timeValueWonPerMin = kTimeValueWonPerMin,
}) {
  final nearest = nearestStation(stations);
  final areaMedian = medianPrice(stations.map((s) => s.price));
  final referencePrice = baseline == SavingsBaseline.nearest || areaMedian <= 0
      ? nearest.price
      : areaMedian;
  final referenceTripCost = tripCostWon(
    trip: tripFor(nearest),
    pricePerLiter: referencePrice,
    fuelEfficiency: fuelEfficiency,
    timeValueWonPerMin: timeValueWonPerMin,
  );

  final entries = <EconomyRankingEntry>[
    for (final station in stations)
      _entryFor(
        station: station,
        trip: tripFor(station),
        referencePrice: referencePrice,
        referenceTripCost: referenceTripCost,
        fillUpLiters: fillUp.liters,
        fuelEfficiency: fuelEfficiency,
        timeValueWonPerMin: timeValueWonPerMin,
      ),
  ]..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.station.distanceM.compareTo(b.station.distanceM);
    });

  return EconomyRankingResult(
    fuelEfficiency: fuelEfficiency,
    isRealEfficiency: isRealEfficiency,
    ranked: entries,
    congestionLevel: congestionLevel,
    baselinePrice: referencePrice,
    fillUpLiters: fillUp.liters,
    baselineKind: baseline,
    areaMedianPrice: areaMedian,
    nearestStation: nearest,
    referenceTripCost: referenceTripCost,
    fillUpBasis: fillUp.basis,
    stationCount: stations.length,
  );
}

EconomyRankingEntry _entryFor({
  required OpinetStation station,
  required StationTrip trip,
  required int referencePrice,
  required double referenceTripCost,
  required double fillUpLiters,
  required double fuelEfficiency,
  required double timeValueWonPerMin,
}) {
  return EconomyRankingEntry(
    station: station,
    isRoadTrip: trip.isRoad,
    result: calculateEconomy(
      baselinePrice: referencePrice,
      candidatePrice: station.price,
      fillUpLiters: fillUpLiters,
      detourKm: trip.detourKm,
      driveTimeMin: trip.driveTimeMin,
      fuelEfficiency: fuelEfficiency,
      timeValueWonPerMin: timeValueWonPerMin,
      referenceTripCost: referenceTripCost,
    ),
  );
}

/// 홈 시트 목록 순서 — 랭킹이 있으면 경제성 순, 없으면 원래(가격) 순.
/// 랭킹에 없는 주유소는 원래 순서대로 뒤에 붙인다.
List<OpinetStation> orderStationsByEconomy(
  List<OpinetStation> stations,
  EconomyRankingResult? ranking,
) {
  if (ranking == null) return stations;
  final byId = {for (final s in stations) s.uniId: s};
  final ordered = <OpinetStation>[
    for (final e in ranking.ranked)
      if (byId.containsKey(e.station.uniId)) byId[e.station.uniId]!,
  ];
  final seen = {for (final s in ordered) s.uniId};
  for (final s in stations) {
    if (!seen.contains(s.uniId)) ordered.add(s);
  }
  return ordered;
}
