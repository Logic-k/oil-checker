import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:oil_checker/core/coordinate/katec.dart';
import 'package:oil_checker/core/format/distance_format.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/drive_island.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';

/// 드라이브 모드 — 카 디스플레이 화면.
///
/// 3D 기울임 지도(MapLibre + OpenFreeMap 벡터 타일, 건물 돌출) 위에
/// 다이나믹 아일랜드 스타일의 플로팅 표시를 얹는다. 주행 중 필요한
/// 정보(속도·가장 경제적인 주유소·절약액)만 남긴 운전 모드.
///
/// - 지도: maplibre_gl + OpenFreeMap dark 스타일 (키 불필요·OSM 벡터)
///   * tilt 58° + fill-extrusion으로 3D 건물 표시
///   * 위치 퍽은 ManualLocationSource — 우리 GPS 스트림을 직접 주입
///     (플랫폼 권한 채널을 다시 타지 않아 웹에서도 동일하게 동작)
/// - 아일랜드: 상단 중앙 알약 — 탭하면 카드로 확장, 지도 탭하면 접힘
/// - 팔로우: GPS 이동 시 카메라가 따라가고, 사용자가 드래그하면 해제
///   (우하단 버튼으로 복귀)
class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key});

  /// 3D 표시용 OpenFreeMap 스타일 (무료·키 없음, OSM 벡터 타일).
  /// 건물 3D에는 'openmaptiles' 소스의 'building' 레이어를 돌출시킨다.
  static const styleUrl = 'https://tiles.openfreemap.org/styles/dark';

  static const double _tilt3d = 58;
  static const double _driveZoom = 16;
  static const String _stationsSource = 'stations';

  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  ml.MapLibreMapController? _map;
  bool _styleReady = false;
  bool _is3d = true;
  bool _following = true;
  bool _programmaticCamera = false;
  bool _islandExpanded = false;
  String? _selectedStationId;
  double? _speedKmh;

  @override
  Widget build(BuildContext context) {
    // GPS 스트림 → 위치 퍽 + 카메라 팔로우
    ref.listen(gpsPositionProvider, (_, next) {
      final p = next.value;
      if (p != null) _onGpsFix(p);
    });
    // 검색 기준 위치 변경(위치 지정 등) → 한 번 이동
    ref.listen(effectivePositionProvider, (_, next) {
      final p = next.value;
      if (p != null && _following) {
        _flyTo(ml.LatLng(p.latitude, p.longitude));
      }
    });
    // 주유소/랭킹 변경 → 지도 레이어 데이터 갱신
    ref.listen(stationsAroundProvider, (_, _) => _pushStations());
    ref.listen(economyRankingProvider, (_, _) => _pushStations());

    final positionAsync = ref.watch(effectivePositionProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: positionAsync.when(
        loading: () => const AppSkeleton(),
        error: (e, _) => AppEmptyView(
          icon: Icons.location_off_outlined,
          title: '위치를 확인할 수 없어요',
          message: '위치 권한을 허용한 뒤 다시 시도해주세요.',
          actionLabel: '다시 시도',
          onAction: () => ref.invalidate(currentLocationProvider),
        ),
        data: (position) => Stack(
          children: [
            Positioned.fill(child: _buildMap(position)),
            // 다이나믹 아일랜드 — 상단 중앙
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: DriveIsland(
                    data: _islandData(),
                    expanded: _islandExpanded,
                    speedKmh: _speedKmh,
                    onToggle: () => setState(
                        () => _islandExpanded = !_islandExpanded),
                  ),
                ),
              ),
            ),
            // 닫기 — 좌상단
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: _roundButton(
                  icon: Icons.close,
                  tooltip: '드라이브 모드 종료',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            // 지도 컨트롤 — 우하단
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roundButton(
                        icon: _is3d
                            ? Icons.threed_rotation
                            : Icons.map_outlined,
                        tooltip: _is3d ? '2D로 보기' : '3D로 보기',
                        onTap: _toggle3d,
                      ),
                      const SizedBox(height: 10),
                      _roundButton(
                        icon: _following
                            ? Icons.gps_fixed
                            : Icons.gps_not_fixed,
                        tooltip: _following ? '따라가는 중' : '내 위치로',
                        accent: _following,
                        onTap: _recenter,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(Position position) {
    return ml.MapLibreMap(
      styleString: DriveScreen.styleUrl,
      initialCameraPosition: ml.CameraPosition(
        target: ml.LatLng(position.latitude, position.longitude),
        zoom: DriveScreen._driveZoom,
        tilt: DriveScreen._tilt3d,
      ),
      onMapCreated: (controller) => _map = controller,
      onStyleLoadedCallback: _onStyleLoaded,
      // 우리 GPS(geolocator) 스트림을 퍽에 주입 — 권한 채널 중복 없음
      myLocationEnabled: true,
      locationSource: const ml.ManualLocationSource(),
      myLocationRenderMode: ml.MyLocationRenderMode.gps,
      compassEnabled: false,
      attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
      trackCameraPosition: true,
      onCameraMove: _onCameraMove,
      onMapClick: (_, _) {
        if (_islandExpanded) {
          setState(() => _islandExpanded = false);
        }
      },
    );
  }

  // ── 지도 스타일 셋업 ────────────────────────────────────────────

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    try {
      // 3D 건물 — 평면 building 레이어 위, 도로 라벨 아래에 돌출
      await map.addFillExtrusionLayer(
        'openmaptiles',
        'buildings-3d',
        const ml.FillExtrusionLayerProperties(
          fillExtrusionColor: '#26303C',
          fillExtrusionOpacity: 0.85,
          fillExtrusionHeight: [ml.Expressions.get, 'render_height'],
          fillExtrusionBase: [ml.Expressions.get, 'render_min_height'],
        ),
        sourceLayer: 'building',
        belowLayerId: 'road_oneway',
        minzoom: 13,
      );
      await map.addGeoJsonSource(
        DriveScreen._stationsSource,
        const {'type': 'FeatureCollection', 'features': <dynamic>[]},
        // 웹은 문자열 id 미지원 → promoteId로 uniId를 feature id로 승격
        promoteId: 'uniId',
      );
      await map.addCircleLayer(
        DriveScreen._stationsSource,
        'station-circles',
        const ml.CircleLayerProperties(
          circleRadius: [
            ml.Expressions.interpolate,
            'linear',
            [ml.Expressions.zoom],
            13, 5,
            17, 9,
          ],
          circleColor: [
            ml.Expressions.match,
            [ml.Expressions.get, 'best'],
            true, '#FFB020', // 경제성 1위 — 골드
            '#DDE5EC',
          ],
          circleStrokeColor: '#0B1016',
          circleStrokeWidth: 2,
        ),
      );
      await map.addSymbolLayer(
        DriveScreen._stationsSource,
        'station-prices',
        const ml.SymbolLayerProperties(
          textField: [
            ml.Expressions.concat,
            [ml.Expressions.toStringExpression, [ml.Expressions.get, 'price']],
            '원',
          ],
          textFont: ['Noto Sans Regular'],
          textSize: 11,
          textColor: [
            ml.Expressions.match,
            [ml.Expressions.get, 'best'],
            true, '#FFB020',
            '#C9D3DD',
          ],
          textHaloColor: '#0B1016',
          textHaloWidth: 1.4,
          textAnchor: 'bottom',
          textOffset: [0.0, -1.3],
          textAllowOverlap: false,
        ),
      );
      map.onFeatureTapped.add(_onFeatureTapped);
    } catch (_) {
      // 스타일이 바뀌거나 소스명이 다르면 오버레이 없이 지도만 표시
    }
    if (mounted) {
      setState(() => _styleReady = true);
      _pushStations();
    }
  }

  // ── 데이터 → 지도 ─────────────────────────────────────────────

  void _pushStations() {
    final map = _map;
    if (map == null || !_styleReady) return;
    final stations =
        ref.read(stationsAroundProvider).value ?? const <OpinetStation>[];
    final bestId =
        ref.read(economyRankingProvider).value?.best?.station.uniId;

    map.setGeoJsonSource(DriveScreen._stationsSource, {
      'type': 'FeatureCollection',
      'features': [
        for (final s in stations)
          {
            'type': 'Feature',
            // Android는 promoteId가 없어 feature id를 직접 넣는다
            'id': s.uniId,
            'properties': {
              'uniId': s.uniId,
              'name': s.name,
              'price': s.price,
              'best': s.uniId == bestId,
            },
            'geometry': {
              'type': 'Point',
              'coordinates': _stationLngLat(s),
            },
          },
      ],
    });
  }

  List<double> _stationLngLat(OpinetStation s) {
    final wgs = katecToWgs84(x: s.gisX, y: s.gisY);
    return [wgs.longitude, wgs.latitude];
  }

  void _onFeatureTapped(
    math.Point<double> point,
    ml.LatLng coordinates,
    String id,
    String layerId,
    ml.Annotation? annotation,
  ) {
    if (!layerId.startsWith('station-')) return;
    setState(() {
      _selectedStationId = id;
      _islandExpanded = true;
    });
  }

  // ── GPS / 카메라 팔로우 ────────────────────────────────────────

  void _onGpsFix(Position p) {
    final target = ml.LatLng(p.latitude, p.longitude);
    _map?.updateManualLocation(
      ml.ManualLocationUpdate(
        target: target,
        bearing: p.heading >= 0 ? p.heading : null,
        speed: p.speed,
        horizontalAccuracy: p.accuracy,
      ),
    );
    final kmh = p.speed * 3.6;
    if (kmh != _speedKmh) setState(() => _speedKmh = kmh);
    if (_following) {
      // 주행 중이면 진행방향으로 헤드업, 정차 시 베어링 유지
      final bearing = p.speed > 1.5 && p.heading >= 0
          ? p.heading
          : _map?.cameraPosition?.bearing;
      _flyTo(target, bearing: bearing);
    }
  }

  Future<void> _flyTo(ml.LatLng target, {double? bearing}) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    _programmaticCamera = true;
    try {
      await map.easeCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: target,
            zoom: DriveScreen._driveZoom,
            tilt: _is3d ? DriveScreen._tilt3d : 0,
            bearing: bearing ?? 0,
          ),
        ),
        // GPS 추적은 등속 보간이 끊김 없이 부드럽다
        interpolation: ml.CameraAnimationInterpolation.linear,
        duration: const Duration(milliseconds: 900),
      );
    } finally {
      _programmaticCamera = false;
    }
  }

  /// 사용자 드래그로 팔로우 해제 — 프로그램 카메라 이동은 무시
  void _onCameraMove(ml.CameraPosition position) {
    if (_following && !_programmaticCamera) {
      setState(() => _following = false);
    }
  }

  Future<void> _recenter() async {
    setState(() => _following = true);
    final p = ref.read(effectivePositionProvider).value ??
        ref.read(gpsPositionProvider).value;
    if (p != null) {
      await _flyTo(
        ml.LatLng(p.latitude, p.longitude),
        bearing: _map?.cameraPosition?.bearing,
      );
    }
  }

  Future<void> _toggle3d() async {
    setState(() => _is3d = !_is3d);
    final p = ref.read(effectivePositionProvider).value ??
        ref.read(gpsPositionProvider).value;
    if (p != null) {
      _programmaticCamera = true;
      try {
        await _map?.easeCamera(
          ml.CameraUpdate.newCameraPosition(
            ml.CameraPosition(
              target: ml.LatLng(p.latitude, p.longitude),
              zoom: DriveScreen._driveZoom,
              tilt: _is3d ? DriveScreen._tilt3d : 0,
              bearing: _map?.cameraPosition?.bearing ?? 0,
            ),
          ),
          duration: const Duration(milliseconds: 600),
        );
      } finally {
        _programmaticCamera = false;
      }
    }
  }

  // ── 아일랜드 데이터 ────────────────────────────────────────────

  DriveIslandData _islandData() {
    final stationsAsync = ref.watch(stationsAroundProvider);
    final ranking = ref.watch(economyRankingProvider).value;

    if (stationsAsync.hasError) {
      return const DriveIslandData(
        title: '주유소 정보를 불러오지 못했어요',
        status: DriveIslandStatus.error,
      );
    }
    final stations = stationsAsync.value;
    if (stations == null || stationsAsync.isLoading) {
      return const DriveIslandData(
        title: '주변 주유소 찾는 중…',
        status: DriveIslandStatus.loading,
      );
    }
    if (stations.isEmpty) {
      return const DriveIslandData(
        title: '주변에 주유소가 없습니다',
        status: DriveIslandStatus.empty,
      );
    }

    // 지도에서 탭한 주유소 우선, 없으면 경제성 1위
    final selected = _selectedStationId;
    EconomyRankingEntry? selectedEntry;
    if (selected != null) {
      for (final e in ranking?.ranked ?? const <EconomyRankingEntry>[]) {
        if (e.station.uniId == selected) {
          selectedEntry = e;
          break;
        }
      }
    }

    OpinetStation station;
    double? score;
    double? detourKm;
    double? driveTimeMin;
    if (selectedEntry != null) {
      station = selectedEntry.station;
      score = selectedEntry.result.score;
      detourKm = selectedEntry.result.detourKm;
      driveTimeMin = selectedEntry.result.driveTimeMin;
    } else if (selected != null) {
      station = stations.firstWhere(
        (s) => s.uniId == selected,
        orElse: () => stations.first,
      );
    } else {
      final best = ranking?.best;
      if (best != null) {
        station = best.station;
        score = best.result.score;
        detourKm = best.result.detourKm;
        driveTimeMin = best.result.driveTimeMin;
      } else {
        station = stations.first;
      }
    }

    final detourText = detourKm == null
        ? null
        : '왕복 ${detourKm.toStringAsFixed(1)}km'
            '${driveTimeMin == null ? '' : ' · 약 ${driveTimeMin.round()}분'}';

    return DriveIslandData(
      title: station.name,
      subtitle:
          '${AppColors.brandLabel(station.brandCode)} · 내 위치에서 ${formatDistance(station.distanceM)}',
      priceText: '${formatWon(station.price)}원/L',
      savingsText:
          score != null && score > 0 ? '+${formatWon(score)}원' : null,
      detailText: detourText,
    );
  }

  // ── 컨트롤 버튼 ────────────────────────────────────────────────

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return Pressable(
      child: Material(
        color: accent ? AppColors.best : AppColors.inkSoft,
        shape: const CircleBorder(),
        elevation: 3,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                icon,
                size: 21,
                color: accent ? AppColors.ink : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
