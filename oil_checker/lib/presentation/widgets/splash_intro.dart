import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';

/// 첫 실행 인트로 — 연료 게이지 바늘이 E↔F로 왕복하다 F에 안착하고
/// 슬로건과 함께 앱으로 넘어가는 1회성 오버레이.
///
/// 네이티브 스플래시(ink 배경)와 이어지도록 배경은 AppColors.ink.
/// reduceMotion이면 부모가 렌더링 자체를 생략한다.
class SplashIntro extends StatefulWidget {
  const SplashIntro({super.key, required this.onDone});

  /// 페이드아웃까지 끝난 뒤 호출 — 부모가 오버레이를 제거한다.
  final VoidCallback onDone;

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  /// 바늘: E→F → 약간 역행 → 탄성으로 F 안착
  late final Animation<double> _needle = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0, end: 1)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 0.15,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.15,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 30,
    ),
  ]).animate(_c);

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _leaving = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      child: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: const Duration(milliseconds: 380),
        curve: AppMotion.curveExit,
        onEnd: widget.onDone,
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 앱 네임 — 먼저 페이드인
                    Opacity(
                      opacity: Interval(
                        0.05,
                        0.4,
                        curve: Curves.easeOut,
                      ).transform(_c.value),
                      child: Text(
                        'OIL CHECKER',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.best,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    CustomPaint(
                      size: const Size(220, 150),
                      painter: _FuelGaugePainter(progress: _needle.value),
                    ),
                    const SizedBox(height: 40),
                    // 슬로건 — 바늘이 한 번 왕복한 뒤 떠오름
                    Opacity(
                      opacity: Interval(
                        0.5,
                        0.85,
                        curve: Curves.easeOut,
                      ).transform(_c.value),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          14 *
                              (1 -
                                  Interval(
                                    0.5,
                                    0.85,
                                    curve: AppMotion.curveEnter,
                                  ).transform(_c.value)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '기름값을 금값처럼!',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '연비·우회비까지 계산한 진짜 최저가',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 상부 반원 연료 게이지 — E(좌)↔F(우) 바늘.
class _FuelGaugePainter extends CustomPainter {
  _FuelGaugePainter({required this.progress});

  /// 0=E, 1=F
  final double progress;

  static const double _sweep = math.pi; // 반원

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 12);
    final radius = size.width / 2 - 8;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // 왼쪽(E)부터
      -_sweep, // 음수 스윕 — 상부 반원으로 (양수면 아래로 그려져 화면 밖)
      false,
      track,
    );

    // 눈금: E — 25% — 50% — 75% — F
    for (var i = 0; i <= 4; i++) {
      final a = math.pi - _sweep * i / 4;
      final outer =
          center + Offset(math.cos(a) * radius, -math.sin(a) * radius);
      final inner =
          center +
          Offset(math.cos(a) * (radius - 10), -math.sin(a) * (radius - 10));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.5),
      );
    }

    // E / F 라벨
    for (final (t, label) in [(0.0, 'E'), (1.0, 'F')]) {
      final a = math.pi - _sweep * t;
      final p =
          center +
          Offset(math.cos(a) * (radius - 26), -math.sin(a) * (radius - 26));
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: t == 0
                ? Colors.white.withValues(alpha: 0.45)
                : AppColors.best,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // 바늘
    final a = math.pi - _sweep * progress.clamp(0.0, 1.0);
    final tip =
        center +
        Offset(math.cos(a) * (radius - 20), -math.sin(a) * (radius - 20));
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.best,
    );
    canvas.drawCircle(center, 7, Paint()..color = AppColors.best);
    canvas.drawCircle(center, 3, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_FuelGaugePainter old) => old.progress != progress;
}
