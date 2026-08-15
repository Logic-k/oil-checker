import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:oil_checker/core/coordinate/katec.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/screens/station_detail_screen.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/station_widgets.dart';

/// 홈 — 전체화면 지도 + 드래그 가능한 주유소 시트 (하단 탭 1번)
///
/// 기존 "지도 38% + 리스트" Column 구조를 Stack + DraggableScrollableSheet로
/// 바꿨다. 데이터 소스(stationsAroundProvider / economyRankingProvider)는 동일.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);
    final stationsAsync = ref.watch(stationsAroundProvider);
    final rankingAsync = ref.watch(economyRankingProvider);
    final ranking = rankingAsync.value;
    final bestId = ranking?.best?.station.uniId;

    // 위치 지정 모드 상태
    final isPicking = ref.watch(isPickingLocationProvider);
    final picked = ref.watch(pickedLocationProvider);
    // 실시간 GPS (지도 파란 점용) — 아직 안 잡혔으면 권한 기준 위치로 폴백
    final livePosition = ref.watch(gpsPositionProvider).value;

    return locationAsync.when(
      loading: () => const AppSkeleton(headerHeight: 220, rowCount: 3),
      error: (e, _) => AppEmptyView(
        icon: Icons.location_off_outlined,
        title: '위치 권한이 필요해요',
        message: '내 주변 주유소를 찾으려면\n위치 접근을 허용해주세요.',
        actionLabel: '다시 시도',
        onAction: () => ref.invalidate(currentLocationProvider),
      ),
      data: (position) => Stack(
        children: [
          Positioned.fill(
            child: _StationMap(
              position: position,
              livePosition: livePosition,
              stations: stationsAsync.value ?? const [],
              bestStationId: bestId,
              isPicking: isPicking,
              pickedLocation: picked,
              onPick: (point) =>
                  ref.read(pickedLocationProvider.notifier).set(point),
            ),
          ),
          _TopBar(
            productCode: ref.watch(fuelProductCodeProvider),
            onRefresh: () {
              ref.invalidate(currentLocationProvider);
              ref.invalidate(stationsAroundProvider);
            },
          ),
          _LocationButtons(
            isPicking: isPicking,
            hasPicked: picked != null,
            onTogglePick: () =>
                ref.read(isPickingLocationProvider.notifier).set(!isPicking),
            onUseMyLocation: () {
              ref.read(pickedLocationProvider.notifier).set(null);
              ref.read(isPickingLocationProvider.notifier).set(false);
            },
          ),
          _StationSheet(
            position: position,
            stationsAsync: stationsAsync,
            ranking: ranking,
            onRetry: () => ref.invalidate(stationsAroundProvider),
          ),
        ],
      ),
    );
  }
}

/// 지도 우측 플로팅 버튼 — [위치 지정] 토글 / [내 위치] 복귀
class _LocationButtons extends StatelessWidget {
  const _LocationButtons({
    required this.isPicking,
    required this.hasPicked,
    required this.onTogglePick,
    required this.onUseMyLocation,
  });

