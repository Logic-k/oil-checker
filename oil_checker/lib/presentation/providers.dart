// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:oil_checker/core/coordinate/katec.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/opinet/opinet_station.dart';
import 'package:oil_checker/core/traffic/congestion.dart';
import 'package:oil_checker/data/car_spec/car_spec_loader.dart';
import 'package:oil_checker/data/db/app_database.dart';
import 'package:oil_checker/data/opinet/opinet_repository.dart';
import 'package:oil_checker/data/routing/osrm_client.dart';
import 'package:oil_checker/data/routing/routing_client.dart';
import 'package:oil_checker/domain/economy/economy_engine.dart';

/// Opinet API 키 (PLAN §3.1 실측 검증 완료)
///
/// 보안: 소스코드에 평문으로 두지 않는다. 키 노출 경로가 서로 다르므로:
/// - 웹: 같은 origin 프록시(`/opinet`)가 서버측 환경변수 `OPINET_API_CODE`로
///   주입한다 → 클라이언트 JS 번들에 키 미포함
/// - 네이티브: `--dart-define=OPINET_API_CODE=...`로 빌드 시 주입한다
///   (미지정 시 null → Opinet 호출은 프록시 경유로만 가능)
/// - 로컬 개발: `tool/opinet_proxy.dart`가 환경변수 `OPINET_API_CODE`를 읽는다
const String _opinetApiCode = String.fromEnvironment('OPINET_API_CODE');

/// 설정 화면 표시용 — Opinet 키의 마스킹된 앞 4자리.
///
/// 웹: 프록시가 서버측에서 주입하므로 "서버측 주입"으로 표시.
/// 네이티브: dart-define으로 주입된 키의 앞 4자리만 표시 (미설정 시 안내).
String opinetApiKeyMasked() {
  if (kIsWeb) return '서버측 주입';
  if (_opinetApiCode.isEmpty) return '미설정';
  return '${_opinetApiCode.substring(0, 4)}****';
}

/// 데이터베이스 (Drift, 웹/네이티브 모두 지원)
///
/// 웹에서는 sqlite3.wasm + drift_worker.dart.js (IndexedDB 기반) 사용.
/// 네이티브에서는 파일 기반 SQLite 사용.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    driftDatabase(
      name: 'oil_checker',
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'),
            )
          : null,
    ),
  );
  ref.onDispose(db.close);
  return db;
});

/// Opinet API base URL 오버라이드 (`--dart-define=OPINET_BASE_URL=...`)
///
/// 지정 시 웹/네이티브 기본값 대신 사용한다. Android 에뮬레이터처럼 외부
/// 네트워크가 차단된 환경에서 호스트의 로컬 프록시(`tool/opinet_proxy.dart`)를
/// 경유해 검증할 때 유용하다 (예: `http://10.0.2.2:8899/opinet`).
const String _opinetBaseUrlOverride = String.fromEnvironment('OPINET_BASE_URL');

/// 라우팅 base URL 오버라이드 (`--dart-define=ROUTING_BASE_URL=...`)
/// 자가 OSRM 또는 상용 라우팅으로 교체 시 사용 (기본: router.project-osrm.org).
const String _routingBaseUrlOverride = String.fromEnvironment('ROUTING_BASE_URL');

/// Opinet HTTP 클라이언트
///
/// 웹: 같은 origin의 프록시 `/opinet` 경로 사용 (Opinet API가 CORS 헤더를
/// 제공하지 않아 브라우저 직접 호출이 차단됨 — `tool/opinet_proxy.dart` 참고).
/// 네이티브: Opinet 서버 직접 호출.
final opinetClientProvider = Provider<OpinetClient>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  return OpinetClient(
    dio: dio,
    // 웹: 프록시가 서버측에서 키 주입 (클라이언트 JS에 키 미포함).
    // 네이티브: 빌드 시 dart-define으로 주입한 키 사용.
    apiCode: kIsWeb ? null : (_opinetApiCode.isEmpty ? null : _opinetApiCode),
    baseUrl: _opinetBaseUrlOverride.isNotEmpty
        ? _opinetBaseUrlOverride
        : (kIsWeb ? '/opinet' : OpinetClient.defaultBaseUrl),
  );
});

