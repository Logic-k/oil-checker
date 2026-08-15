import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CarProfile', () {
    test('차량 프로필을 등록하고 활성 프로필을 조회한다', () async {
      await db.upsertCarProfile(
        id: null,
        modelName: '쏘나타',
        brand: '현대',
        fuelType: 'B027',
        tankSizeL: 60,
        avgFuelEfficiency: 12.1,
        isActive: true,
      );

      final profile = await db.getActiveCarProfile();
      expect(profile, isNotNull);
      expect(profile!.modelName, '쏘나타');
      expect(profile.brand, '현대');
      expect(profile.fuelType, 'B027');
      expect(profile.tankSizeL, closeTo(60, 0.001));
      expect(profile.avgFuelEfficiency, closeTo(12.1, 0.001));
      expect(profile.isActive, isTrue);
    });

    test('활성 프로필이 없으면 null을 반환한다', () async {
      expect(await db.getActiveCarProfile(), isNull);
    });

    test('새 프로필 활성화 시 기존 활성 프로필이 해제된다', () async {
      await db.upsertCarProfile(
        id: null,
        modelName: '쏘나타',
        brand: '현대',
        fuelType: 'B027',
        tankSizeL: 60,
        avgFuelEfficiency: 12.1,
        isActive: true,
      );
      final first = await db.getActiveCarProfile();
      final firstId = first!.id;

      await db.upsertCarProfile(
        id: null,
        modelName: '그랜저',
        brand: '현대',
        fuelType: 'D047',
        tankSizeL: 70,
        avgFuelEfficiency: 14.2,
        isActive: true,
      );
      await db.setActiveCarProfile(
          (await db.getAllCarProfiles()).firstWhere((p) => p.id != firstId).id);

      final profiles = await db.getAllCarProfiles();
      expect(profiles.where((p) => p.isActive).length, 1);
      expect(
        profiles.where((p) => p.isActive).first.modelName,
        '그랜저',
      );
    });
  });

  group('FuelingHistory', () {
    test('주유 이력을 추가하고 최신순으로 조회한다', () async {
      await db.upsertCarProfile(
        id: null,
        modelName: '쏘나타',
        brand: '현대',
        fuelType: 'B027',
        tankSizeL: 60,
        avgFuelEfficiency: 12.1,
        isActive: true,
      );
      final profile = (await db.getActiveCarProfile())!;

      await db.addFuelingHistory(
        carProfileId: profile.id,
        fueledAt: DateTime(2026, 7, 1, 10),
        odometerKm: 10000,
        liters: 50,
        totalAmountWon: 100000,
        stationName: 'GS칼텍스 서계주유소',
      );
      await db.addFuelingHistory(
        carProfileId: profile.id,
        fueledAt: DateTime(2026, 7, 10, 10),
        odometerKm: 10600,
        liters: 50,
        totalAmountWon: 95000,
        stationName: 'HD현대오일뱅크 갈월동주유소',
      );

      final histories = await db.getFuelingHistories(profile.id);
      expect(histories, hasLength(2));
      expect(histories[0].fueledAt, DateTime(2026, 7, 10, 10)); // 최신순
      expect(histories[1].odometerKm, closeTo(10000, 0.001));
    });

    test('주행거리차 ÷ 주유량으로 실연비를 계산한다', () async {
      await db.upsertCarProfile(
        id: null,
        modelName: '쏘나타',
        brand: '현대',
        fuelType: 'B027',
        tankSizeL: 60,
        avgFuelEfficiency: 12.1,
        isActive: true,
      );
      final profile = (await db.getActiveCarProfile())!;

      await db.addFuelingHistory(
        carProfileId: profile.id,
        fueledAt: DateTime(2026, 7, 1, 10),
        odometerKm: 10000,
        liters: 50,
        totalAmountWon: 100000,
        stationName: 'A',
      );
      await db.addFuelingHistory(
        carProfileId: profile.id,
        fueledAt: DateTime(2026, 7, 10, 10),
        odometerKm: 10600,
        liters: 50,
        totalAmountWon: 95000,
        stationName: 'B',
      );

      // (10600 - 10000) / 50 = 12.0 km/L
      final eff = await db.computeLatestKmPerL(profile.id);
      expect(eff, closeTo(12.0, 0.001));
    });

    test('이력이 1건 이하면 실연비를 계산하지 않는다', () async {
      await db.upsertCarProfile(
        id: null,
        modelName: '쏘나타',
        brand: '현대',
        fuelType: 'B027',
        tankSizeL: 60,
        avgFuelEfficiency: 12.1,
        isActive: true,
      );
      final profile = (await db.getActiveCarProfile())!;
      await db.addFuelingHistory(
        carProfileId: profile.id,
        fueledAt: DateTime(2026, 7, 1, 10),
        odometerKm: 10000,
        liters: 50,
        totalAmountWon: 100000,
        stationName: 'A',
      );

      expect(await db.computeLatestKmPerL(profile.id), isNull);
    });
  });

  group('StationCache', () {
    test('주유소 캐시를 저장하고 가격 오름차순으로 조회한다', () async {
      final now = DateTime.now();
      await db.upsertStationCache([
        StationCacheCompanion.insert(
          uniId: 'A0000232',
          brandCode: 'HDO',
          name: '갈월동주유소',
          price: 1887,
          distanceM: 2169.5,
          gisX: 309369.8437,
          gisY: 549923.2713,
          productCode: 'B027',
          fetchedAt: now,
        ),
        StationCacheCompanion.insert(
          uniId: 'A0009071',
          brandCode: 'HDO',
          name: '장원주유소',
          price: 1911,
          distanceM: 2860.7,
          gisX: 312642.3697,
          gisY: 550902.4588,
          productCode: 'B027',
          fetchedAt: now,
        ),
      ]);

      final stations = await db.getCachedStations(productCode: 'B027');
      expect(stations, hasLength(2));
      expect(stations[0].name, '갈월동주유소'); // 가격 오름차순
      expect(stations[1].price, 1911);
    });

    test('가장 최근 캐시 시각을 반환한다 (TTL 판정용)', () async {
      final old = DateTime(2026, 8, 1, 1);
      final recent = DateTime(2026, 8, 2, 19, 5);
      await db.upsertStationCache([
        StationCacheCompanion.insert(
          uniId: 'A1',
          brandCode: 'HDO',
          name: 'A',
          price: 1800,
          distanceM: 100,
          gisX: 0,
          gisY: 0,
          productCode: 'B027',
          fetchedAt: old,
        ),
        StationCacheCompanion.insert(
          uniId: 'A2',
          brandCode: 'HDO',
          name: 'B',
          price: 1900,
          distanceM: 200,
          gisX: 0,
          gisY: 0,
          productCode: 'B027',
          fetchedAt: recent,
        ),
      ]);

      final latest = await db.getLatestCacheTime(productCode: 'B027');
      expect(latest, recent);
    });
  });
}
