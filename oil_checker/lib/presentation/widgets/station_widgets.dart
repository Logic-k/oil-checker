import 'package:flutter/material.dart';
import 'package:oil_checker/core/format/distance_format.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/core/traffic/congestion.dart';

/// 도로 혼잡 단계 칩 — 원활/보통/혼잡
class CongestionChip extends StatelessWidget {
  const CongestionChip({super.key, required this.level, this.compact = false});

  final CongestionLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.traffic(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '도로 ${CongestionModel.labelOf(level)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 지도 위 가격 말풍선 마커 — 지도만 봐도 가격 비교가 된다.
class PriceMarker extends StatelessWidget {
  const PriceMarker({
    super.key,
    required this.price,
    this.isBest = false,
  });

  final int price;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isBest
        ? AppColors.best
        : (isDark ? AppColors.darkSurfaceAlt : Colors.white);
    final fg = isBest
        ? AppColors.ink
        : (isDark ? AppColors.darkText : AppColors.ink);
    final tail = isBest
        ? AppColors.best
        : (isDark ? const Color(0xFF3A4553) : AppColors.ink);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(isBest ? 8 : 11, 6, 11, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isBest
                  ? Colors.white
                  : (isDark ? const Color(0xFF3A4553) : AppColors.ink),
              width: isBest ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isBest
                    ? AppColors.best.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.16),
                blurRadius: isBest ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBest) ...[
                Icon(Icons.local_gas_station, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                formatWon(price),
                style: TextStyle(
                  fontSize: isBest ? 14 : 13,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: Size(isBest ? 12 : 10, isBest ? 8 : 7),
          painter: _TailPainter(tail),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// 주유소 리스트 카드 — 좌측 정유사 컬러 스트라이프 + 가격 + 절약액
class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    this.savingAmount,
    this.detourKm,
    this.driveTimeMin,
    this.isBest = false,
    this.rank,
    this.onTap,
  });

  final OpinetStation station;

  /// 절약액(원). null이면 표시하지 않음(계산 전).
  final double? savingAmount;
  final double? detourKm;
  final double? driveTimeMin;
  final bool isBest;
  final int? rank;
  final VoidCallback? onTap;

  bool get _isSaving => (savingAmount ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingColor = isDark ? AppColors.savingBright : AppColors.saving;

    final subtitleParts = <String>[
      formatDistance(station.distanceM),
      if (detourKm != null) '도로 왕복 ${detourKm!.toStringAsFixed(1)}km',
      if (driveTimeMin != null) '예상 ${driveTimeMin!.round()}분',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isBest ? 18 : 16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isBest
                ? (isDark
                    ? AppColors.best.withValues(alpha: 0.07)
                    : AppColors.bestSoft)
                : scheme.surface,
            borderRadius: BorderRadius.circular(isBest ? 18 : 16),
            border: Border.all(
              color: isBest ? AppColors.best : scheme.outlineVariant,
              width: isBest ? 1.5 : 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: AppColors.brand(station.brandCode)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15, isBest ? 14 : 13, 15,
                        isBest ? 14 : 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isBest) ...[
                                        const _BestBadge(),
                                        const SizedBox(width: 6),
                                      ] else if (rank != null) ...[
                                        _RankBadge(rank: rank!),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Text(
                                          AppColors
                                              .brandLabel(station.brandCode),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    station.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isBest ? 17 : 15.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitleParts.join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: formatWon(station.price),
                                        style: TextStyle(
                                          fontSize: isBest ? 19 : 16,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                      TextSpan(
                                        text: '원/L',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                if (savingAmount != null)
                                  Text(
                                    _isSaving
                                        ? '+${formatWon(savingAmount!)}원'
                                        : '절약 없음',
                                    style: TextStyle(
                                      fontSize: _isSaving ? 13 : 12,
                                      fontWeight: _isSaving
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _isSaving
                                          ? savingColor
                                          : AppColors.mutedSoft,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (isBest && _isSaving) ...[
                          const SizedBox(height: 9),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 8),
                            decoration: BoxDecoration(
                              color: savingColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '우회비용 빼고도 1회당 ${formatWon(savingAmount!)}원 이득',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.savingBright
                                    : AppColors.savingDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BestBadge extends StatelessWidget {
  const _BestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.best,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '경제 1위',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