/// Opinet 저장소 (TTL 캐시 + 오프라인 폴백)
///
/// 캐시 TTL: 가격 갱신 시각(1/2/9/12/16/19시)과 무관하게
/// 6시간 이내 재사용, 이후 재호출 (PLAN §3.3 기준 하루 4회 수준)
final opinetRepositoryProvider = Provider<OpinetRepository>((ref) {
  return OpinetRepository(
    client: ref.watch(opinetClientProvider),
    db: ref.watch(appDatabaseProvider),
    cacheTtl: const Duration(hours: 6),
  );
});

/// 주유소 상세 정보 (detailById.do) — [uniId]별 autoDispose 캐시
///
/// 상세 화면 진입 시에만 호출된다. 상세 API는 캐시되지 않으므로
/// 화면 재진입 시마다 최신 정보를 가져온다.
final stationDetailProvider =
    FutureProvider.autoDispose.family<OpinetStationDetail?, String>((ref, uniId) {
  return ref.watch(opinetClientProvider).fetchStationDetail(uniId: uniId);
});

/// 차종·연비 CSV 로더 (앱 임베드 에셋, 연료탱크 매핑 포함)
final carSpecLoaderProvider = FutureProvider<CarSpecLoader>((ref) async {
  final data = await rootBundle.loadString('assets/data/car_fuel_economy.csv');
  String? tank;
  try {
    tank = await rootBundle
        .loadString('assets/data/fuel_tank_capacity.csv');
  } catch (_) {
    // 에셋 없어도 연비 검색은 동작 — 탱크 자동입력만 생략
  }
  return CarSpecLoader.fromCsv(data, tankCsv: tank);
});

/// 차종별 실사 이미지 매핑 (pattern → asset 경로).
///
/// tool/fetch_car_images.py가 Wikimedia Commons에서 수집한 결과
/// (assets/data/car_image_map.csv). 없으면 실루엣 폴백만 사용.
final carPhotoMapProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final csv = await rootBundle.loadString('assets/data/car_image_map.csv');
    final map = <String, String>{};
    for (final line in csv.split('\n').skip(1)) {
      final i = line.indexOf(',');
      if (i <= 0) continue;
      final j = line.indexOf(',', i + 1);
      if (j <= i + 1) continue;
      map[line.substring(0, i).trim()] = line.substring(i + 1, j).trim();
    }
    return map;
  } catch (_) {
    return const {};
  }
});

/// 활성 차량 프로필 (없으면 null) — DB 변경 시 자동 갱신
final activeCarProfileProvider = StreamProvider<CarProfile?>((ref) {
  return ref.watch(appDatabaseProvider).watchActiveCarProfile();
});

/// 모든 차량 프로필 — DB 변경 시 자동 갱신
final allCarProfilesProvider = StreamProvider<List<CarProfile>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllCarProfiles();
});

/// 특정 차량의 주유 이력 (최신순) — DB 변경 시 자동 갱신
final fuelingHistoriesProvider =
    StreamProvider.autoDispose.family<List<FuelingHistory>, int>((ref, id) {
  return ref.watch(appDatabaseProvider).watchFuelingHistories(id);
});

/// 현재 위치 (WGS84) — GPS 실패 시 예외
///
/// Android: 런타임 위치 권한 확인 후 요청. 웹: 브라우저가 권한 프롬프트를
/// 자동 표시하므로 추가 처리 없음. 권한이 영구 거부되면 예외를 던진다.
final currentLocationProvider = FutureProvider<Position>((ref) async {
  // Android/iOS: 런타임 권한 요청 (웹은 kIsWeb 경로로 건너뜀)
  if (!kIsWeb) {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        permission == LocationPermission.deniedForever
            ? '위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.'
            : '위치 권한이 필요합니다.',
      );
    }
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  );
});

