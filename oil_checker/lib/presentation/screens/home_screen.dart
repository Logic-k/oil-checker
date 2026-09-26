import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:oil_checker/core/coordinate/katec.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/screens/drive_screen.dart';
import 'package:oil_checker/presentation/screens/station_detail_screen.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';
import 'package:oil_checker/presentation/widgets/station_widgets.dart';

/// 홈 — 전체화면 지도 + 드래그 가능한 주유소 시트 (하단 탭 1번)
///
/// 기존 "지도 38% + 리스트" Column 구조를 Stack + DraggableScrollableSheet로
/// 바꿨다. 데이터 소스(stationsAroundProvider / economyRankingProvider)는 동일.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(effectivePositionProvider);
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
        // 권한 없이도 둘러보기 — 서울 중심으로 열고 위치 지정 모드 진입
        secondaryLabel: '지도에서 위치 지정',
        onSecondary: () {
          ref
              .read(pickedLocationProvider.notifier)
              .set(const LatLng(37.5665, 126.9780)); // 서울 시청
          ref.read(isPickingLocationProvider.notifier).set(true);
        },
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
      return Pressable(
        child: Material(
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
                          (isDark
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant)),
                ),
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
                  icon: Icons.navigation_outlined,
                  tooltip: '드라이브 모드',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DriveScreen(),
                    ),
                  ),
                  foreground: AppColors.best,
                ),
                const SizedBox(height: 10),
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
                  _SpinRefresh(onTap: onRefresh, dark: isDark),
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
///
/// 카메라 이동은 AnimatedMapController(스프링 플라이), 마커는 스태거 팝인,
/// 1위 마커는 골드 펄스, 위치 지정 핀은 낙하 모션으로 표시한다.
class _StationMap extends StatefulWidget {
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
  State<_StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<_StationMap>
    with SingleTickerProviderStateMixin {
  late final AnimatedMapController _mapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    curve: AppMotion.curveEnter,
    cancelPreviousAnimations: true,
  );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_StationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위치 지정 핀이 생기면 그 지점으로, 해제되면 내 위치로 부드럽게 이동
    final picked = widget.pickedLocation;
    if (picked != null && picked != oldWidget.pickedLocation) {
      _mapController.animateTo(dest: picked, zoom: 15);
    } else if (picked == null && oldWidget.pickedLocation != null) {
      _mapController.animateTo(
        dest: LatLng(widget.position.latitude, widget.position.longitude),
        zoom: 14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.position.latitude, widget.position.longitude);
    // 실시간 GPS가 잡히면 파란 점은 그걸 따라간다
    final dot = widget.livePosition != null
        ? LatLng(widget.livePosition!.latitude, widget.livePosition!.longitude)
        : center;
    final pickedLocation = widget.pickedLocation;

    return FlutterMap(
      mapController: _mapController.mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        onTap: (tapPosition, point) {
          if (widget.isPicking) widget.onPick?.call(point);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.oil_checker',
        ),
        MarkerLayer(
          markers: [
            // 파란 점 — 실시간 내 위치 (GPS 살아있을 때 은은한 펄스)
            Marker(
              point: dot,
              width: 26,
              height: 26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.livePosition != null)
                    const RepaintBoundary(
                      child: PulseRing(
                        color: Color(0xFF2563EB),
                        size: 26,
                        pulses: 0,
                      ),
                    ),
                  Container(
                    width: 26,
                    height: 26,
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
                ],
              ),
            ),
            // 위치 지정 핀 — 탭한 곳에 위에서 떨어지며 착지
            if (pickedLocation != null)
              Marker(
                point: pickedLocation,
                width: 34,
                height: 34,
                child: _DropPin(key: ValueKey(pickedLocation)),
              ),
            // 주유소 가격 마커 — 첫 표시 시 스태거 팝인, 1위는 골드 펄스
            for (var i = 0; i < widget.stations.length; i++)
              Marker(
                point: _toLatLng(widget.stations[i]),
                width: 84,
                height: 44,
                alignment: Alignment.topCenter,
                child: PopIn(
                  index: i,
                  child: _BestMarkerFrame(
                    isBest: widget.stations[i].uniId == widget.bestStationId,
                    child: PriceMarker(
                      price: widget.stations[i].price,
                      isBest: widget.stations[i].uniId == widget.bestStationId,
                    ),
                  ),
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

/// 위치 지정 핀 — 위에서 떨어지는 바운스 낙하 (새 지점 찍을 때마다 재생)
class _DropPin extends StatelessWidget {
  const _DropPin({super.key});

  @override
  Widget build(BuildContext context) {
    final pin = Container(
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
      child:
          const Icon(Icons.location_on, size: 18, color: AppColors.ink),
    );

    if (AppMotion.reduceMotion(context)) return pin;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.bounceOut,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -52 * (1 - t)),
        child: child,
      ),
      child: pin,
    );
  }
}

/// 경제성 1위 마커 프레임 — 마커 뒤에 골드 펄스 링 (3회 울리고 정지)
class _BestMarkerFrame extends StatelessWidget {
  const _BestMarkerFrame({required this.isBest, required this.child});

  final bool isBest;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isBest) return child;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          child: RepaintBoundary(
            child: PulseRing(color: AppColors.best, size: 30),
          ),
        ),
        child,
      ],
    );
  }
}

