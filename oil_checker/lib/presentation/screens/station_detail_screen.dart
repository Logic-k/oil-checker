import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:oil_checker/core/coordinate/katec.dart';
import 'package:oil_checker/core/format/distance_format.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/station_widgets.dart';

/// 주유소 상세 — 지도 히어로 + 고정 하단 액션바
///
/// Opinet은 영업시간을 제공하지 않으므로 표시하지 않는다.
class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({
    super.key,
    required this.station,
    required this.position,
  });

  final OpinetStation station;
  final Position position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(station.uniId));
    final ranking = ref.watch(economyRankingProvider).value;
    final isBest = ranking?.best?.station.uniId == station.uniId;
    final saving = _savingFor(ranking);

    return Scaffold(
      body: detailAsync.when(
        loading: () => const AppSkeleton(headerHeight: 200),
        error: (e, _) => AppEmptyView(
          icon: Icons.cloud_off_outlined,
          title: '상세 정보를 불러오지 못했어요',
          message: '$e',
          actionLabel: '다시 시도',
          onAction: () =>
              ref.invalidate(stationDetailProvider(station.uniId)),
        ),
        data: (detail) => detail == null
            ? const AppEmptyView(
                icon: Icons.info_outline,
                title: '상세 정보를 불러올 수 없어요',
                message: '오피넷에 등록되지 않은 주유소일 수 있어요.',
              )
            : _DetailBody(
                station: station,
                detail: detail,
                isBest: isBest,
                savingAmount: saving,
              ),
      ),
    );
  }

  double? _savingFor(EconomyRankingResult? ranking) {
    if (ranking == null) return null;
    for (final e in ranking.ranked) {
      if (e.station.uniId == station.uniId) return e.result.score;
    }
    return null;
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.station,
    required this.detail,
    required this.isBest,
    this.savingAmount,
  });

  final OpinetStation station;
  final OpinetStationDetail detail;
  final bool isBest;
  final double? savingAmount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wgs84 = katecToWgs84(x: station.gisX, y: station.gisY);
    final center = LatLng(wgs84.latitude, wgs84.longitude);
    final hasSaving = (savingAmount ?? 0) > 0;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- 지도 히어로 ---
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.oil_checker',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: center,
                              width: 84,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: PriceMarker(
                                price: station.price,
                                isBest: isBest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 본문 ---
            Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.brand(detail.brandCode),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            AppColors.brandShort(detail.brandCode),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isBest) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.best,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '경제 1위',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      AppColors.brandLabel(detail.brandCode),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detail.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 가격 / 절약액
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: '현재 가격',
                            value: '${formatWon(station.price)}원/L',
                            background: scheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            label: hasSaving ? '1회 절약' : '내 위치에서',
                            value: hasSaving
                                ? '+${formatWon(savingAmount!)}원'
                                : formatDistance(station.distanceM),
                            valueColor: hasSaving
                                ? (isDark
                                    ? AppColors.savingBright
                                    : AppColors.saving)
                                : null,
                            background: hasSaving
                                ? AppColors.saving.withValues(alpha: 0.1)
                                : scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 주소 / 전화
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.home_outlined,
                            label: '도로명',
                            value: detail.newAddress,
                          ),
                          Divider(height: 20, color: scheme.outlineVariant),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: '지번',
                            value: detail.vanAddress,
                          ),
                          if (detail.hasPhone) ...[
                            Divider(height: 20, color: scheme.outlineVariant),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: '전화',
                              value: detail.tel,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const _SubTitle('부가서비스'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (detail.hasCarWash) const _ServiceChip('세차장'),
                        if (detail.hasMaintenance) const _ServiceChip('경정비'),
                        if (detail.hasConvenienceStore)
                          const _ServiceChip('편의점'),
                        if (detail.isQualityCertified)
                          const _ServiceChip('품질인증', highlight: true),
                        if (!detail.hasCarWash &&
                            !detail.hasMaintenance &&
                            !detail.hasConvenienceStore &&
                            !detail.isQualityCertified)
                          Text(
                            '제공 서비스 정보가 없어요',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),

                    if (detail.prices.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const _SubTitle('유종별 가격'),
                      const SizedBox(height: 9),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            for (final entry
                                in detail.prices.entries.toList().asMap().entries)
                              Column(
                                children: [
                                  if (entry.key > 0)
                                    Divider(
                                        height: 1,
                                        color: scheme.outlineVariant),
                                  _PriceRow(
                                    label: _productLabel(entry.value.key),
                                    price: entry.value.value,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      '가격은 오피넷 기준 1~2시간마다 갱신돼요. '
                      '영업시간은 오피넷에서 제공하지 않아요.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // --- 고정 하단 액션바 ---
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  scheme.surface,
                  scheme.surface,
                  scheme.surface.withValues(alpha: 0),
                ],
                stops: const [0, 0.72, 1],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: const Icon(Icons.favorite_border, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation_outlined,
                          size: 19, color: AppColors.best),
                      label: const Text('길안내 시작'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _productLabel(String prodcd) => switch (prodcd) {
        OpinetClient.productGasoline => '휘발유',
        OpinetClient.productPremium => '고급휘발유',
        OpinetClient.productDiesel => '경유',
        OpinetClient.productLpg => 'LPG',
        'C004' => '실내등유',
        _ => prodcd,
      };
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 19, color: scheme.onSurface),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.background,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color background;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: scheme.onSurfaceVariant),
        const SizedBox(width: 11),
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '정보 없음' : value,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip(this.label, {this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.saving.withValues(alpha: 0.1)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          color: highlight
              ? (isDark ? AppColors.savingBright : AppColors.savingDeep)
              : scheme.onSurface,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.price});

  final String label;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${formatWon(price)}원',
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