/// 지도에서 사용자가 직접 지정한 검색 기준 위치 (null이면 실제 GPS 사용)
///
/// 홈 지도의 [위치 지정] 모드에서 탭한 좌표. 설정 시 이 좌표 기준으로
/// 주변 주유소와 경제성 랭킹을 다시 계산한다. [내 위치] 버튼으로 null 복귀.
class PickedLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void set(LatLng? value) => state = value;
}

final pickedLocationProvider = NotifierProvider<PickedLocationNotifier, LatLng?>(
  PickedLocationNotifier.new,
);

/// 위치 지정 모드 활성 여부 — true면 지도 탭 시 [pickedLocationProvider] 설정
class IsPickingLocationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isPickingLocationProvider = NotifierProvider<IsPickingLocationNotifier, bool>(
  IsPickingLocationNotifier.new,
);

/// 목적지 위치 (Phase 3-C) — null이면 왕복(내위치→후보→복귀), 지정 시 편도(내위치→후보→목적지)
class DestinationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void set(LatLng? value) => state = value;
}

final destinationProvider = NotifierProvider<DestinationNotifier, LatLng?>(
  DestinationNotifier.new,
);

/// 실시간 GPS 위치 스트림 — 지도 파란 점(내 위치) 실시간 이동용
///
/// TODO(pw) 10m 이상 이동 시마다 갱신된다. 주유소 목록은 새로고침 버튼으로만
/// 갱신하는 "가벼운 실시간" 정책이라 이 스트림은 지도 표시 전용이며
/// [effectivePositionProvider]의 검색 기준에는 직접 연결하지 않는다.
final gpsPositionProvider = StreamProvider<Position>((ref) {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  );
});

/// 검색 기준 위치 — 지정 위치 우선, 없으면 실제 GPS
///
/// 주변 주유소 조회와 경제성 랭킹이 이 제공자를 사용한다.
/// [pickedLocationProvider]가 바뀌면 주유소·가격 계산이 재실행된다.
final effectivePositionProvider = FutureProvider<Position>((ref) async {
  // 지정 위치가 있으면 GPS 조회 없이 바로 사용 — 위치 권한 거부
  // (데스크톱 브라우저 등)에서도 지도·검색이 동작하도록 한다.
  final picked = ref.watch(pickedLocationProvider);
  if (picked != null) {
    return Position(
      latitude: picked.latitude,
      longitude: picked.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
  return ref.watch(currentLocationProvider.future);
});

/// 활성 차량의 기름 종류에 맞는 Opinet 제품 코드
///
/// 차량 프로필이 없으면 휘발유(B027) 기본값.
final fuelProductCodeProvider = Provider<String>((ref) {
  final profile = ref.watch(activeCarProfileProvider).value;
  if (profile?.fuelType == OpinetClient.productDiesel) {
    return OpinetClient.productDiesel;
  }
  if (profile?.fuelType == OpinetClient.productLpg) {
    return OpinetClient.productLpg;
  }
  return OpinetClient.productGasoline;
});

/// 현재 위치 기준 반경 내 주유소 (캐시 우선, 가격순)
///
/// 위치가 변경되면 자동 재조회. 위치 로딩 중에는 로딩 상태 유지.
final stationsAroundProvider = FutureProvider<List<OpinetStation>>((ref) async {
  final position = await ref.watch(effectivePositionProvider.future);
  final productCode = ref.watch(fuelProductCodeProvider);
  final repository = ref.watch(opinetRepositoryProvider);
  final katec = wgs84ToKatec(
    latitude: position.latitude,
    longitude: position.longitude,
  );
  return repository.getStationsAround(
    x: katec.x,
    y: katec.y,
    productCode: productCode,
    sort: 1, // 가격순
  );
});

/// 라우팅 클라이언트 — 실제 도로 거리·시간 계산 (추상화)
///
/// 공개 데모 서버(무료·키 불필요·CORS 허용)를 기본으로 사용.
/// `--dart-define=ROUTING_BASE_URL=https://your-host` 로 교체 가능.
/// `RoutingClient` 인터페이스에만 의존하므로 자가 OSRM/상용 API로 교체 가능.
final routingClientProvider = Provider<RoutingClient>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  return OsrmClient(
    dio: dio,
    baseUrl: _routingBaseUrlOverride.isNotEmpty
        ? _routingBaseUrlOverride
        : OsrmClient.defaultBaseUrl,
  );
});

