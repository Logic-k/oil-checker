import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';

/// 눌리는 터치 피드백 — Listener 기반이라 제스처 아레나를 타지 않아
/// 내부 InkWell/onTap을 방해하지 않는다. 카드·칩·버튼 위에 얹어 사용.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _press() {
    _c.stop();
    _c.value = 1.0;
  }

  void _release() {
    if (AppMotion.reduceMotion(context)) {
      _c.value = 0;
      return;
    }
    _c.animateWith(SpringSimulation(
      AppMotion.springSnappy,
      _c.value,
      0,
      3.5,
      snapToEnd: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(
          scale: 1 - 0.03 * _c.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 첫 진입 1회 스프링 팝인 — scale 0.6→1 + fade. 마커·배지·카드용.
/// [index]로 스태거 간격을 준다([AppMotion.staggerMax] 초과 시 즉시 표시).
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    final gap = AppMotion.staggerGap * widget.index.clamp(0, AppMotion.staggerMax);
    _delay = Timer(gap, () {
      if (!mounted) return;
      _c.animateWith(SpringSimulation(
        AppMotion.springExpressive,
        0,
        1,
        0,
        snapToEnd: true,
      ));
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: _c.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.4 * _c.value.clamp(0.0, 1.2),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// 첫 진입 1회 fade + slide-up — 리스트 아이템 스태거용.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    final gap = AppMotion.staggerGap * widget.index.clamp(0, AppMotion.staggerMax);
    _delay = Timer(gap, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: AppMotion.curveEnter.transform(_c.value),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _c.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// 펄스 링 — 기본 3회만 울리고 정지 (1위 마커 강조용).
/// [pulses]를 0으로 주면 무한 반복 — 내 위치 점처럼 "살아있음"을
/// 표현해야 하는 곳에만 사용한다. 지도 위에선 반드시 RepaintBoundary 안에 둘 것.
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    required this.color,
    this.size = 30,
    this.pulses = 3,
  });

  final Color color;
  final double size;

  /// 울림 횟수. 0이면 무한 반복.
  final int pulses;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  int _pulses = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener(_onStatus);
    _c.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _pulses++;
      final infinite = widget.pulses == 0;
      if ((infinite || _pulses < widget.pulses) && mounted) {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.removeStatusListener(_onStatus);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Transform.scale(
          scale: 1 + 0.9 * t,
          child: Opacity(
            opacity: 0.55 * (1 - t),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 2.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 성공 체크 — 원이 스프링으로 팝인 후 체크 표시가 쓱 그려진다.
/// 저장 완료 같은 해피 모먼트용. 화면 전체가 아니라 작은 배지 크기로 쓴다.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({
    super.key,
    this.size = 84,
    this.color = AppColors.saving,
    this.onDone,
  });

  final double size;
  final Color color;

  /// 애니메이션 완료 콜백 (자동 닫기 타이밍용)
  final VoidCallback? onDone;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
    if (AppMotion.reduceMotion(context)) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onDone?.call());
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _CheckPainter(progress: _c.value, color: widget.color),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 0.0~0.5: 원 팝인 (살짝 커졌다가 안착) / 0.4~1.0: 체크 드로우
    final circleT =
        (progress / 0.5).clamp(0.0, 1.0);
    final checkT =
        ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    if (circleT <= 0) return;

    final center = size.center(Offset.zero);
    final r = size.width / 2;
    // easeOutBack 근사 — 1.0을 살짝 넘었다가 돌아온다
    final overshoot = Curves.elasticOut.transform(circleT);
    final scale = 0.4 + 0.6 * overshoot.clamp(0.0, 1.3);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = color.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.72,
      Paint()..color = color,
    );

    if (checkT > 0) {
      final path = Path()
        ..moveTo(-r * 0.34, r * 0.02)
        ..lineTo(-r * 0.08, r * 0.26)
        ..lineTo(r * 0.38, -r * 0.2);
      final metric = path.computeMetrics().first;
      final partial = metric.extractPath(0, metric.length * checkT);
      canvas.drawPath(
        partial,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// 탭하면 아이콘이 한 바퀴 도는 액션 버튼 (새로고침용).
class SpinAction extends StatefulWidget {
  const SpinAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? iconColor;
  final double iconSize;

  @override
  State<SpinAction> createState() => _SpinActionState();
}

class _SpinActionState extends State<SpinAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _turns =
      CurvedAnimation(parent: _c, curve: AppMotion.curveStandard);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: () {
        if (!AppMotion.reduceMotion(context)) _c.forward(from: 0);
        widget.onPressed();
      },
      icon: RotationTransition(
        turns: _turns,
        child: Icon(widget.icon, size: widget.iconSize, color: widget.iconColor),
      ),
    );
  }
}
