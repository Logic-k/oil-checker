import 'package:flutter/material.dart';
import 'package:oil_checker/core/theme/app_theme.dart';

/// 로딩 스켈레톤 — 스피너 대신 들어올 레이아웃을 미리 보여준다.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.headerHeight = 96,
    this.rowCount = 4,
    this.rowHeight = 74,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final double headerHeight;
  final int rowCount;
  final double rowHeight;
  final EdgeInsets padding;

  /// 리스트만 있는 화면용
  const AppSkeleton.list({super.key, this.rowCount = 5})
      : headerHeight = 0,
        rowHeight = 74,
        padding = const EdgeInsets.fromLTRB(16, 16, 16, 16);

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEDF1F4);
    final highlight = isDark
        ? AppColors.darkBorder
        : Colors.white.withValues(alpha: 0.75);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = (rect.width + 300) * _controller.value - 150;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx / rect.width),
            ).createShader(rect);
          },
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.headerHeight > 0) ...[
                  _Block(height: 26, width: 130, color: base),
                  const SizedBox(height: 14),
                  _Block(height: widget.headerHeight, color: base, radius: 20),
                  const SizedBox(height: 14),
                ],
                for (var i = 0; i < widget.rowCount; i++) ...[
                  _Block(height: widget.rowHeight, color: base),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.ratio);
  final double ratio;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * ratio, 0, 0);
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.height,
    required this.color,
    this.width,
    this.radius = 16,
  });

  final double height;
  final double? width;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// 빈 상태 / 에러 공통 뷰 — 원인 + 해결 행동 + 대안 경로
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: AppColors.mutedSoft),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 7),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel ?? '다시 시도'),
              ),
            ],
            if (onSecondary != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel ?? '',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 섹션 제목 (설정/이력 등)
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedSoft,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