/// @deprecated Use [routingClientProvider] instead — 하위 호환용 alias
@Deprecated('Use routingClientProvider instead')
final osrmClientProvider = Provider<OsrmClient>((ref) {
  final client = ref.watch(routingClientProvider);
  if (client is OsrmClient) return client;
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  return OsrmClient(
    dio: dio,
    baseUrl: _routingBaseUrlOverride.isNotEmpty
        ? _routingBaseUrlOverride
        : OsrmClient.defaultBaseUrl,
  );
});

/// 교통 혼잡 모델 — 요일·시간대별 가중치
final congestionModelProvider = Provider<CongestionModel>((ref) {
  return const CongestionModel();
});

/// 운전자의 시간 가치 (원/분)
///
/// 0이면 시간 비용 미반영(연료비만). 개인 설정 기능 전까지 상수로 둔다.
/// 참고: 최저시급(2025년 10,030원/시) 기준 약 167원/분.
const double kTimeValueWonPerMin = 80;

/// 경제성 랭킹 엔트리 — 주유소 + 계산 결과
class EconomyRankingEntry implements HasScore {
  const EconomyRankingEntry({
    required this.station,
    required this.result,
  });

  final OpinetStation station;
  final EconomyResult result;

  @override
  double get score => result.score;
}

/// 경제성 랭킹 결과 — 사용된 연비(실연비/폴백)와 정렬된 목록
class EconomyRankingResult {
  const EconomyRankingResult({
    required this.fuelEfficiency,
    required this.isRealEfficiency,
    required this.ranked,
    required this.congestionLevel,
    required this.baselinePrice,
    required this.fillUpLiters,
  });

  /// 계산에 사용된 연비 (km/L) — 실연비 우선, 없으면 수동/표시연비
  final double fuelEfficiency;

  /// [fuelEfficiency]가 실제 주행 기록 기반 실연비인지 여부
  final bool isRealEfficiency;

  /// 경제성 점수 내림차순 정렬된 주유소 목록 (기준 주유소 제외)
  final List<EconomyRankingEntry> ranked;

  /// 계산 시점의 도로 혼잡 단계 (UI 표시용)
  final CongestionLevel congestionLevel;

  /// 기준 주유소(가장 가까운 곳) 가격 — 카드별 리터당 가격차 계산용
  final int baselinePrice;

  /// 주유량(L) = 차량 탱크 용량 — 카드별 총절약액 표시용
  final double fillUpLiters;

  /// 가장 경제적인 주유소 (1위) — 없으면 null
  EconomyRankingEntry? get best => ranked.isEmpty ? null : ranked.first;
}

/// OSRM table 행렬에 포함할 후보 주유소 최대 개수.
///
/// 공개 데모 서버(router.project-osrm.org, 비상업 1 req/s) 부담 경감을 위한
/// 후보 축소: 직선거리 예비 점수 상위 N개만 실제 도로 거리·시간으로 정밀
/// 계산하고, 나머지는 직선거리 예비 점수를 그대로 사용한다. (SYNTHESIS §3)
const int kOsrmCandidateCount = 10;

