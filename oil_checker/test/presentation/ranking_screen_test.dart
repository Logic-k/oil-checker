import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/traffic/congestion.dart';
import 'package:oil_checker/data/db/app_database.dart';
import 'package:oil_checker/domain/economy/economy_engine.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/screens/ranking_screen.dart';

/// ranking_screen 카드형 디자인 검증 — 데이터 주입으로 UI 구조 확인
void main() {
  final profile = CarProfile(
    id: 1,
    modelName: '아반떼',
    brand: '현대',
    fuelType: 'B027',
    tankSizeL: 50,
    avgFuelEfficiency: 12.0,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final stations = [
    OpinetStation(
      uniId: 'A001',
      brandCode: 'HDO',
      name: '주유소 A',
      price: 1600,
      distanceM: 800,
      gisX: 309910,
      gisY: 552073,
    ),
    OpinetStation(
      uniId: 'A002',
      brandCode: 'GSC',
      name: '주유소 B',
      price: 1700,
      distanceM: 1200,
      gisX: 310000,
      gisY: 552100,
    ),
  ];

  Widget buildRanking() {
    final result = EconomyRankingResult(
      fuelEfficiency: 12.0,
      isRealEfficiency: true,
      congestionLevel: CongestionLevel.heavy,
      baselinePrice: 1700,
      fillUpLiters: 50,
      ranked: [
        EconomyRankingEntry(
          station: stations[0],
          result: calculateEconomy(
            baselinePrice: 1700,
            candidatePrice: 1600,
            fillUpLiters: 50,
            detourKm: 3.2,
            driveTimeMin: 24,
            fuelEfficiency: 12.0,
            timeValueWonPerMin: kTimeValueWonPerMin,
          ),
        ),
        EconomyRankingEntry(
          station: stations[1],
          result: calculateEconomy(
            baselinePrice: 1700,
            candidatePrice: 1700,
            fillUpLiters: 50,
            detourKm: 5.1,
            driveTimeMin: 38,
            fuelEfficiency: 12.0,
            timeValueWonPerMin: kTimeValueWonPerMin,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        activeCarProfileProvider
            .overrideWith((ref) => Stream.value(profile)),
        economyRankingProvider.overrideWith((ref) async => result),
      ],
      child: const MaterialApp(home: RankingScreen()),
    );
  }

  testWidgets('혼잡 배너가 혼잡 단계를 색상 칩으로 표시한다', (tester) async {
    await tester.pumpWidget(buildRanking());
    await tester.pumpAndSettle();

    expect(find.text('도로 혼잡'), findsOneWidget);
    expect(find.text('실연비 12.0 km/L 기준'), findsOneWidget);
  });

  testWidgets('1위 히어로 카드가 절약액·월 절약·도로 정보를 표시한다', (tester) async {
    await tester.pumpWidget(buildRanking());
    await tester.pumpAndSettle();

    expect(find.text('월 2회 주유 기준, 여기서 넣으면'), findsOneWidget);
    expect(find.text('아껴요'), findsOneWidget);
    expect(find.text('주유소 A'), findsOneWidget);
    expect(find.text('1,600원/L'), findsOneWidget);
    expect(find.text('도로 왕복'), findsOneWidget);
    expect(find.text('3.2km'), findsOneWidget);
    expect(find.text('예상 시간'), findsOneWidget);
    expect(find.text('24분'), findsOneWidget);
  });

  testWidgets('2위 카드가 도로 정보와 절약 없음 상태를 표시한다', (tester) async {
    await tester.pumpWidget(buildRanking());
    await tester.pumpAndSettle();

    expect(find.text('주유소 B'), findsOneWidget);
    expect(find.textContaining('도로 왕복 5.1km'), findsOneWidget);
    expect(find.text('절약 없음'), findsOneWidget);
  });
}
