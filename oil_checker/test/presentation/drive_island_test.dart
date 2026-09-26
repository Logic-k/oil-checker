import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/presentation/widgets/drive_island.dart';

/// drive_island — 다이나믹 아일랜드 위젯 검증
/// 접힘/펼침 상태별 렌더링과 상태(로딩/빈/에러) 표시를 확인한다.
void main() {
  const data = DriveIslandData(
    title: 'SK에너지 강남주유소',
    subtitle: 'SK에너지 · 내 위치에서 850m',
    priceText: '1,620원/L',
    savingsText: '+3,200원',
    detailText: '왕복 2.4km · 약 9분',
  );

  Widget harness({
    required DriveIslandData data,
    bool expanded = false,
    double? speedKmh,
    VoidCallback? onToggle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DriveIsland(
          data: data,
          expanded: expanded,
          speedKmh: speedKmh,
          onToggle: onToggle ?? () {},
        ),
      ),
    );
  }

  testWidgets('접힌 상태 — 이름·절약액·속도 칩을 보여준다', (tester) async {
    await tester.pumpWidget(harness(data: data, speedKmh: 42));
    await tester.pumpAndSettle();

    expect(find.text('SK에너지 강남주유소'), findsOneWidget);
    expect(find.text('+3,200원'), findsOneWidget);
    expect(find.text('42km/h'), findsOneWidget);
    // 접힌 알약에는 상세(가격 대형 글씨·우회 정보)가 없다
    expect(find.text('왕복 2.4km · 약 9분'), findsNothing);
  });

  testWidgets('탭 콜백이 호출되고 펼친 상태엔 상세가 보인다', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(harness(data: data, onToggle: () => toggled++));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DriveIsland));
    expect(toggled, 1);

    await tester.pumpWidget(harness(data: data, expanded: true));
    await tester.pumpAndSettle();

    expect(find.text('SK에너지 · 내 위치에서 850m'), findsOneWidget);
    expect(find.text('+3,200원 아껴요'), findsOneWidget);
    expect(find.text('왕복 2.4km · 약 9분'), findsOneWidget);
  });

  testWidgets('상태 표시 — 로딩/빈/에러 문구', (tester) async {
    for (final (status, label) in [
      (DriveIslandStatus.loading, '주변 주유소 찾는 중…'),
      (DriveIslandStatus.empty, '주변에 주유소가 없습니다'),
      (DriveIslandStatus.error, '주유소 정보를 불러오지 못했어요'),
    ]) {
      await tester.pumpWidget(
        harness(
          data: DriveIslandData(title: label, status: status),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
    }
  });
}