/// 경제성 랭킹 계산 (실연비 + 실제 도로 + 교통 혼잡 반영)
///
/// - 연비 우선순위: 주행 기록 실연비 → 수동 입력 → 차량 표시연비
/// - 기준 주유소: 가장 가까운 곳 (가격 비교 대상)
/// - 후보 축소: 직선거리 예비 점수 상위 [kOsrmCandidateCount]개만 OSRM으로
///   정밀 계산, 나머지는 예비 점수 유지 (공개 데모 서버 부담 경감)
/// - 우회거리·시간: OSRM table 서비스로 **실제 도로** 기준 계산
///   - 왕복 = 내위치→후보 + 후보→내위치 (행렬 대칭 이용)
/// - 시간대별 혼잡 가중치를 예상 시간에 반영 (출퇴근 1.5x)
/// - 경제성 점수 = 절약액 - (연료비용 + 시간비용), 내림차순 정렬
///
/// 랭킹 탭과 홈 탭이 같은 계산을 공유한다.
final economyRankingProvider =
    FutureProvider<EconomyRankingResult?>((ref) async {
  final profile = ref.watch(activeCarProfileProvider).value;
  if (profile == null) return null;

  final stations = await ref.watch(stationsAroundProvider.future);
  if (stations.isEmpty) return null;

  final db = ref.watch(appDatabaseProvider);
  final routing = ref.watch(routingClientProvider);
  final congestion = ref.watch(congestionModelProvider);
  final position = await ref.watch(effectivePositionProvider.future);

  // 실연비: 주행 기록 → 수동 입력 → 표시연비
  final realKmPerL = await db.computeLatestKmPerL(profile.id);
  final isRealEfficiency = realKmPerL != null;
  final fuelEfficiency =
      realKmPerL ?? profile.manualFuelEfficiency ?? profile.avgFuelEfficiency;

  final now = DateTime.now();
  final congestionFactor = congestion.factorAt(now);
  final congestionLevel = congestion.levelAt(now);

  // 기준 주유소 = 가장 가까운 곳
  final baseline = stations.reduce(
    (a, b) => a.distanceM <= b.distanceM ? a : b,
  );

  // --- 후보 축소: 직선거리 예비 점수 상위 N개만 OSRM(실제 도로)로 정밀 계산 ---
  // 공개 데모 서버 부담 경감 (SYNTHESIS §3). 나머지는 예비 점수를 그대로 사용.
  final preliminary = <EconomyRankingEntry>[];
  for (final station in stations) {
    if (station.uniId == baseline.uniId) continue; // 기준 주유소 제외
    // 폴백과 동일한 직선거리 기반 예상 시간 (도심 평균 40km/h 가정)
    final detourKm = computeDetourKm(
      fromToStationKm: station.distanceM / 1000,
    );
    final baseDriveMin = (detourKm / 40) * 60;
    final driveTimeMin = applyCongestion(
      baseDriveMin: baseDriveMin,
      congestionFactor: congestionFactor,
    );
    final result = calculateEconomy(
      baselinePrice: baseline.price,
      candidatePrice: station.price,
      fillUpLiters: profile.tankSizeL,
      detourKm: detourKm,
      driveTimeMin: driveTimeMin,
      fuelEfficiency: fuelEfficiency,
      timeValueWonPerMin: kTimeValueWonPerMin,
    );
    preliminary.add(EconomyRankingEntry(station: station, result: result));
  }
  preliminary.sort((a, b) => b.result.score.compareTo(a.result.score));

  // 정밀 계산 대상 = 예비 점수 상위 N개 (승산 있는 후보만 실제 도로로)
  final candidates = preliminary.take(kOsrmCandidateCount).toList();
  final candidateIds = {for (final e in candidates) e.station.uniId};

  // --- 실제 도로 거리·시간 (OSRM table: 1회 호출, 후보 N개만) ---
  // 인덱스 0 = 현재 위치, 1..N = 후보, (N+1) = 목적지(있을 때)
  final destination = ref.watch(destinationProvider);
  final myPoint = LatLng(position.latitude, position.longitude);
  final points = [
    myPoint,
    for (final e in candidates) _stationLatLng(e.station),
    if (destination case final d?) d,
  ];
  final hasDestination = destination != null;
  final destIdx = hasDestination ? points.length - 1 : -1;

  final ({List<List<double>> distances, List<List<double>> durations}) matrix;
  try {
    matrix = await routing.table(points: points);
  } on RoutingException {
    // OSRM 실패 시 직선거리 폴백 (기존 동작) — 라우팅 불능이어도 앱은 동작
    return _fallbackRanking(
      stations: stations,
      baseline: baseline,
      profile: profile,
      fuelEfficiency: fuelEfficiency,
      isRealEfficiency: isRealEfficiency,
      congestionLevel: congestionLevel,
    );
  }

  // 후보는 실제 도로 결과로 재계산, 비후보는 예비 점수 유지
  final results = <EconomyRankingEntry>[];
  for (var i = 0; i < candidates.length; i++) {
    final entry = candidates[i];
    final matrixIdx = i + 1; // 행렬 인덱스 (0=내위치)

    // 목적지 있으면 편도(내위치→후보→목적지), 없으면 왕복(내위치→후보→복귀)
    final double detourKm;
    final double baseDriveMin;
    if (hasDestination) {
      detourKm = (matrix.distances[0][matrixIdx] +
              matrix.distances[matrixIdx][destIdx]) /
          1000;
      baseDriveMin =
          (matrix.durations[0][matrixIdx] + matrix.durations[matrixIdx][destIdx]) /
              60;
    } else {
      detourKm = (matrix.distances[0][matrixIdx] +
              matrix.distances[matrixIdx][0]) /
          1000;
      baseDriveMin =
          (matrix.durations[0][matrixIdx] + matrix.durations[matrixIdx][0]) / 60;
    }
    final driveTimeMin = applyCongestion(
      baseDriveMin: baseDriveMin,
      congestionFactor: congestionFactor,
    );

    final result = calculateEconomy(
      baselinePrice: baseline.price,
      candidatePrice: entry.station.price,
      fillUpLiters: profile.tankSizeL,
      detourKm: detourKm,
      driveTimeMin: driveTimeMin,
      fuelEfficiency: fuelEfficiency,
      timeValueWonPerMin: kTimeValueWonPerMin,
    );
    results.add(EconomyRankingEntry(station: entry.station, result: result));
  }
  for (final entry in preliminary) {
    if (candidateIds.contains(entry.station.uniId)) continue;
    results.add(entry); // 비후보: 예비 점수 그대로
  }

  results.sort((a, b) => b.result.score.compareTo(a.result.score));
  return EconomyRankingResult(
    fuelEfficiency: fuelEfficiency,
    isRealEfficiency: isRealEfficiency,
    ranked: results,
    congestionLevel: congestionLevel,
    baselinePrice: baseline.price,
    fillUpLiters: profile.tankSizeL,
  );
});

