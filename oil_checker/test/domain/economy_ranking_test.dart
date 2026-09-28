import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/traffic/congestion.dart';
import 'package:oil_checker/domain/economy/economy_ranking.dart';

OpinetStation _station(String id, int price, double distanceM) => OpinetStation(
      uniId: id,
      brandCode: 'GSC',
      name: '주유소 $id',
      price: price,
      distanceM: distanceM,
      gisX: 0,
      gisY: 0,
    );

void main() {
  group('medianPrice', () {
    test('홀수 개면 가운데 값', () {
      expect(medianPrice([1900, 1840, 2385]), 1900);
    });

    test('짝수 개면 가운데 두 값의 평균(반올림)', () {
      expect(medianPrice([1840, 1850, 1861, 1900]), 1856); // (1850+1861)/2
    });

    test('0원 이하는 제외, 비면 0', () {
      expect(medianPrice([0, 1800]), 1800);
      expect(medianPrice(const []), 0);
    });
  });

  group('planFillUp', () {
    test('기록이 없으면 40L (탱크가 더 작으면 탱크)', () {
      final big = planFillUp(tankSizeL: 68);
      expect(big.liters, 40);
      expect(big.basis, FillUpBasis.defaultAmount);
      expect(planFillUp(tankSizeL: 35).liters, 35);
    });

    test('최근 기록 평균 — 0 이하는 건너뛰고 최대 5건', () {
      final plan = planFillUp(tankSizeL: 68, recentLiters: [30, 50, 0, 40]);
      expect(plan.liters, closeTo(40, 0.001));
      expect(plan.basis, FillUpBasis.recentHistory);
      expect(plan.sampleCount, 3);

      final capped =
          planFillUp(tankSizeL: 68, recentLiters: [10, 20, 30, 40, 50, 60]);
      expect(capped.liters, closeTo(30, 0.001)); // 앞의 5건만
      expect(capped.sampleCount, 5);
    });
  });

  group('rankStations — 가장 가까운 곳이 비싼 이상치일 때', () {
    // 서울시청 실측 패턴 재현: 가장 가까운 곳(A)만 2,385원으로 튀고
    // 나머지는 1,8xx~1,9xx원. 시세(중앙값) = 1,900원.
    final stations = [
      _station('A', 2385, 500), // 가장 가까운 곳 — 이상치
      _station('B', 1840, 4100), // 가장 싸지만 멀다
      _station('C', 1878, 1500), // 시세 근처, 가깝다
      _station('D', 1900, 2000),
      _station('E', 1950, 3000),
    ];
    StationTrip trip(OpinetStation s) =>
        straightLineTrip(s, congestionFactor: 1.0);
    const fillUp = FillUpPlan(liters: 40, basis: FillUpBasis.defaultAmount);

    EconomyRankingResult rank(SavingsBaseline baseline) => rankStations(
          stations: stations,
          tripFor: trip,
          baseline: baseline,
          fillUp: fillUp,
          fuelEfficiency: 10,
          isRealEfficiency: false,
          congestionLevel: CongestionLevel.smooth,
        );

    test('주변 시세 기준이면 이상치에 끌려가지 않는다', () {
      final r = rank(SavingsBaseline.areaMedian);
      expect(r.baselinePrice, 1900);
      expect(r.areaMedianPrice, 1900);
      expect(r.nearestStation!.uniId, 'A');
      expect(r.stationCount, 5);
      // 기준 이동비 = A 왕복 1.0km ÷ 10km/L × 1,900원 + 1.5분 × 80원 = 310원
      expect(r.referenceTripCost, closeTo(310, 0.01));

      // 1위 C: (1900-1878)×40 - (923.4 - 310) = 880 - 613.4 = 266.6원
      expect(r.best!.station.uniId, 'C');
      expect(r.best!.score, closeTo(266.6, 0.01));
      // B: (1900-1840)×40 - (2492.8 - 310) = 2400 - 2182.8 = 217.2원
      final b = r.ranked.firstWhere((e) => e.station.uniId == 'B');
      expect(b.score, closeTo(217.2, 0.01));
      // 1회 절약이 수백 원 수준 — 가격차×주유량 이상으로 부풀지 않는다
      for (final e in r.ranked) {
        expect(e.score, lessThan((1900 - 1840) * 40));
      }
      // 가장 가까운 이상치 A는 꼴찌 (시세보다 485원 비쌈)
      expect(r.ranked.last.station.uniId, 'A');
    });

    test('가장 가까운 곳 기준이면 이상치만큼 절약액이 커진다 (선택 시에만)', () {
      final r = rank(SavingsBaseline.nearest);
      expect(r.baselinePrice, 2385);
      // C: (2385-1878)×40 - (923.4 - 358.5) = 20280 - 564.9 = 19,715.1원
      expect(r.best!.score, closeTo(19715.1, 0.01));
      // 기준인 가장 가까운 곳 자신은 절약 0
      final a = r.ranked.firstWhere((e) => e.station.uniId == 'A');
      expect(a.score, closeTo(0, 0.001));
    });

    test('비교 기준은 절약액 크기만 바꾸고 순위는 그대로다', () {
      final byMedian = rank(SavingsBaseline.areaMedian)
          .ranked
          .map((e) => e.station.uniId)
          .toList();
      final byNearest = rank(SavingsBaseline.nearest)
          .ranked
          .map((e) => e.station.uniId)
          .toList();
      expect(byMedian, ['C', 'B', 'D', 'E', 'A']);
      expect(byNearest, byMedian);
    });

    test('주유량 가정이 결과에 그대로 실린다', () {
      final r = rank(SavingsBaseline.areaMedian);
      expect(r.fillUpLiters, 40);
      expect(r.fillUpBasis, FillUpBasis.defaultAmount);
    });
  });

  group('orderStationsByEconomy', () {
    final a = _station('A', 1900, 300);
    final b = _station('B', 1800, 900);
    final c = _station('C', 1850, 600);
    final z = _station('Z', 2000, 1200);

    test('랭킹 순으로 정렬하고 랭킹에 없는 곳은 뒤에 붙인다', () {
      final ranking = rankStations(
        stations: [a, b, c],
        tripFor: (s) => straightLineTrip(s, congestionFactor: 1.0),
        baseline: SavingsBaseline.areaMedian,
        fillUp: const FillUpPlan(liters: 40, basis: FillUpBasis.defaultAmount),
        fuelEfficiency: 12,
        isRealEfficiency: false,
        congestionLevel: CongestionLevel.smooth,
      );
      final ordered = orderStationsByEconomy([a, b, c, z], ranking);
      expect(ordered.map((s) => s.uniId).toList(),
          [...ranking.ranked.map((e) => e.station.uniId), 'Z']);
    });

    test('랭킹이 없으면 원래 순서', () {
      expect(orderStationsByEconomy([b, a], null), [b, a]);
    });
  });
}
