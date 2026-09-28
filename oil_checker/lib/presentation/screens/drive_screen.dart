import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:oil_checker/core/coordinate/katec.dart';
import 'package:oil_checker/core/format/distance_format.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/drive_island.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
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
  const DriveScreen({super.key, this.initialStationId});

  /// 상세 화면 등에서 "드라이브 모드로 보기"로 진입할 때 미리 선택할 주유소.
  final String? initialStationId;

  /// 3D 표시용 OpenFreeMap 스타일 (무료·키 없음, OSM 벡터 타일).
  /// liberty: 도로 라벨·방패가 잘 보이는 컬러풀 스타일. 건물 3D에는
  /// 'openmaptiles' 소스의 'building' 레이어를 돌출시킨다.
  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const double _tilt3d = 58;
  static const double _driveZoom = 16;
  static const String _stationsSource = 'stations';

  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  /// 검색 기준에서 이 거리(m) 이상 벗어나면 "이 근처 다시 찾기" 노출.
  /// Opinet 검색 반경 5km의 절반 — 겹치는 결과를 유지하며 갱신.
  static const double _originDriftM = 2500;

  ml.MapLibreMapController? _map;
  bool _styleReady = false;
  bool _is3d = true;
  bool _following = true;
  bool _programmaticCamera = false;
  bool _islandExpanded = false;
  bool _originDrifted = false;
  String? _selectedStationId;
  double? _speedKmh;
  Position? _lastGpsFix;

  /// 진행 중인 프로그램 카메라 이동의 세대 — 겹친 애니메이션이
  /// 플래그를 중간에 해제해 사용자 드래그로 오인하는 것을 방지.
  int _cameraGen = 0;

  /// 프로그램 카메라 이동의 무시 윈도우 — 웹의 easeCamera는
  /// fire-and-forget이라 future 해결이 아니라 시간 경과로 해제.
  Timer? _cameraGuardTimer;

  /// 진입 시 pickedLocation — 드라이브 모드가 바꾼 값을 종료 시 복원
  ll2.LatLng? _pickedOnEntry;

  /// dispose에서 ref 사용 금지 → notifier는 initState에서 캐시한다.
  late final PickedLocationNotifier _pickedNotifier;

  @override
  void initState() {
    super.initState();
    _pickedNotifier = ref.read(pickedLocationProvider.notifier);
    _pickedOnEntry = ref.read(pickedLocationProvider);
    _selectedStationId = widget.initialStationId;
    _islandExpanded = _selectedStationId != null;
  }

  @override
  void dispose() {
    _cameraGuardTimer?.cancel();
    _paintTimer?.cancel();
    _buildingsTimer?.cancel();
    _pickedNotifier.set(_pickedOnEntry);
    super.dispose();
  }

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
            // 다이나믹 아일랜드 — 상단 중앙.
            // 웹에서 지도 플랫폼뷰가 포인터 이벤트를 삼키므로
            // PointerInterceptor로 이벤트를 Flutter 쪽에 돌린다.
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PointerInterceptor(
                        child: DriveIsland(
                          data: _islandData(),
                          expanded: _islandExpanded,
                          speedKmh: _speedKmh,
                          onToggle: () => setState(
                            () => _islandExpanded = !_islandExpanded,
                          ),
                        ),
                      ),
                      // 출발지 검색 반경에서 멀어지면 재검색 제안
                      if (_originDrifted) ...[
                        const SizedBox(height: 8),
                        PointerInterceptor(child: _researchButton()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // 닫기 — 좌상단
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: PointerInterceptor(
                  child: _roundButton(
                    icon: Icons.close,
                    tooltip: '드라이브 모드 종료',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            // 지도 컨트롤 — 우하단
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 18),
                  child: PointerInterceptor(
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
                        // 자유 회전 — 데스크톱에서도 버튼으로 돌릴 수 있게
                        _roundButton(
                          icon: Icons.rotate_left,
                          tooltip: '반시계 회전',
                          onTap: () => _rotateBy(-45),
                        ),
                        const SizedBox(height: 10),
                        _roundButton(
                          icon: Icons.rotate_right,
                          tooltip: '시계 회전',
                          onTap: () => _rotateBy(45),
                        ),
                        const SizedBox(height: 10),
                        // 북쪽 정렬 나침반
                        _roundButton(
                          icon: Icons.explore_outlined,
                          tooltip: '북쪽으로 정렬',
                          onTap: _resetNorth,
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
    // async 갭 이전에 읽어둔다 (use_build_context_synchronously)
    final reduceMotion = AppMotion.reduceMotion(context);
    try {
      // 3D 건물 — 평면 building 레이어 위, 라벨 계열 아래에 돌출.
      // 스타일마다 라벨 레이어 id가 달라 첫 심볼성 레이어를 찾아 그 아래에 둔다.
      final belowLabel = await map.getLayerIds().then(
        (ids) => ids
            .map((e) => '$e')
            .firstWhere(
              (id) => id.contains('one_way') || id.contains('label'),
              orElse: () => '',
            ),
      );
      // 진입 시 건물이 바닥에서 솟아오르는 인트로 — reduceMotion이면 즉시
      await map.addFillExtrusionLayer(
        'openmaptiles',
        'buildings-3d',
        ml.FillExtrusionLayerProperties(
          fillExtrusionColor: '#8FA5BC',
          fillExtrusionOpacity: reduceMotion ? 0.88 : 0.0,
          fillExtrusionHeight: [
            ml.Expressions.multiply,
            reduceMotion ? 1.0 : 0.0,
            [ml.Expressions.get, 'render_height'],
          ],
          fillExtrusionBase: [ml.Expressions.get, 'render_min_height'],
        ),
        sourceLayer: 'building',
        belowLayerId: belowLabel.isEmpty ? null : belowLabel,
        minzoom: 13,
      );
      if (!reduceMotion) _riseBuildings();
      await map.addGeoJsonSource(
        DriveScreen._stationsSource,
        const {'type': 'FeatureCollection', 'features': <dynamic>[]},
        // 웹은 문자열 id 미지원 → promoteId로 uniId를 feature id로 승격
        promoteId: 'uniId',
      );
      // 주유소는 원형 점이 아니라 브랜드색 3D 블록 — 진입/갱신 시
      // 바닥에서 솟아오르며 회색 → 브랜드색으로 "색칠"되는 모션.
      // (실제 건물 footprint는 스타일 feature에 고유 id가 없어 못 쓰므로
      //  주유소 좌표에 소형 다각형 필-엑스트루전을 세운다)
      await map.addFillExtrusionLayer(
        DriveScreen._stationsSource,
        'station-blocks',
        ml.FillExtrusionLayerProperties(
          fillExtrusionColor: _brandColorExpr(0.0),
          fillExtrusionHeight: [
            ml.Expressions.multiply,
            0.0,
            [ml.Expressions.get, 'h'],
          ],
          fillExtrusionBase: 0,
          fillExtrusionOpacity: 0.95,
          fillExtrusionVerticalGradient: true,
        ),
        minzoom: 12.5,
      );
      await map.addSymbolLayer(
        DriveScreen._stationsSource,
        'station-prices',
        const ml.SymbolLayerProperties(
          textField: [
            ml.Expressions.concat,
            [
              ml.Expressions.toStringExpression,
              [ml.Expressions.get, 'price'],
            ],
            '원',
          ],
          textFont: ['Noto Sans Regular'],
          textSize: 13,
          textColor: [
            ml.Expressions.caseExpression,
            [ml.Expressions.get, 'best'],
            '#C77700',
            '#31445B',
          ],
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2.4,
          textAnchor: 'bottom',
          textOffset: [0.0, -2.6],
          textAllowOverlap: false,
        ),
        enableInteraction: false,
      );
      map.onFeatureTapped.add(_onFeatureTapped);
    } catch (_) {
      // 스타일이 바뀌거나 소스명이 다르면 오버레이 없이 지도만 표시
    }
    if (mounted) {
      setState(() => _styleReady = true);
      _pushStations();
      // 지도 준비 전에 들어온 마지막 GPS fix 재생 — 퍽이 안 뜨는 사각지대 해소
      final last = _lastGpsFix;
      if (last != null) _onGpsFix(last);
    }
  }

  // ── 데이터 → 지도 ─────────────────────────────────────────────

  void _pushStations() {
    final map = _map;
    if (map == null || !_styleReady) return;
    final stations =
        ref.read(stationsAroundProvider).value ?? const <OpinetStation>[];
    final bestId = ref.read(economyRankingProvider).value?.best?.station.uniId;

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
              'brand': s.brandCode,
              'best': s.uniId == bestId,
              // 블록 높이(m) — 경제성 1위는 더 높게 솟는다
              'h': s.uniId == bestId ? 78.0 : 52.0,
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [_stationFootprint(s)],
            },
          },
      ],
    });
    _paintStations();
  }

  List<double> _stationLngLat(OpinetStation s) {
    final wgs = katecToWgs84(x: s.gisX, y: s.gisY);
    return [wgs.longitude, wgs.latitude];
  }

  /// 주유소 좌표 중심의 소형 12각형 footprint (반경 ~16m) —
  /// 주유소 부지 크기 정도의 블록이 세워지도록 한다.
  List<List<double>> _stationFootprint(OpinetStation s) {
    final c = _stationLngLat(s);
    const r = 24.0;
    final dLat = r / 111320.0;
    final dLng = r / (111320.0 * math.cos(c[1] * math.pi / 180));
    return [
      for (var i = 0; i <= 12; i++)
        [
          c[0] + dLng * math.cos(2 * math.pi * i / 12),
          c[1] + dLat * math.sin(2 * math.pi * i / 12),
        ],
    ];
  }

  /// 브랜드별 색칠 목표색 — best는 골드, 그 외는 정유사 컬러.
  static const _brandTargets = {
    'HDO': 0xE5484D,
    'GSC': 0x2563EB,
    'SKE': 0xF5A524,
    'SOL': 0x0E9F6E,
  };
  static const _brandDefault = 0x7C6BF5;
  static const _brandBest = 0xFFB020;
  static const _paintBase = 0xAAB7C4; // 색칠 전 회색 블록

  static String _hex(int rgb) =>
      '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static int _lerpRgb(int a, int b, double f) {
    int ch(int sh) =>
        ((((a >> sh) & 0xFF) + ((((b >> sh) & 0xFF) - ((a >> sh) & 0xFF)) * f)))
            .round();
    return (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  /// 진행률 f의 브랜드색 match 표현식 — 회색에서 각 브랜드색으로 채워진다.
  static List<dynamic> _brandColorExpr(double f) => [
    ml.Expressions.caseExpression,
    [ml.Expressions.get, 'best'],
    _hex(_lerpRgb(_paintBase, _brandBest, f)),
    [
      'match',
      [ml.Expressions.get, 'brand'],
      for (final e in _brandTargets.entries) ...[
        e.key,
        _hex(_lerpRgb(_paintBase, e.value, f)),
      ],
      _hex(_lerpRgb(_paintBase, _brandDefault, f)),
    ],
  ];

  Timer? _paintTimer;

  /// 주유소 블록이 솟아오르며 회색 → 브랜드색으로 색칠되는 모션.
  /// 높이 배수와 색을 같은 진행률로 함께 올려 "아래서 위로 칠해지는"
  /// 느낌을 만든다 (웹은 transition 미지원 → 스텝 업데이트).
  void _paintStations() {
    _paintTimer?.cancel();
    if (AppMotion.reduceMotion(context)) {
      _map?.setLayerProperties(
        'station-blocks',
        ml.FillExtrusionLayerProperties(
          fillExtrusionColor: _brandColorExpr(1.0),
          fillExtrusionHeight: [ml.Expressions.get, 'h'],
          fillExtrusionBase: 0,
          fillExtrusionOpacity: 0.95,
          fillExtrusionVerticalGradient: true,
        ),
      );
      return;
    }
    const steps = 16;
    var i = 0;
    _paintTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      i++;
      final f = Curves.easeOutCubic.transform(i / steps);
      if (!mounted) {
        t.cancel();
        return;
      }
      _map?.setLayerProperties(
        'station-blocks',
        ml.FillExtrusionLayerProperties(
          fillExtrusionColor: _brandColorExpr(f),
          fillExtrusionHeight: [
            ml.Expressions.multiply,
            f,
            [ml.Expressions.get, 'h'],
          ],
          fillExtrusionBase: 0,
          fillExtrusionOpacity: 0.95,
          fillExtrusionVerticalGradient: true,
        ),
      );
      if (i >= steps) t.cancel();
    });
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
    _lastGpsFix = p;
    _updateOriginDrift(p);
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

  /// 차의 최신 위치 — GPS 스트림 우선, 첫 fix 전엔 검색 기준 위치로 폴백
  Position? _latestCarPosition() =>
      ref.read(gpsPositionProvider).value ??
      ref.read(effectivePositionProvider).value;

  /// 검색 기준과의 거리 갱신 — 멀어지면 재검색 버튼 노출
  /// (검색 자체는 수동: AGENTS.md §5-3 API 호출 한도 정책 유지)
  void _updateOriginDrift(Position p) {
    final origin = ref.read(effectivePositionProvider).value;
    if (origin == null) return;
    final drifted =
        Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          p.latitude,
          p.longitude,
        ) >
        _originDriftM;
    if (drifted != _originDrifted && mounted) {
      setState(() => _originDrifted = drifted);
    }
  }

  /// "이 근처 다시 찾기" — 검색 기준을 현재 차 위치로 이동 (수동 갱신)
  Widget _researchButton() {
    return Pressable(
      child: Material(
        color: AppColors.best,
        borderRadius: BorderRadius.circular(999),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _searchHere,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 15, color: AppColors.ink),
                SizedBox(width: 6),
                Text(
                  '이 근처 주유소 다시 찾기',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _searchHere() {
    final p = _latestCarPosition();
    if (p == null) return;
    // 검색 기준 이동 — pickedLocation 변경이 주유소·랭킹 재조회를 유발한다
    ref
        .read(pickedLocationProvider.notifier)
        .set(ll2.LatLng(p.latitude, p.longitude));
    setState(() {
      _originDrifted = false;
      _selectedStationId = null;
    });
  }

  void _flyTo(ml.LatLng target, {double? bearing, Duration? duration}) {
    final map = _map;
    if (map == null || !_styleReady) return;
    final gen = ++_cameraGen;
    _programmaticCamera = true;
    final anim = duration ?? const Duration(milliseconds: 900);
    // maplibre_gl_web의 easeCamera는 fire-and-forget — future 해결 시점이
    // 아니라 애니메이션 시간(+여유) 경과 후 플래그를 내린다. 겹친 호출은
    // 최신 세대만이 해제권을 갖는다.
    _cameraGuardTimer?.cancel();
    _cameraGuardTimer = Timer(anim + const Duration(milliseconds: 250), () {
      if (gen == _cameraGen) _programmaticCamera = false;
    });
    unawaited(
      map.easeCamera(
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
        duration: anim,
      ),
    );
  }

  /// 사용자 드래그로 팔로우 해제 — 프로그램 카메라 이동은 무시
  void _onCameraMove(ml.CameraPosition position) {
    if (_following && !_programmaticCamera) {
      setState(() => _following = false);
    }
  }

  void _recenter() {
    setState(() => _following = true);
    final p = _latestCarPosition();
    if (p != null) {
      _flyTo(
        ml.LatLng(p.latitude, p.longitude),
        bearing: _map?.cameraPosition?.bearing,
      );
    }
  }

  void _toggle3d() {
    setState(() => _is3d = !_is3d);
    final p = _latestCarPosition();
    if (p != null) {
      _flyTo(
        ml.LatLng(p.latitude, p.longitude),
        bearing: _map?.cameraPosition?.bearing ?? 0,
        duration: const Duration(milliseconds: 600),
      );
    }
    if (_is3d && !AppMotion.reduceMotion(context)) _riseBuildings();
  }

  /// 진행 중인 건물 rise 타이머 — 재시작 겹침과 dispose 후
  /// 지도 컨트롤러 접근을 막기 위해 상태로 관리한다.
  Timer? _buildingsTimer;

  /// 진입/3D 전환 시 건물이 바닥에서 솟아오르는 연출 —
  /// fill-extrusion-height 배수를 스텝으로 올린다 (웹은 transition 미지원).
  void _riseBuildings() {
    _buildingsTimer?.cancel();
    const steps = 14;
    var i = 0;
    _buildingsTimer = Timer.periodic(const Duration(milliseconds: 55), (t) {
      i++;
      final f = Curves.easeOutCubic.transform(i / steps);
      if (!mounted) {
        t.cancel();
        return;
      }
      _map?.setLayerProperties(
        'buildings-3d',
        ml.FillExtrusionLayerProperties(
          fillExtrusionColor: '#8FA5BC',
          fillExtrusionOpacity: 0.88 * f,
          fillExtrusionHeight: [
            ml.Expressions.multiply,
            f,
            [ml.Expressions.get, 'render_height'],
          ],
          fillExtrusionBase: [ml.Expressions.get, 'render_min_height'],
        ),
      );
      if (i >= steps) t.cancel();
    });
  }

  /// 버튼 회전 — 데스크톱 웹(우클릭 드래그 미지원 사용자)용 회전 진입점
  void _rotateBy(double deltaDeg) {
    final cam = _map?.cameraPosition;
    if (cam == null || !_styleReady) return;
    final gen = ++_cameraGen;
    _programmaticCamera = true;
    _cameraGuardTimer?.cancel();
    _cameraGuardTimer = Timer(const Duration(milliseconds: 700), () {
      if (gen == _cameraGen) _programmaticCamera = false;
    });
    unawaited(
      _map?.easeCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: cam.target,
            zoom: cam.zoom,
            tilt: cam.tilt,
            bearing: cam.bearing + deltaDeg,
          ),
        ),
        duration: const Duration(milliseconds: 450),
      ),
    );
    // 수동 회전은 팔로우 해제 — 헤드업 베어링과 충돌 방지
    if (_following) setState(() => _following = false);
  }

  /// 북쪽 정렬 — 현재 위치/틸트 유지, 베어링만 0으로
  void _resetNorth() {
    final cam = _map?.cameraPosition;
    if (cam == null || !_styleReady) return;
    final gen = ++_cameraGen;
    _programmaticCamera = true;
    _cameraGuardTimer?.cancel();
    _cameraGuardTimer = Timer(const Duration(milliseconds: 700), () {
      if (gen == _cameraGen) _programmaticCamera = false;
    });
    unawaited(
      _map?.easeCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: cam.target,
            zoom: cam.zoom,
            tilt: cam.tilt,
            bearing: 0,
          ),
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
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
      savingsText: score != null && score > 0 ? '+${formatWon(score)}원' : null,
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