/// OSRM 실패 시 직선거리 기반 폴백 랭킹 (기존 방식 유지)
Future<EconomyRankingResult> _fallbackRanking({
  required List<OpinetStation> stations,
  required OpinetStation baseline,
  required CarProfile profile,
  required double fuelEfficiency,
  required bool isRealEfficiency,
  required CongestionLevel congestionLevel,
}) async {
  final results = <EconomyRankingEntry>[];
  for (final station in stations) {
    if (station.uniId == baseline.uniId) continue;
    final detourKm = computeDetourKm(
      fromToStationKm: station.distanceM / 1000,
    );
    // 폴백: 직선거리 기반 예상 시간 (도심 평균 40km/h 가정)
    final baseDriveMin = (detourKm / 40) * 60;
    final result = calculateEconomy(
      baselinePrice: baseline.price,
      candidatePrice: station.price,
      fillUpLiters: profile.tankSizeL,
      detourKm: detourKm,
      driveTimeMin: baseDriveMin,
      fuelEfficiency: fuelEfficiency,
      timeValueWonPerMin: kTimeValueWonPerMin,
    );
    results.add(EconomyRankingEntry(station: station, result: result));
  }
  results.sort((a, b) => b.result.score.compareTo(a.result.score));
  return EconomyRankingResult(
    fuelEfficiency: fuelEfficiency,
    isRealEfficiency: isRealEfficiency,
    ranked: results,
    congestionLevel: congestionLevel,
    baselinePrice: baseline.price,
    fillUpLiters: profile.tankSizeL,
  );
}

/// OpinetStation의 KATEC 좌표 → WGS84 LatLng 변환 (OSRM용)
LatLng _stationLatLng(OpinetStation station) {
  final wgs84 = katecToWgs84(x: station.gisX, y: station.gisY);
  return LatLng(wgs84.latitude, wgs84.longitude);
}
