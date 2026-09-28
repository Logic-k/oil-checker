import 'package:drift/drift.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/data/car_spec/fuel_type_inference.dart';

part 'app_database.g.dart';

/// 차량 프로필 (PLAN §5.2 CarProfile)
class CarProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 모델명 (CSV 모델명)
  TextColumn get modelName => text()();

  /// 제조(수입사)
  TextColumn get brand => text().withDefault(const Constant(''))();

  /// 기름 종류 — Opinet 제품 코드 (B027 휘발유 / D047 경유 / K015 LPG)
  TextColumn get fuelType => text()();

  /// 탱크용량 (L)
  RealColumn get tankSizeL => real().withDefault(const Constant(50.0))();

  /// 차종 평균 연비 (임베드 CSV, km/L)
  RealColumn get avgFuelEfficiency => real().withDefault(const Constant(0))();

  /// 사용자 입력 실연비 (km/L, null이면 미입력)
  RealColumn get manualFuelEfficiency => real().nullable()();

  /// 주유이력 기반 최신 실연비 (km/L, null이면 미측정)
  RealColumn get latestRecordedKmPerL => real().nullable()();

  /// 활성 프로필 여부 (한 번에 하나만 active)
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 주유 이력 (PLAN §2.1-4)
class FuelingHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 소속 차량 프로필
  IntColumn get carProfileId => integer().references(CarProfiles, #id)();

  /// 주유 일시
  DateTimeColumn get fueledAt => dateTime()();

  /// 주유 시점 주행거리계 (km) — 실연비 계산용
  RealColumn get odometerKm => real()();

  /// 주유량 (L)
  RealColumn get liters => real()();

  /// 총 금액 (원)
  RealColumn get totalAmountWon => real()();

  /// 주유소 이름
  TextColumn get stationName => text()();

  /// 주유소 고유 ID
  TextColumn get stationUniId => text().withDefault(const Constant(''))();
}

/// 주유소 캐시 (PLAN §3.3 — 갱신 시각 직후 1회 호출 → TTL까지 캐시 사용)
class StationCache extends Table {
  /// 주유소 고유 ID (UNI_ID)
  TextColumn get uniId => text()();

  /// 정유사 코드 (HDO, GSC, SKE, SOL...)
  TextColumn get brandCode => text()();

  /// 상호명
  TextColumn get name => text()();

  /// 가격 (원)
  IntColumn get price => integer()();

  /// 거리 (m)
  RealColumn get distanceM => real()();

  /// KATEC X 좌표
  RealColumn get gisX => real()();

  /// KATEC Y 좌표
  RealColumn get gisY => real()();

  /// 기름 종류 (B027/D047...)
  TextColumn get productCode => text()();

  /// 캐시 저장 시각 (TTL 판정용)
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {uniId, productCode};
}

