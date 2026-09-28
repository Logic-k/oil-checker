import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/domain/economy/economy_ranking.dart';

/// UI 전용 환경설정
///
/// DB 스키마를 건드리지 않기 위해 메모리 상태로만 둔다.
/// 영구 저장이 필요해지면 SharedPreferences로 감싸면 된다.
///
/// Riverpod 3.x에서는 StateProvider가 제거되어 Notifier로 작성한다.

/// 다크 모드 여부 — 설정 화면에서 토글
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 월 평균 주유 횟수 — 절약액을 "한 달 기준"으로 환산할 때 쓴다.
class MonthlyFillCountNotifier extends Notifier<int> {
  @override
  int build() => 2;

  void set(int value) => state = value.clamp(1, 12);
}

final monthlyFillCountProvider =
    NotifierProvider<MonthlyFillCountNotifier, int>(
  MonthlyFillCountNotifier.new,
);

/// 절약순위 화면의 절약액 표기 방식
enum SavingsEmphasis { monthly, perFill }

/// 기본은 1회당 — 월 환산은 곱셈이 한 번 더 들어가 숫자가 커 보이므로
/// 사용자가 고를 때만 쓴다.
class SavingsEmphasisNotifier extends Notifier<SavingsEmphasis> {
  @override
  SavingsEmphasis build() => SavingsEmphasis.perFill;

  void set(SavingsEmphasis emphasis) => state = emphasis;
}

final savingsEmphasisProvider =
    NotifierProvider<SavingsEmphasisNotifier, SavingsEmphasis>(
  SavingsEmphasisNotifier.new,
);

/// 절약액 비교 기준 — 기본은 주변 시세(가격 중앙값).
/// 이 설정은 표시되는 절약액만 바꾸고 순위는 바꾸지 않는다.
class SavingsBaselineNotifier extends Notifier<SavingsBaseline> {
  @override
  SavingsBaseline build() => SavingsBaseline.areaMedian;

  void set(SavingsBaseline baseline) => state = baseline;
}

final savingsBaselineProvider =
    NotifierProvider<SavingsBaselineNotifier, SavingsBaseline>(
  SavingsBaselineNotifier.new,
);
