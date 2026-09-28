import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/domain/economy/economy_engine.dart';

void main() {
  group('EconomyEngine.calculateEconomy', () {
    // 절약액 = (기준가 - 후보가) × 주유량
    test('가격차 × 주유량으로 절약액을 계산한다', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 50,
        detourKm: 0,
        driveTimeMin: 0,
        fuelEfficiency: 10,
      );
      expect(result.savingAmount, closeTo(10000, 0.001));
    });

    // 연료비용 = 우회거리 ÷ 연비 × 후보 유가
    test('연료비용 = (우회거리 ÷ 연비) × 후보 가격', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 50,
        detourKm: 5,
        driveTimeMin: 0,
        fuelEfficiency: 10,
      );
      // 5km ÷ 10km/L = 0.5L, 0.5L × 1800원 = 900원
      expect(result.fuelCost, closeTo(900, 0.001));
      expect(result.detourCost, closeTo(900, 0.001));
    });

    test('시간비용 = 예상시간(분) × 시간 가치', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 50,
        detourKm: 5,
        driveTimeMin: 10,
        fuelEfficiency: 10,
        timeValueWonPerMin: 80,
      );
      // 10분 × 80원 = 800원
      expect(result.timeCost, closeTo(800, 0.001));
      // 우회비용 = 연료 900 + 시간 800 = 1700
      expect(result.detourCost, closeTo(1700, 0.001));
    });

    test('시간 가치 0이면 시간비용 미반영', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 50,
        detourKm: 5,
        driveTimeMin: 10,
        fuelEfficiency: 10,
      );
      expect(result.timeCost, closeTo(0, 0.001));
      expect(result.detourCost, closeTo(900, 0.001));
    });

    test('경제성 점수 = 절약액 - 우회비용', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 50,
        detourKm: 5,
        driveTimeMin: 10,
        fuelEfficiency: 10,
        timeValueWonPerMin: 80,
      );
      // 10000 - 1700 = 8300
      expect(result.score, closeTo(8300, 0.001));
    });

    test('기준 이동비보다 더 드는 비용만 우회비용으로 뺀다 (0 하한)', () {
      final far = calculateEconomy(
        baselinePrice: 1900,
        candidatePrice: 1840,
        fillUpLiters: 40,
        detourKm: 8.2,
        driveTimeMin: 12.3,
        fuelEfficiency: 10,
        timeValueWonPerMin: 80,
        referenceTripCost: 310,
      );
      expect(far.detourCost, closeTo(2492.8, 0.01)); // 이동비 전체
      expect(far.extraTripCost, closeTo(2182.8, 0.01)); // 더 드는 만큼
      expect(far.score, closeTo(2400 - 2182.8, 0.01));

      final nearer = calculateEconomy(
        baselinePrice: 1900,
        candidatePrice: 1840,
        fillUpLiters: 40,
        detourKm: 0.5,
        driveTimeMin: 1,
        fuelEfficiency: 10,
        timeValueWonPerMin: 80,
        referenceTripCost: 310,
      );
      expect(nearer.extraTripCost, 0); // 기준보다 적게 들면 0
      expect(nearer.score, closeTo(2400, 0.001));
    });

    test('스코어가 양수면 isSavings=true', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 50,
        detourKm: 5,
        driveTimeMin: 0,
        fuelEfficiency: 10,
      );
      expect(result.isSavings, isTrue);
    });

    test('후보 가격이 더 비싸면 isSavings=false', () {
      final result = calculateEconomy(
        baselinePrice: 1800,
        candidatePrice: 2000,
        fillUpLiters: 50,
        detourKm: 0,
        driveTimeMin: 0,
        fuelEfficiency: 10,
      );
      expect(result.isSavings, isFalse);
      expect(result.savingAmount, lessThan(0));
    });

    test('주유량 0L면 절약액이 0', () {
      final result = calculateEconomy(
        baselinePrice: 2000,
        candidatePrice: 1800,
        fillUpLiters: 0,
        detourKm: 0,
        driveTimeMin: 0,
        fuelEfficiency: 10,
      );
      expect(result.savingAmount, closeTo(0, 0.001));
      expect(result.score, closeTo(0, 0.001));
    });
  });

  group('EconomyEngine.computeDetourKm', () {
    test('목적지 설정 시 편도 (내위치→후보→목적지)', () {
      final detour = computeDetourKm(
        fromToStationKm: 2,
        stationToDestinationKm: 3,
      );
      expect(detour, closeTo(5, 0.001));
    });

    test('목적지 미설정 시 왕복 2배 (내위치→후보→복귀)', () {
      final detour = computeDetourKm(fromToStationKm: 2);
      expect(detour, closeTo(4, 0.001));
    });
  });

  group('EconomyEngine.applyCongestion', () {
    test('혼잡 가중치 1.5면 예상시간 1.5배', () {
      final time = applyCongestion(baseDriveMin: 10, congestionFactor: 1.5);
      expect(time, closeTo(15, 0.001));
    });

    test('가중치 1.0이면 시간 변화 없음', () {
      final time = applyCongestion(baseDriveMin: 10, congestionFactor: 1.0);
      expect(time, closeTo(10, 0.001));
    });
  });

  group('EconomyEngine 순위 정렬', () {
    test('경제성 점수 내림차순으로 정렬한다', () {
      final stations = [
        _ranked(score: 100),
        _ranked(score: 300),
        _ranked(score: 200),
      ];
      final sorted = rankByEconomy(stations);
      expect(sorted.map((s) => s.score).toList(), [300, 200, 100]);
    });
  });
}

class _Ranked implements HasScore {
  const _Ranked(this.score);
  @override
  final double score;
}

_Ranked _ranked({required double score}) => _Ranked(score);