@DriftDatabase(tables: [CarProfiles, FuelingHistories, StationCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting(super.e) : super();

  /// v2: 스키마 변경 없음 — v1에서 모든 차량이 휘발유로 저장되던 버그를
  /// 한 번 보정한다 ([reinferFuelTypes]).
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // 테이블 구조는 v1과 같다. 데이터 보정은 beforeOpen에서 한다
          // (마이그레이션이 끝난 뒤라 일반 쿼리를 안전하게 쓸 수 있다).
        },
        beforeOpen: (details) async {
          final before = details.versionBefore;
          if (before != null && before < 2) {
            await reinferFuelTypes();
          }
        },
      );

  // ── 차량 프로필 ───────────────────────────────────────────────

  /// v1 보정: 휘발유(B027)로 저장된 프로필만 모델명으로 다시 추론해
  /// 경유·LPG로 고친다. 고친 프로필 수를 반환한다.
  ///
  /// v1은 연료를 고를 방법이 없었으므로 B027 값은 사용자 선택이 아니라
  /// 버그의 결과다. v2부터는 사용자가 고른 값을 건드리지 않는다
  /// (스키마 버전 업그레이드 때 한 번만 실행).
  Future<int> reinferFuelTypes() async {
    final profiles = await (select(carProfiles)
          ..where((t) => t.fuelType.equals(OpinetClient.productGasoline)))
        .get();
    var fixed = 0;
    for (final profile in profiles) {
      final inferred = inferFuelProductCode(profile.modelName);
      if (inferred == profile.fuelType) continue;
      await updateCarProfileFuelType(profile.id, inferred);
      fixed++;
    }
    return fixed;
  }

  /// 차량의 연료 종류(Opinet 제품 코드) 변경
  Future<void> updateCarProfileFuelType(int id, String fuelType) async {
    await (update(carProfiles)..where((t) => t.id.equals(id)))
        .write(CarProfilesCompanion(fuelType: Value(fuelType)));
  }

  /// 차량 프로필 등록/수정
  Future<void> upsertCarProfile({
    required int? id,
    required String modelName,
    required String brand,
    required String fuelType,
    required double tankSizeL,
    required double avgFuelEfficiency,
    double? manualFuelEfficiency,
    bool isActive = false,
  }) async {
    await into(carProfiles).insertOnConflictUpdate(CarProfilesCompanion.insert(
      id: id == null ? const Value.absent() : Value(id),
      modelName: modelName,
      brand: Value(brand),
      fuelType: fuelType,
      tankSizeL: Value(tankSizeL),
      avgFuelEfficiency: Value(avgFuelEfficiency),
      manualFuelEfficiency: Value(manualFuelEfficiency),
      isActive: Value(isActive),
    ));
  }

  /// 활성 차량 프로필 조회 (없으면 null)
  Future<CarProfile?> getActiveCarProfile() async {
    final query = select(carProfiles)
      ..where((t) => t.isActive.equals(true))
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// 활성 차량 프로필 실시간 감시 (Drift watch — DB 변경 시 자동 갱신)
  Stream<CarProfile?> watchActiveCarProfile() {
    final query = select(carProfiles)
      ..where((t) => t.isActive.equals(true))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  /// 모든 차량 프로필
  Future<List<CarProfile>> getAllCarProfiles() => select(carProfiles).get();

  /// 모든 차량 프로필 실시간 감시
  Stream<List<CarProfile>> watchAllCarProfiles() => select(carProfiles).watch();

  /// 프로필 활성화 (기존 active 해제 후 지정 id 활성)
  Future<void> setActiveCarProfile(int id) async {
    await (update(carProfiles)..where((t) => t.isActive.equals(true)))
        .write(const CarProfilesCompanion(isActive: Value(false)));
    await (update(carProfiles)..where((t) => t.id.equals(id)))
        .write(const CarProfilesCompanion(isActive: Value(true)));
  }

  // ── 주유 이력 ─────────────────────────────────────────────────

  /// 주유 이력 추가
  Future<int> addFuelingHistory({
    required int carProfileId,
    required DateTime fueledAt,
    required double odometerKm,
    required double liters,
    required double totalAmountWon,
    required String stationName,
    String stationUniId = '',
  }) {
    return into(fuelingHistories).insert(
      FuelingHistoriesCompanion.insert(
        carProfileId: carProfileId,
        fueledAt: fueledAt,
        odometerKm: odometerKm,
        liters: liters,
        totalAmountWon: totalAmountWon,
        stationName: stationName,
        stationUniId: Value(stationUniId),
      ),
    );
  }

  /// 차량의 주유 이력 (최신순)
  Future<List<FuelingHistory>> getFuelingHistories(int carProfileId) {
    final query = select(fuelingHistories)
      ..where((t) => t.carProfileId.equals(carProfileId))
      ..orderBy([(t) => OrderingTerm.desc(t.fueledAt)]);
    return query.get();
  }

  /// 차량의 주유 이력 실시간 감시 (최신순)
  Stream<List<FuelingHistory>> watchFuelingHistories(int carProfileId) {
    final query = select(fuelingHistories)
      ..where((t) => t.carProfileId.equals(carProfileId))
      ..orderBy([(t) => OrderingTerm.desc(t.fueledAt)]);
    return query.watch();
  }

  /// 최근 2회 이력으로 실연비 계산 (주행거리차 ÷ 주유량)
  ///
  /// 주행거리계 기준: (최신 odometer - 이전 odometer) / 최신 주유량
  /// 이상치 필터: 거리 ≤0, 연비 3~30km/L 밖은 제외 (다음 쌍으로 탐색)
  Future<double?> computeLatestKmPerL(int carProfileId) async {
    final histories = await getFuelingHistories(carProfileId);
    if (histories.length < 2) return null;
    for (var i = 0; i < histories.length - 1; i++) {
      final latest = histories[i];
      final previous = histories[i + 1];
      final distanceKm = latest.odometerKm - previous.odometerKm;
      if (distanceKm <= 0 || latest.liters <= 0) continue;
      final kmPerL = distanceKm / latest.liters;
      if (kmPerL < 3 || kmPerL > 30) continue;
      return kmPerL;
    }
    return null;
  }

  // ── 주유소 캐시 ───────────────────────────────────────────────

  /// 주유소 목록 캐시 저장 (기존 항목 덮어쓰기)
  Future<void> upsertStationCache(List<StationCacheCompanion> stations) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(stationCache, stations);
    });
  }

  /// 캐시된 주유소 목록 조회
  Future<List<StationCacheData>> getCachedStations({
    required String productCode,
  }) {
    final query = select(stationCache)
      ..where((t) => t.productCode.equals(productCode))
      ..orderBy([(t) => OrderingTerm.asc(t.price)]);
    return query.get();
  }

  /// 캐시 유효성 확인 (가장 최근 fetchedAt 반환, 없으면 null)
  Future<DateTime?> getLatestCacheTime({required String productCode}) async {
    final query = select(stationCache)
      ..where((t) => t.productCode.equals(productCode))
      ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.fetchedAt;
  }
}
