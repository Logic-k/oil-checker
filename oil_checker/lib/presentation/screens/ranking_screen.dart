import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/core/format/distance_format.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/domain/economy/economy_engine.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/screens/station_detail_screen.dart';
import 'package:oil_checker/presentation/ui_prefs.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';
import 'package:oil_checker/presentation/widgets/station_widgets.dart';

/// 절약순위 화면 (하단 탭 2번 — 핵심 화면)
///
/// 절약액을 히어로 숫자로 올리고, 그 근거(가격차·도로 왕복·우회비용)를
/// 3분할 지표로 받친다. 정렬/필터 동작은 기존과 동일.
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  double? _maxDistanceM;
  bool _sortByDistance = false;

  static const List<(String, double?)> _distanceFilters = [
    ('전체', null),
    ('1km', 1000),
    ('3km', 3000),
    ('5km', 5000),
    ('10km', 10000),
  ];

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(economyRankingProvider);
    final profile = ref.watch(activeCarProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('절약순위'),
        actions: [
          IconButton(
            tooltip: _sortByDistance ? '경제성순으로' : '거리순으로',
            icon: Icon(
              _sortByDistance ? Icons.near_me_outlined : Icons.bar_chart,
              size: 22,
            ),
            onPressed: () =>
                setState(() => _sortByDistance = !_sortByDistance),
          ),
          SpinAction(
            tooltip: '새로고침',
            icon: Icons.refresh,
            onPressed: () => ref.invalidate(stationsAroundProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profile == null
          ? const AppEmptyView(
              icon: Icons.directions_car_outlined,
              title: '차량을 등록하면 절약 금액을 계산해드려요',
            )
          : rankingAsync.when(
              loading: () => const AppSkeleton(headerHeight: 200),
              error: (e, _) => AppEmptyView(
                icon: Icons.cloud_off_outlined,
                title: '주유소 정보를 불러오지 못했어요',
                message: '$e',
                actionLabel: '다시 시도',
                onAction: () => ref.invalidate(stationsAroundProvider),
              ),
              data: (result) => result == null
                  ? const AppEmptyView(
                      icon: Icons.local_gas_station_outlined,
                      title: '주변에 주유소가 없습니다',
                    )
                  : _RankingBody(
                      result: result,
                      maxDistanceM: _maxDistanceM,
                      sortByDistance: _sortByDistance,
                      onDistanceFilterChanged: (v) =>
                          setState(() => _maxDistanceM = v),
                      filters: _distanceFilters,
                    ),
            ),
    );
  }
}

class _RankingBody extends ConsumerWidget {
  const _RankingBody({
    required this.result,
    required this.maxDistanceM,
    required this.sortByDistance,
    required this.onDistanceFilterChanged,
    required this.filters,
  });

  final EconomyRankingResult result;
  final double? maxDistanceM;
  final bool sortByDistance;
  final ValueChanged<double?> onDistanceFilterChanged;
  final List<(String, double?)> filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = maxDistanceM == null
        ? result.ranked
        : result.ranked
            .where((e) => e.station.distanceM <= maxDistanceM!)
            .toList();

    final shown = sortByDistance
        ? (List<EconomyRankingEntry>.of(filtered)
          ..sort((a, b) => a.station.distanceM.compareTo(b.station.distanceM)))
        : filtered;

    final position = ref.watch(currentLocationProvider).value;

    return Column(
      children: [
        _FilterBar(
          maxDistanceM: maxDistanceM,
          filters: filters,
          onChanged: onDistanceFilterChanged,
        ),
        Expanded(
          child: shown.isEmpty
              ? const AppEmptyView(
                  icon: Icons.filter_alt_off_outlined,
                  title: '이 범위 안에 주유소가 없습니다',
                  message: '거리 필터를 넓혀보세요.',
                )
              : RefreshIndicator(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.best
                      : AppColors.ink,
                  // 당겨서 새로고침 — 주유소/랭킹 재계산
                  onRefresh: () async =>
                      ref.invalidate(stationsAroundProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                    OpenContainer(
                      transitionDuration: const Duration(milliseconds: 450),
                      tappable: false,
                      closedElevation: 0,
                      openElevation: 0,
                      closedColor: Colors.transparent,
                      openColor: Theme.of(context).colorScheme.surface,
                      middleColor: Theme.of(context).colorScheme.surface,
                      closedShape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      closedBuilder: (context, open) => _BestCard(
                        entry: shown.first,
                        result: result,
                        onTap: position == null ? null : open,
                      ),
                      openBuilder: (context, _) => StationDetailScreen(
                        station: shown.first.station,
                        position: position!,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 1; i < shown.length; i++) ...[
                      StaggerIn(
                        index: i,
                        child: OpenContainer(
                          transitionDuration:
                              const Duration(milliseconds: 450),
                          tappable: false,
                          closedElevation: 0,
                          openElevation: 0,
                          closedColor: Colors.transparent,
                          openColor:
                              Theme.of(context).colorScheme.surface,
                          middleColor:
                              Theme.of(context).colorScheme.surface,
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          closedBuilder: (context, open) => StationCard(
                            station: shown[i].station,
                            rank: i + 1,
                            savingAmount: shown[i].result.score,
                            detourKm: shown[i].result.detourKm,
                            driveTimeMin: shown[i].result.driveTimeMin,
                            detourCost: shown[i].result.detourCost,
                            baselinePrice: result.baselinePrice,
                            onTap: position == null ? null : open,
                          ),
                          openBuilder: (context, _) => StationDetailScreen(
                            station: shown[i].station,
                            position: position!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                    ],
                  ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.maxDistanceM,
    required this.filters,
    required this.onChanged,
  });

  final double? maxDistanceM;
  final List<(String, double?)> filters;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        children: [
          for (final (label, value) in filters)
            Padding(
              padding: const EdgeInsets.only(right: 7, top: 6, bottom: 8),
              child: Pressable(
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: AppMotion.curveStandard,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: maxDistanceM == value
                          ? (isDark ? AppColors.best : AppColors.ink)
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: maxDistanceM == value
                            ? (isDark ? AppColors.ink : Colors.white)
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 1위 히어로 카드 — 절약액이 주인공
class _BestCard extends ConsumerWidget {
  const _BestCard({
    required this.entry,
    required this.result,
    this.onTap,
  });

  final EconomyRankingEntry entry;
  final EconomyRankingResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = entry.station;
    final economy = entry.result;
    final monthly = ref.watch(monthlyFillCountProvider);
    final emphasis = ref.watch(savingsEmphasisProvider);
    final isMonthly = emphasis == SavingsEmphasis.monthly;

    final amount =
        isMonthly ? economy.score * monthly : economy.score;
    final caption = isMonthly
        ? '월 $monthly회 주유 기준, 여기서 넣으면'
        : '가득 주유하면 1회당';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 1위 메달 — 팝인으로 확정감
                  PopIn(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.best,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        '1위',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${result.isRealEfficiency ? '실연비' : '표시연비'} '
                      '${result.fuelEfficiency.toStringAsFixed(1)} km/L 기준',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  CongestionChip(level: result.congestionLevel, compact: true),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                economy.isSavings ? caption : '이 주유소가 그나마 가장 나아요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 4),
              if (economy.isSavings)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // 히어로 절약액 — 값이 바뀌면 부드럽게 카운트업
                    if (AppMotion.reduceMotion(context))
                      Text(
                        formatWon(amount),
                        style: const TextStyle(
                          fontSize: 50,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.2,
                          color: AppColors.best,
                        ),
                      )
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: amount),
                        duration: AppMotion.heroCountUp,
                        curve: AppMotion.curveEnter,
                        builder: (context, t, _) => Text(
                          formatWon(t.round()),
                          style: const TextStyle(
                            fontSize: 50,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.2,
                            color: AppColors.best,
                          ),
                        ),
                      ),
                    const SizedBox(width: 3),
                    const Text(
                      '원',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.best,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '아껴요',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '우회비용이 절약액보다 커서 추천하지 않아요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.13), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  BrandBadge(
                    brandCode: station.brandCode,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${AppColors.brandLabel(station.brandCode)} · '
                          '내 위치에서 ${formatDistance(station.distanceM)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatWon(station.price),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: '원/L',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricRow(economy: economy),
            ],
          ),
        ),
      ),
    );
  }
}

/// 절약액의 근거 — 가격차 / 도로 왕복 / 우회비용
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.economy});

  final EconomyResult economy;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _metric('도로 왕복', '${economy.detourKm.toStringAsFixed(1)}km'),
            const SizedBox(width: 1),
            _metric('예상 시간', '${economy.driveTimeMin.round()}분'),
            const SizedBox(width: 1),
            _metric('우회비용', '${formatWon(economy.detourCost)}원'),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
