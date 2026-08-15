import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI 전용 환경설정 (계산 로직에는 영향 없음)
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

class SavingsEmphasisNotifier extends Notifier<SavingsEmphasis> {
  @override
  SavingsEmphasis build() => SavingsEmphasis.monthly;

  void set(SavingsEmphasis emphasis) => state = emphasis;
}

final savingsEmphasisProvider =
    NotifierProvider<SavingsEmphasisNotifier, SavingsEmphasis>(
  SavingsEmphasisNotifier.new,
);
