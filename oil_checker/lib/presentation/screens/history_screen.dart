import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/data/db/app_database.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';

/// 주유이력 화면 (하단 탭 3번)
///
/// 요약 카드에 실연비 + 연비 추이 스파크라인을 얹었다.
/// 추이는 저장된 주유 기록(주행거리계 차이 ÷ 주유량)으로만 계산하므로
/// DB 스키마 변경이 필요 없다.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeCarProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('주유이력')),
      floatingActionButton: profile == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref, profile),
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              icon: const Icon(Icons.add, color: AppColors.best),
              label: const Text(
                '주유 기록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
      body: profile == null
          ? const AppEmptyView(
              icon: Icons.directions_car_outlined,
              title: '차량을 먼저 등록해주세요',
            )
          : _HistoryBody(profile: profile),
    );
  }

  Future<void> _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    CarProfile profile,
  ) async {
    final odometer = TextEditingController();
    final liters = TextEditingController();
    final amount = TextEditingController();
    final stationName = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '주유 기록 추가',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: odometer,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '주행거리계 (km) *',
                  hintText: '계기판 총 주행거리',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: liters,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '주유량 (L) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '총 금액 (원) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stationName,
                decoration: const InputDecoration(
                  labelText: '주유소명',
                  hintText: '일반 주유소',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;

    final odo = double.tryParse(odometer.text.trim());
    final l = double.tryParse(liters.text.trim());
    final won = double.tryParse(amount.text.trim());
    if (odo == null || l == null || won == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 항목을 숫자로 입력해주세요.')),
        );
      }
      return;
    }

    await ref.read(appDatabaseProvider).addFuelingHistory(
          carProfileId: profile.id,
          fueledAt: DateTime.now(),
          odometerKm: odo,
          liters: l,
          totalAmountWon: won,
          stationName: stationName.text.trim().isEmpty
              ? '일반 주유소'
              : stationName.text.trim(),
        );
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.profile});

  final CarProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiesAsync = ref.watch(fuelingHistoriesProvider(profile.id));

    return historiesAsync.when(
      loading: () => const AppSkeleton(headerHeight: 150),
      error: (e, _) => AppEmptyView(
        icon: Icons.error_outline,
        title: '이력을 불러오지 못했어요',
        message: '$e',
      ),
      data: (histories) {
        final points = _efficiencySeries(histories);
        final totalSpent = histories.fold<double>(
          0,
          (sum, h) => sum + h.totalAmountWon,
        );

        return RefreshIndicator(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.best
              : AppColors.ink,
          onRefresh: () async =>
              ref.invalidate(fuelingHistoriesProvider(profile.id)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
            _SummaryCard(
              profile: profile,
              recordCount: histories.length,
              series: points,
            ),
            const SizedBox(height: 18),
            AppSectionLabel(
              '최근 기록',
              trailing: Text(
                '누적 ${formatWon(totalSpent)}원',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (histories.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: AppEmptyView(
                  icon: Icons.local_gas_station_outlined,
                  title: '첫 주유를 기록해보세요',
                  message: '두 번째 기록부터 실연비가 계산돼요.',
                ),
              )
            else
              for (var i = 0; i < histories.length; i++) ...[
                StaggerIn(
                  index: i,
                  child: _HistoryTile(
                    history: histories[i],
                    kmPerL: _kmPerLAt(histories, i),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 기록 목록(최신순)에서 index 항목의 구간 연비
  double? _kmPerLAt(List<FuelingHistory> histories, int index) {
    if (index + 1 >= histories.length) return null;
    final current = histories[index];
    final previous = histories[index + 1];
    final km = current.odometerKm - previous.odometerKm;
    if (km <= 0 || current.liters <= 0) return null;
    return km / current.liters;
  }

  /// 스파크라인용 연비 시계열 (오래된 순)
  List<double> _efficiencySeries(List<FuelingHistory> histories) {
    final series = <double>[];
    for (var i = histories.length - 1; i >= 0; i--) {
      final v = _kmPerLAt(histories, i);
      if (v != null) series.add(v);
    }
    return series;
  }
}

/// 실연비 요약 + 추이
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.profile,
    required this.recordCount,
    required this.series,
  });

  final CarProfile profile;
  final int recordCount;
  final List<double> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<double?>(
      future: ref.read(appDatabaseProvider).computeLatestKmPerL(profile.id),
      builder: (context, snapshot) {
        final real = snapshot.data ??
            profile.latestRecordedKmPerL ??
            profile.manualFuelEfficiency;
        final spec = profile.avgFuelEfficiency;
        final gap = (real != null && spec > 0)
            ? ((real - spec) / spec * 100).round()
            : null;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceAlt : AppColors.ink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car,
                        size: 18, color: AppColors.best),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      profile.modelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.saving.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '기록 $recordCount회',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.savingBright
                            : AppColors.savingDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '실연비',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // 실연비 히어로 숫자 — 카운트업
                          if (real == null ||
                              AppMotion.reduceMotion(context))
                            Text(
                              real != null
                                  ? real.toStringAsFixed(1)
                                  : '—',
                              style: const TextStyle(
                                fontSize: 38,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.6,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            )
                          else
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: real),
                              duration: AppMotion.heroCountUp,
                              curve: AppMotion.curveEnter,
                              builder: (context, t, _) => Text(
                                t.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 38,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.6,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            'km/L',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '표시연비',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${spec.toStringAsFixed(1)} km/L',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (gap != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (gap >= 0
                                  ? AppColors.saving
                                  : AppColors.trafficHeavy)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${gap >= 0 ? '+' : ''}$gap%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: gap >= 0
                                ? AppColors.saving
                                : AppColors.trafficHeavy,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (series.length >= 2) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 70,
                  child: AppMotion.reduceMotion(context)
                      ? CustomPaint(
                          painter: SparklinePainter(values: series),
                          size: Size.infinite,
                        )
                      // 스파크라인 좌→우 드로우 리빌
                      : TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 900),
                          curve: AppMotion.curveEnter,
                          builder: (context, t, _) => CustomPaint(
                            painter:
                                SparklinePainter(values: series, progress: t),
                            size: Size.infinite,
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 연비 추이 스파크라인 — [progress]로 좌→우 리빌 애니메이션 지원
class SparklinePainter extends CustomPainter {
  const SparklinePainter({required this.values, this.progress = 1});

  final List<double> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    if (progress < 1) {
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    }
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.01 ? 1.0 : max - min;

    Offset pointAt(int i) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - (values[i] - min) / range);
      return Offset(x, y.clamp(4.0, size.height - 4));
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = pointAt(i);
      line.lineTo(p.dx, p.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x47FFB020), Color(0x00FFB020)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.best
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      pointAt(values.length - 1),
      4.5,
      Paint()..color = AppColors.best,
    );
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.values != values || old.progress != progress;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.history, this.kmPerL});

  final FuelingHistory history;
  final double? kmPerL;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = history.fueledAt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Text(
                  '${date.month.toString().padLeft(2, '0')}월',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedSoft,
                  ),
                ),
                Text(
                  date.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 34, color: scheme.outlineVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.stationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${history.liters.toStringAsFixed(1)}L · '
                  '${formatWon(history.odometerKm)}km'
                  '${kmPerL != null ? ' · ${kmPerL!.toStringAsFixed(1)} km/L' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatWon(history.totalAmountWon)}원',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
