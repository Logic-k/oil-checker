import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/data/db/app_database.dart';

/// v1(모든 차량이 휘발유로 저장되던 버전) → v2 업그레이드 시 연료 보정
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('oc_migration_');
    file = File('${dir.path}${Platform.pathSeparator}app.sqlite');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> addProfile(
    AppDatabase db,
    String modelName, {
    String fuelType = 'B027',
    bool isActive = false,
  }) {
    return db.upsertCarProfile(
      id: null,
      modelName: modelName,
      brand: '',
      fuelType: fuelType,
      tankSizeL: 60,
      avgFuelEfficiency: 12,
      isActive: isActive,
    );
  }

  Future<Map<String, String>> fuelByModel(AppDatabase db) async => {
        for (final p in await db.getAllCarProfiles()) p.modelName: p.fuelType,
      };

  test('v1 DB를 열면 휘발유로 잘못 저장된 경유·LPG 차량을 고친다', () async {
    var db = AppDatabase(NativeDatabase(file));
    await addProfile(db, '쏘렌토(MQ4) 2.2 디젤 2WD', isActive: true);
    await addProfile(db, 'K5(JF) 2.0LPI 6MT(15)');
    await addProfile(db, '그랜저(GN7) 2.5 GDi');
    // v1 파일인 것처럼 스키마 버전을 되돌린다 → 다음에 열 때 v1→v2 업그레이드
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final fuels = await fuelByModel(db);
    expect(fuels['쏘렌토(MQ4) 2.2 디젤 2WD'], 'D047');
    expect(fuels['K5(JF) 2.0LPI 6MT(15)'], 'K015');
    expect(fuels['그랜저(GN7) 2.5 GDi'], 'B027');
    // 활성 프로필(경유)이 바로 경유 가격 조회에 쓰인다
    expect((await db.getActiveCarProfile())!.fuelType, 'D047');
    await db.close();
  });

  test('v2 DB는 다시 열어도 사용자가 고른 연료를 건드리지 않는다', () async {
    var db = AppDatabase(NativeDatabase(file));
    // v2에서 사용자가 직접 휘발유를 고른 경우 (추론과 달라도 존중)
    await addProfile(db, '쏘렌토(MQ4) 2.2 디젤 2WD');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect((await fuelByModel(db))['쏘렌토(MQ4) 2.2 디젤 2WD'], 'B027');
    await db.close();
  });

  test('연료 종류를 바꿀 수 있다', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await addProfile(db, 'K5(JF) 2.0LPI 6MT(15)', isActive: true);
    final profile = (await db.getActiveCarProfile())!;

    await db.updateCarProfileFuelType(profile.id, 'K015');
    expect((await db.getActiveCarProfile())!.fuelType, 'K015');
    await db.close();
  });
}
