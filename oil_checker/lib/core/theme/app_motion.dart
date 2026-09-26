import 'package:flutter/material.dart';

/// Oil Checker 모션 토큰 — M3 Expressive 스프링 물리 기반.
/// duration/curve가 아니라 스프링(mass·stiffness·damping)이 기본 언어다.
class AppMotion {
  const AppMotion._();

  /// 히어로 모먼트 — 1위 카드, 시트 스냅, 마커 팝인. 살짝 바운스.
  static final SpringDescription springExpressive =
      SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 500),
    bounce: 0.3,
  );

  /// 일반 공간 이동 — 칩 선택, 카드, 바텀시트. 바운스 없음.
  static final SpringDescription springStandard =
      SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 350),
  );

  /// 터치 피드백·배지 — 빠르고 미세한 바운스.
  static final SpringDescription springSnappy =
      SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 280),
    bounce: 0.15,
  );

  /// 진입 커브 (M3 emphasizedDecelerate) — 공간이 아닌 속성용.
  static const Curve curveEnter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// 퇴장 커브 (M3 standardAccelerate).
  static const Curve curveExit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// 표준 커브 (M3 standard).
  static const Curve curveStandard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 리스트 스태거 간격 / 최대 연출 개수 (이후는 즉시 표시).
  static const Duration staggerGap = Duration(milliseconds: 40);
  static const int staggerMax = 8;

  /// 히어로 숫자 카운트업 시간.
  static const Duration heroCountUp = Duration(milliseconds: 900);

  /// 접근성 — "애니메이션 줄이기/제거" 설정이면 true.
  /// 모든 커스텀 애니메이션의 분기점으로 사용한다.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