  final bool isPicking;
  final bool hasPicked;
  final VoidCallback onTogglePick;
  final VoidCallback onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button({
      required IconData icon,
      required String tooltip,
      required VoidCallback onTap,
      Color? background,
      Color? foreground,
      bool active = false,
    }) {
      return Material(
        color: active
            ? AppColors.best
            : (background ??
                (isDark ? scheme.surfaceContainerHigh : Colors.white)),
        shape: const CircleBorder(),
        elevation: 2,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 20,
                color: active
                    ? AppColors.ink
                    : (foreground ??
                        (isDark ? scheme.onSurface : scheme.onSurfaceVariant)),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 68),
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(
                  icon: Icons.edit_location_alt,
                  tooltip: '위치 지정',
                  onTap: onTogglePick,
                  active: isPicking,
                ),
                const SizedBox(height: 10),
                if (hasPicked)
                  button(
                    icon: Icons.my_location,
                    tooltip: '내 위치로',
                    onTap: onUseMyLocation,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 플로팅 바 — 현재 지역 + 연료 종류 + 새로고침
class _TopBar extends StatelessWidget {
  const _TopBar({required this.productCode, required this.onRefresh});

  final String productCode;
  final VoidCallback onRefresh;

  String get _fuelLabel => switch (productCode) {
        OpinetClient.productDiesel => '경유',
        OpinetClient.productLpg => 'LPG',
        _ => '휘발유',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark
                      ? Border.all(color: scheme.outlineVariant)
                      : null,
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location,
                        size: 17, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 9),
                    Text(
                      '내 주변 주유소',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.best : AppColors.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    _fuelLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.ink : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onRefresh,
                    child: Icon(
                      Icons.refresh,
                      size: 18,
                      color: isDark ? AppColors.ink : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 지도 — 현재 위치 + 가격 말풍선 마커 (경제성 1위는 금색)
class _StationMap extends StatelessWidget {
  const _StationMap({
    required this.position,
    required this.stations,
    this.bestStationId,
    this.livePosition,
    this.isPicking = false,
    this.pickedLocation,
    this.onPick,
  });

  final Position position;
  final List<OpinetStation> stations;
  final String? bestStationId;
  final Position? livePosition;
  final bool isPicking;
  final LatLng? pickedLocation;
  final void Function(LatLng point)? onPick;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(position.latitude, position.longitude);
    // 실시간 GPS가 잡히면 파란 점은 그걸 따라간다
    final dot = livePosition != null
        ? LatLng(livePosition!.latitude, livePosition!.longitude)
        : center;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        onTap: (tapPosition, point) {
          if (isPicking) onPick?.call(point);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.oil_checker',
        ),
        MarkerLayer(
          markers: [
            // 파란 점 — 실시간 내 위치
            Marker(
              point: dot,
              width: 26,
              height: 26,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            // 위치 지정 핀 — 탭한 곳 표시
            if (pickedLocation != null)
              Marker(
                point: pickedLocation!,
                width: 34,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.best,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, size: 18, color: AppColors.ink),
                ),
              ),
            for (final station in stations)
              Marker(
                point: _toLatLng(station),
                width: 84,
                height: 44,
                alignment: Alignment.topCenter,
                child: PriceMarker(
                  price: station.price,
                  isBest: station.uniId == bestStationId,
                ),
              ),
          ],
        ),
      ],
    );
  }

  LatLng _toLatLng(OpinetStation station) {
    final wgs84 = katecToWgs84(x: station.gisX, y: station.gisY);
    return LatLng(wgs84.latitude, wgs84.longitude);
  }
}

/// 하단 주유소 시트 — 드래그로 지도/리스트 비중 조절
class _StationSheet extends StatelessWidget {
  const _StationSheet({
    required this.position,
    required this.stationsAsync,
    required this.ranking,
    required this.onRetry,
  });

  final Position position;
  final AsyncValue<List<OpinetStation>> stationsAsync;
  final EconomyRankingResult? ranking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.22,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: stationsAsync.when(
            loading: () => const AppSkeleton.list(),
            error: (e, _) => AppEmptyView(
              icon: Icons.cloud_off_outlined,
              title: '주유소 정보를 불러오지 못했어요',
              message: '$e',
              actionLabel: '다시 시도',
              onAction: onRetry,
            ),
            data: (stations) => stations.isEmpty
                ? const AppEmptyView(
                    icon: Icons.local_gas_station_outlined,
                    title: '주변에 주유소가 없습니다',
                  )
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      const _Grabber(),
                      if (ranking != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                          child: Row(
                            children: [
                              CongestionChip(level: ranking!.congestionLevel),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '지금 도로 상황이 반영됐어요',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        const SizedBox(height: 8),
                      for (final station in stations) ...[
                        _cardFor(context, station),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _cardFor(BuildContext context, OpinetStation station) {
    final entry = _entryFor(station);
    final isBest = ranking?.best?.station.uniId == station.uniId;
    return StationCard(
      station: station,
      isBest: isBest,
      savingAmount: entry?.result.score,
      detourKm: isBest ? entry?.result.detourKm : null,
      driveTimeMin: entry?.result.driveTimeMin,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StationDetailScreen(
            station: station,
            position: position,
          ),
        ),
      ),
    );
  }

  EconomyRankingEntry? _entryFor(OpinetStation station) {
    final ranked = ranking?.ranked;
    if (ranked == null) return null;
    for (final e in ranked) {
      if (e.station.uniId == station.uniId) return e;
    }
    return null;
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