/// 하단 주유소 시트 — 드래그로 지도/리스트 비중 조절
///
/// snap으로 손을 떼면 자석처럼 붙고, 로딩→데이터 전환은 크로스페이드,
/// 카드 리스트는 첫 표시 시 스태거로 올라온다.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.22,
      maxChildSize: 0.92,
      // 자석 스냅 — 손을 떼면 가장 가까운 크기로 붙는다
      snap: true,
      snapSizes: const [0.5],
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(
                stationsAsync.hasValue
                    ? 'data'
                    : (stationsAsync.hasError ? 'error' : 'loading'),
              ),
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
                    : RefreshIndicator(
                        color: isDark ? AppColors.best : AppColors.ink,
                        // 당겨서 새로고침 — 드래그 시트와 제스처 충돌 없음
                        onRefresh: () async => onRetry(),
                        child: ListView(
                          controller: controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                          const _Grabber(),
                          if (ranking != null) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 4, 0, 12),
                              child: Row(
                                children: [
                                  CongestionChip(
                                      level: ranking!.congestionLevel),
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
                          for (var i = 0; i < stations.length; i++) ...[
                            StaggerIn(
                              index: i,
                              child: _cardFor(context, stations[i]),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 카드가 그대로 상세 화면으로 확장되는 공유요소 전환 (OpenContainer)
  Widget _cardFor(BuildContext context, OpinetStation station) {
    final entry = _entryFor(station);
    final isBest = ranking?.best?.station.uniId == station.uniId;
    final scheme = Theme.of(context).colorScheme;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 450),
      // 카드 내부 InkWell이 탭을 소유 → 컨테이너 자체 탭은 끈다
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: scheme.surface,
      middleColor: scheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isBest ? 18 : 16),
      ),
      closedBuilder: (context, open) => StationCard(
        station: station,
        isBest: isBest,
        savingAmount: entry?.result.score,
        detourKm: isBest ? entry?.result.detourKm : null,
        driveTimeMin: entry?.result.driveTimeMin,
        onTap: open,
      ),
      openBuilder: (context, _) => StationDetailScreen(
        station: station,
        position: position,
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

/// 탑바 새로고침 — 탭하면 한 바퀴 회전
class _SpinRefresh extends StatefulWidget {
  const _SpinRefresh({required this.onTap, required this.dark});

  final VoidCallback onTap;
  final bool dark;

  @override
  State<_SpinRefresh> createState() => _SpinRefreshState();
}

class _SpinRefreshState extends State<_SpinRefresh>
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
    return InkWell(
      onTap: () {
        if (!AppMotion.reduceMotion(context)) _c.forward(from: 0);
        widget.onTap();
      },
      child: RotationTransition(
        turns: _turns,
        child: Icon(
          Icons.refresh,
          size: 18,
          color: widget.dark ? AppColors.ink : Colors.white,
        ),
      ),
    );
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
