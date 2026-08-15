// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CarProfilesTable extends CarProfiles
    with TableInfo<$CarProfilesTable, CarProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CarProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tankSizeLMeta = const VerificationMeta(
    'tankSizeL',
  );
  @override
  late final GeneratedColumn<double> tankSizeL = GeneratedColumn<double>(
    'tank_size_l',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(50.0),
  );
  static const VerificationMeta _avgFuelEfficiencyMeta = const VerificationMeta(
    'avgFuelEfficiency',
  );
  @override
  late final GeneratedColumn<double> avgFuelEfficiency =
      GeneratedColumn<double>(
        'avg_fuel_efficiency',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _manualFuelEfficiencyMeta =
      const VerificationMeta('manualFuelEfficiency');
  @override
  late final GeneratedColumn<double> manualFuelEfficiency =
      GeneratedColumn<double>(
        'manual_fuel_efficiency',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestRecordedKmPerLMeta =
      const VerificationMeta('latestRecordedKmPerL');
  @override
  late final GeneratedColumn<double> latestRecordedKmPerL =
      GeneratedColumn<double>(
        'latest_recorded_km_per_l',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    modelName,
    brand,
    fuelType,
    tankSizeL,
    avgFuelEfficiency,
    manualFuelEfficiency,
    latestRecordedKmPerL,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'car_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CarProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_modelNameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelTypeMeta);
    }
    if (data.containsKey('tank_size_l')) {
      context.handle(
        _tankSizeLMeta,
        tankSizeL.isAcceptableOrUnknown(data['tank_size_l']!, _tankSizeLMeta),
      );
    }
    if (data.containsKey('avg_fuel_efficiency')) {
      context.handle(
        _avgFuelEfficiencyMeta,
        avgFuelEfficiency.isAcceptableOrUnknown(
          data['avg_fuel_efficiency']!,
          _avgFuelEfficiencyMeta,
        ),
      );
    }
    if (data.containsKey('manual_fuel_efficiency')) {
      context.handle(
        _manualFuelEfficiencyMeta,
        manualFuelEfficiency.isAcceptableOrUnknown(
          data['manual_fuel_efficiency']!,
          _manualFuelEfficiencyMeta,
        ),
      );
    }
    if (data.containsKey('latest_recorded_km_per_l')) {
      context.handle(
        _latestRecordedKmPerLMeta,
        latestRecordedKmPerL.isAcceptableOrUnknown(
          data['latest_recorded_km_per_l']!,
          _latestRecordedKmPerLMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CarProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CarProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      )!,
      tankSizeL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tank_size_l'],
      )!,
      avgFuelEfficiency: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_fuel_efficiency'],
      )!,
      manualFuelEfficiency: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}manual_fuel_efficiency'],
      ),
      latestRecordedKmPerL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latest_recorded_km_per_l'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CarProfilesTable createAlias(String alias) {
    return $CarProfilesTable(attachedDatabase, alias);
  }
}

class CarProfile extends DataClass implements Insertable<CarProfile> {
  final int id;

  /// 모델명 (CSV 모델명)
  final String modelName;

  /// 제조(수입사)
  final String brand;

  /// 기름 종류 (B027 휘발유 / D047 경유)
  final String fuelType;

  /// 탱크용량 (L)
  final double tankSizeL;

  /// 차종 평균 연비 (임베드 CSV, km/L)
  final double avgFuelEfficiency;

  /// 사용자 입력 실연비 (km/L, null이면 미입력)
  final double? manualFuelEfficiency;

  /// 주유이력 기반 최신 실연비 (km/L, null이면 미측정)
  final double? latestRecordedKmPerL;

  /// 활성 프로필 여부 (한 번에 하나만 active)
  final bool isActive;
  final DateTime createdAt;
  const CarProfile({
    required this.id,
    required this.modelName,
    required this.brand,
    required this.fuelType,
    required this.tankSizeL,
    required this.avgFuelEfficiency,
    this.manualFuelEfficiency,
    this.latestRecordedKmPerL,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['model_name'] = Variable<String>(modelName);
    map['brand'] = Variable<String>(brand);
    map['fuel_type'] = Variable<String>(fuelType);
    map['tank_size_l'] = Variable<double>(tankSizeL);
    map['avg_fuel_efficiency'] = Variable<double>(avgFuelEfficiency);
    if (!nullToAbsent || manualFuelEfficiency != null) {
      map['manual_fuel_efficiency'] = Variable<double>(manualFuelEfficiency);
    }
    if (!nullToAbsent || latestRecordedKmPerL != null) {
      map['latest_recorded_km_per_l'] = Variable<double>(latestRecordedKmPerL);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CarProfilesCompanion toCompanion(bool nullToAbsent) {
    return CarProfilesCompanion(
      id: Value(id),
      modelName: Value(modelName),
      brand: Value(brand),
      fuelType: Value(fuelType),
      tankSizeL: Value(tankSizeL),
      avgFuelEfficiency: Value(avgFuelEfficiency),
      manualFuelEfficiency: manualFuelEfficiency == null && nullToAbsent
          ? const Value.absent()
          : Value(manualFuelEfficiency),
      latestRecordedKmPerL: latestRecordedKmPerL == null && nullToAbsent
          ? const Value.absent()
          : Value(latestRecordedKmPerL),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory CarProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CarProfile(
      id: serializer.fromJson<int>(json['id']),
      modelName: serializer.fromJson<String>(json['modelName']),
      brand: serializer.fromJson<String>(json['brand']),
      fuelType: serializer.fromJson<String>(json['fuelType']),
      tankSizeL: serializer.fromJson<double>(json['tankSizeL']),
      avgFuelEfficiency: serializer.fromJson<double>(json['avgFuelEfficiency']),
      manualFuelEfficiency: serializer.fromJson<double?>(
        json['manualFuelEfficiency'],
      ),
      latestRecordedKmPerL: serializer.fromJson<double?>(
        json['latestRecordedKmPerL'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'modelName': serializer.toJson<String>(modelName),
      'brand': serializer.toJson<String>(brand),
      'fuelType': serializer.toJson<String>(fuelType),
      'tankSizeL': serializer.toJson<double>(tankSizeL),
      'avgFuelEfficiency': serializer.toJson<double>(avgFuelEfficiency),
      'manualFuelEfficiency': serializer.toJson<double?>(manualFuelEfficiency),
      'latestRecordedKmPerL': serializer.toJson<double?>(latestRecordedKmPerL),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CarProfile copyWith({
    int? id,
    String? modelName,
    String? brand,
    String? fuelType,
    double? tankSizeL,
    double? avgFuelEfficiency,
    Value<double?> manualFuelEfficiency = const Value.absent(),
    Value<double?> latestRecordedKmPerL = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => CarProfile(
    id: id ?? this.id,
    modelName: modelName ?? this.modelName,
    brand: brand ?? this.brand,
    fuelType: fuelType ?? this.fuelType,
    tankSizeL: tankSizeL ?? this.tankSizeL,
    avgFuelEfficiency: avgFuelEfficiency ?? this.avgFuelEfficiency,
    manualFuelEfficiency: manualFuelEfficiency.present
        ? manualFuelEfficiency.value
        : this.manualFuelEfficiency,
    latestRecordedKmPerL: latestRecordedKmPerL.present
        ? latestRecordedKmPerL.value
        : this.latestRecordedKmPerL,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  CarProfile copyWithCompanion(CarProfilesCompanion data) {
    return CarProfile(
      id: data.id.present ? data.id.value : this.id,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      brand: data.brand.present ? data.brand.value : this.brand,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      tankSizeL: data.tankSizeL.present ? data.tankSizeL.value : this.tankSizeL,
      avgFuelEfficiency: data.avgFuelEfficiency.present
          ? data.avgFuelEfficiency.value
          : this.avgFuelEfficiency,
      manualFuelEfficiency: data.manualFuelEfficiency.present
          ? data.manualFuelEfficiency.value
          : this.manualFuelEfficiency,
      latestRecordedKmPerL: data.latestRecordedKmPerL.present
          ? data.latestRecordedKmPerL.value
          : this.latestRecordedKmPerL,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CarProfile(')
          ..write('id: $id, ')
          ..write('modelName: $modelName, ')
          ..write('brand: $brand, ')
          ..write('fuelType: $fuelType, ')
          ..write('tankSizeL: $tankSizeL, ')
          ..write('avgFuelEfficiency: $avgFuelEfficiency, ')
          ..write('manualFuelEfficiency: $manualFuelEfficiency, ')
          ..write('latestRecordedKmPerL: $latestRecordedKmPerL, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    modelName,
    brand,
    fuelType,
    tankSizeL,
    avgFuelEfficiency,
    manualFuelEfficiency,
    latestRecordedKmPerL,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CarProfile &&
          other.id == this.id &&
          other.modelName == this.modelName &&
          other.brand == this.brand &&
          other.fuelType == this.fuelType &&
          other.tankSizeL == this.tankSizeL &&
          other.avgFuelEfficiency == this.avgFuelEfficiency &&
          other.manualFuelEfficiency == this.manualFuelEfficiency &&
          other.latestRecordedKmPerL == this.latestRecordedKmPerL &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class CarProfilesCompanion extends UpdateCompanion<CarProfile> {
  final Value<int> id;
  final Value<String> modelName;
  final Value<String> brand;
  final Value<String> fuelType;
  final Value<double> tankSizeL;
  final Value<double> avgFuelEfficiency;
  final Value<double?> manualFuelEfficiency;
  final Value<double?> latestRecordedKmPerL;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const CarProfilesCompanion({
    this.id = const Value.absent(),
    this.modelName = const Value.absent(),
    this.brand = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.tankSizeL = const Value.absent(),
    this.avgFuelEfficiency = const Value.absent(),
    this.manualFuelEfficiency = const Value.absent(),
    this.latestRecordedKmPerL = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CarProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String modelName,
    this.brand = const Value.absent(),
    required String fuelType,
    this.tankSizeL = const Value.absent(),
    this.avgFuelEfficiency = const Value.absent(),
    this.manualFuelEfficiency = const Value.absent(),
    this.latestRecordedKmPerL = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : modelName = Value(modelName),
       fuelType = Value(fuelType);
  static Insertable<CarProfile> custom({
    Expression<int>? id,
    Expression<String>? modelName,
    Expression<String>? brand,
    Expression<String>? fuelType,
    Expression<double>? tankSizeL,
    Expression<double>? avgFuelEfficiency,
    Expression<double>? manualFuelEfficiency,
    Expression<double>? latestRecordedKmPerL,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (modelName != null) 'model_name': modelName,
      if (brand != null) 'brand': brand,
      if (fuelType != null) 'fuel_type': fuelType,
      if (tankSizeL != null) 'tank_size_l': tankSizeL,
      if (avgFuelEfficiency != null) 'avg_fuel_efficiency': avgFuelEfficiency,
      if (manualFuelEfficiency != null)
        'manual_fuel_efficiency': manualFuelEfficiency,
      if (latestRecordedKmPerL != null)
        'latest_recorded_km_per_l': latestRecordedKmPerL,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CarProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? modelName,
    Value<String>? brand,
    Value<String>? fuelType,
    Value<double>? tankSizeL,
    Value<double>? avgFuelEfficiency,
    Value<double?>? manualFuelEfficiency,
    Value<double?>? latestRecordedKmPerL,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
  }) {
    return CarProfilesCompanion(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      brand: brand ?? this.brand,
      fuelType: fuelType ?? this.fuelType,
      tankSizeL: tankSizeL ?? this.tankSizeL,
      avgFuelEfficiency: avgFuelEfficiency ?? this.avgFuelEfficiency,
      manualFuelEfficiency: manualFuelEfficiency ?? this.manualFuelEfficiency,
      latestRecordedKmPerL: latestRecordedKmPerL ?? this.latestRecordedKmPerL,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (tankSizeL.present) {
      map['tank_size_l'] = Variable<double>(tankSizeL.value);
    }
    if (avgFuelEfficiency.present) {
      map['avg_fuel_efficiency'] = Variable<double>(avgFuelEfficiency.value);
    }
    if (manualFuelEfficiency.present) {
      map['manual_fuel_efficiency'] = Variable<double>(
        manualFuelEfficiency.value,
      );
    }
    if (latestRecordedKmPerL.present) {
      map['latest_recorded_km_per_l'] = Variable<double>(
        latestRecordedKmPerL.value,
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CarProfilesCompanion(')
          ..write('id: $id, ')
          ..write('modelName: $modelName, ')
          ..write('brand: $brand, ')
          ..write('fuelType: $fuelType, ')
          ..write('tankSizeL: $tankSizeL, ')
          ..write('avgFuelEfficiency: $avgFuelEfficiency, ')
          ..write('manualFuelEfficiency: $manualFuelEfficiency, ')
          ..write('latestRecordedKmPerL: $latestRecordedKmPerL, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FuelingHistoriesTable extends FuelingHistories
    with TableInfo<$FuelingHistoriesTable, FuelingHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelingHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _carProfileIdMeta = const VerificationMeta(
    'carProfileId',
  );
  @override
  late final GeneratedColumn<int> carProfileId = GeneratedColumn<int>(
    'car_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES car_profiles (id)',
    ),
  );
  static const VerificationMeta _fueledAtMeta = const VerificationMeta(
    'fueledAt',
  );
  @override
  late final GeneratedColumn<DateTime> fueledAt = GeneratedColumn<DateTime>(
    'fueled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerKmMeta = const VerificationMeta(
    'odometerKm',
  );
  @override
  late final GeneratedColumn<double> odometerKm = GeneratedColumn<double>(
    'odometer_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _litersMeta = const VerificationMeta('liters');
  @override
  late final GeneratedColumn<double> liters = GeneratedColumn<double>(
    'liters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountWonMeta = const VerificationMeta(
    'totalAmountWon',
  );
  @override
  late final GeneratedColumn<double> totalAmountWon = GeneratedColumn<double>(
    'total_amount_won',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationNameMeta = const VerificationMeta(
    'stationName',
  );
  @override
  late final GeneratedColumn<String> stationName = GeneratedColumn<String>(
    'station_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationUniIdMeta = const VerificationMeta(
    'stationUniId',
  );
  @override
  late final GeneratedColumn<String> stationUniId = GeneratedColumn<String>(
    'station_uni_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    carProfileId,
    fueledAt,
    odometerKm,
    liters,
    totalAmountWon,
    stationName,
    stationUniId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fueling_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelingHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('car_profile_id')) {
      context.handle(
        _carProfileIdMeta,
        carProfileId.isAcceptableOrUnknown(
          data['car_profile_id']!,
          _carProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carProfileIdMeta);
    }
    if (data.containsKey('fueled_at')) {
      context.handle(
        _fueledAtMeta,
        fueledAt.isAcceptableOrUnknown(data['fueled_at']!, _fueledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fueledAtMeta);
    }
    if (data.containsKey('odometer_km')) {
      context.handle(
        _odometerKmMeta,
        odometerKm.isAcceptableOrUnknown(data['odometer_km']!, _odometerKmMeta),
      );
    } else if (isInserting) {
      context.missing(_odometerKmMeta);
    }
    if (data.containsKey('liters')) {
      context.handle(
        _litersMeta,
        liters.isAcceptableOrUnknown(data['liters']!, _litersMeta),
      );
    } else if (isInserting) {
      context.missing(_litersMeta);
    }
    if (data.containsKey('total_amount_won')) {
      context.handle(
        _totalAmountWonMeta,
        totalAmountWon.isAcceptableOrUnknown(
          data['total_amount_won']!,
          _totalAmountWonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountWonMeta);
    }
    if (data.containsKey('station_name')) {
      context.handle(
        _stationNameMeta,
        stationName.isAcceptableOrUnknown(
          data['station_name']!,
          _stationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stationNameMeta);
    }
    if (data.containsKey('station_uni_id')) {
      context.handle(
        _stationUniIdMeta,
        stationUniId.isAcceptableOrUnknown(
          data['station_uni_id']!,
          _stationUniIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FuelingHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelingHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      carProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}car_profile_id'],
      )!,
      fueledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fueled_at'],
      )!,
      odometerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}odometer_km'],
      )!,
      liters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}liters'],
      )!,
      totalAmountWon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount_won'],
      )!,
      stationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_name'],
      )!,
      stationUniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_uni_id'],
      )!,
    );
  }

  @override
  $FuelingHistoriesTable createAlias(String alias) {
    return $FuelingHistoriesTable(attachedDatabase, alias);
  }
}

class FuelingHistory extends DataClass implements Insertable<FuelingHistory> {
  final int id;

  /// 소속 차량 프로필
  final int carProfileId;

  /// 주유 일시
  final DateTime fueledAt;

  /// 주유 시점 주행거리계 (km) — 실연비 계산용
  final double odometerKm;

  /// 주유량 (L)
  final double liters;

  /// 총 금액 (원)
  final double totalAmountWon;

  /// 주유소 이름
  final String stationName;

  /// 주유소 고유 ID
  final String stationUniId;
  const FuelingHistory({
    required this.id,
    required this.carProfileId,
    required this.fueledAt,
    required this.odometerKm,
    required this.liters,
    required this.totalAmountWon,
    required this.stationName,
    required this.stationUniId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['car_profile_id'] = Variable<int>(carProfileId);
    map['fueled_at'] = Variable<DateTime>(fueledAt);
    map['odometer_km'] = Variable<double>(odometerKm);
    map['liters'] = Variable<double>(liters);
    map['total_amount_won'] = Variable<double>(totalAmountWon);
    map['station_name'] = Variable<String>(stationName);
    map['station_uni_id'] = Variable<String>(stationUniId);
    return map;
  }

  FuelingHistoriesCompanion toCompanion(bool nullToAbsent) {
    return FuelingHistoriesCompanion(
      id: Value(id),
      carProfileId: Value(carProfileId),
      fueledAt: Value(fueledAt),
      odometerKm: Value(odometerKm),
      liters: Value(liters),
      totalAmountWon: Value(totalAmountWon),
      stationName: Value(stationName),
      stationUniId: Value(stationUniId),
    );
  }

  factory FuelingHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelingHistory(
      id: serializer.fromJson<int>(json['id']),
      carProfileId: serializer.fromJson<int>(json['carProfileId']),
      fueledAt: serializer.fromJson<DateTime>(json['fueledAt']),
      odometerKm: serializer.fromJson<double>(json['odometerKm']),
      liters: serializer.fromJson<double>(json['liters']),
      totalAmountWon: serializer.fromJson<double>(json['totalAmountWon']),
      stationName: serializer.fromJson<String>(json['stationName']),
      stationUniId: serializer.fromJson<String>(json['stationUniId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'carProfileId': serializer.toJson<int>(carProfileId),
      'fueledAt': serializer.toJson<DateTime>(fueledAt),
      'odometerKm': serializer.toJson<double>(odometerKm),
      'liters': serializer.toJson<double>(liters),
      'totalAmountWon': serializer.toJson<double>(totalAmountWon),
      'stationName': serializer.toJson<String>(stationName),
      'stationUniId': serializer.toJson<String>(stationUniId),
    };
  }

  FuelingHistory copyWith({
    int? id,
    int? carProfileId,
    DateTime? fueledAt,
    double? odometerKm,
    double? liters,
    double? totalAmountWon,
    String? stationName,
    String? stationUniId,
  }) => FuelingHistory(
    id: id ?? this.id,
    carProfileId: carProfileId ?? this.carProfileId,
    fueledAt: fueledAt ?? this.fueledAt,
    odometerKm: odometerKm ?? this.odometerKm,
    liters: liters ?? this.liters,
    totalAmountWon: totalAmountWon ?? this.totalAmountWon,
    stationName: stationName ?? this.stationName,
    stationUniId: stationUniId ?? this.stationUniId,
  );
  FuelingHistory copyWithCompanion(FuelingHistoriesCompanion data) {
    return FuelingHistory(
      id: data.id.present ? data.id.value : this.id,
      carProfileId: data.carProfileId.present
          ? data.carProfileId.value
          : this.carProfileId,
      fueledAt: data.fueledAt.present ? data.fueledAt.value : this.fueledAt,
      odometerKm: data.odometerKm.present
          ? data.odometerKm.value
          : this.odometerKm,
      liters: data.liters.present ? data.liters.value : this.liters,
      totalAmountWon: data.totalAmountWon.present
          ? data.totalAmountWon.value
          : this.totalAmountWon,
      stationName: data.stationName.present
          ? data.stationName.value
          : this.stationName,
      stationUniId: data.stationUniId.present
          ? data.stationUniId.value
          : this.stationUniId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelingHistory(')
          ..write('id: $id, ')
          ..write('carProfileId: $carProfileId, ')
          ..write('fueledAt: $fueledAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('liters: $liters, ')
          ..write('totalAmountWon: $totalAmountWon, ')
          ..write('stationName: $stationName, ')
          ..write('stationUniId: $stationUniId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    carProfileId,
    fueledAt,
    odometerKm,
    liters,
    totalAmountWon,
    stationName,
    stationUniId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelingHistory &&
          other.id == this.id &&
          other.carProfileId == this.carProfileId &&
          other.fueledAt == this.fueledAt &&
          other.odometerKm == this.odometerKm &&
          other.liters == this.liters &&
          other.totalAmountWon == this.totalAmountWon &&
          other.stationName == this.stationName &&
          other.stationUniId == this.stationUniId);
}

class FuelingHistoriesCompanion extends UpdateCompanion<FuelingHistory> {
  final Value<int> id;
  final Value<int> carProfileId;
  final Value<DateTime> fueledAt;
  final Value<double> odometerKm;
  final Value<double> liters;
  final Value<double> totalAmountWon;
  final Value<String> stationName;
  final Value<String> stationUniId;
  const FuelingHistoriesCompanion({
    this.id = const Value.absent(),
    this.carProfileId = const Value.absent(),
    this.fueledAt = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.liters = const Value.absent(),
    this.totalAmountWon = const Value.absent(),
    this.stationName = const Value.absent(),
    this.stationUniId = const Value.absent(),
  });
  FuelingHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required int carProfileId,
    required DateTime fueledAt,
    required double odometerKm,
    required double liters,
    required double totalAmountWon,
    required String stationName,
    this.stationUniId = const Value.absent(),
  }) : carProfileId = Value(carProfileId),
       fueledAt = Value(fueledAt),
       odometerKm = Value(odometerKm),
       liters = Value(liters),
       totalAmountWon = Value(totalAmountWon),
       stationName = Value(stationName);
  static Insertable<FuelingHistory> custom({
    Expression<int>? id,
    Expression<int>? carProfileId,
    Expression<DateTime>? fueledAt,
    Expression<double>? odometerKm,
    Expression<double>? liters,
    Expression<double>? totalAmountWon,
    Expression<String>? stationName,
    Expression<String>? stationUniId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (carProfileId != null) 'car_profile_id': carProfileId,
      if (fueledAt != null) 'fueled_at': fueledAt,
      if (odometerKm != null) 'odometer_km': odometerKm,
      if (liters != null) 'liters': liters,
      if (totalAmountWon != null) 'total_amount_won': totalAmountWon,
      if (stationName != null) 'station_name': stationName,
      if (stationUniId != null) 'station_uni_id': stationUniId,
    });
  }

  FuelingHistoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? carProfileId,
    Value<DateTime>? fueledAt,
    Value<double>? odometerKm,
    Value<double>? liters,
    Value<double>? totalAmountWon,
    Value<String>? stationName,
    Value<String>? stationUniId,
  }) {
    return FuelingHistoriesCompanion(
      id: id ?? this.id,
      carProfileId: carProfileId ?? this.carProfileId,
      fueledAt: fueledAt ?? this.fueledAt,
      odometerKm: odometerKm ?? this.odometerKm,
      liters: liters ?? this.liters,
      totalAmountWon: totalAmountWon ?? this.totalAmountWon,
      stationName: stationName ?? this.stationName,
      stationUniId: stationUniId ?? this.stationUniId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (carProfileId.present) {
      map['car_profile_id'] = Variable<int>(carProfileId.value);
    }
    if (fueledAt.present) {
      map['fueled_at'] = Variable<DateTime>(fueledAt.value);
    }
    if (odometerKm.present) {
      map['odometer_km'] = Variable<double>(odometerKm.value);
    }
    if (liters.present) {
      map['liters'] = Variable<double>(liters.value);
    }
    if (totalAmountWon.present) {
      map['total_amount_won'] = Variable<double>(totalAmountWon.value);
    }
    if (stationName.present) {
      map['station_name'] = Variable<String>(stationName.value);
    }
    if (stationUniId.present) {
      map['station_uni_id'] = Variable<String>(stationUniId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelingHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('carProfileId: $carProfileId, ')
          ..write('fueledAt: $fueledAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('liters: $liters, ')
          ..write('totalAmountWon: $totalAmountWon, ')
          ..write('stationName: $stationName, ')
          ..write('stationUniId: $stationUniId')
          ..write(')'))
        .toString();
  }
}

class $StationCacheTable extends StationCache
    with TableInfo<$StationCacheTable, StationCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uniIdMeta = const VerificationMeta('uniId');
  @override
  late final GeneratedColumn<String> uniId = GeneratedColumn<String>(
    'uni_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandCodeMeta = const VerificationMeta(
    'brandCode',
  );
  @override
  late final GeneratedColumn<String> brandCode = GeneratedColumn<String>(
    'brand_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gisXMeta = const VerificationMeta('gisX');
  @override
  late final GeneratedColumn<double> gisX = GeneratedColumn<double>(
    'gis_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gisYMeta = const VerificationMeta('gisY');
  @override
  late final GeneratedColumn<double> gisY = GeneratedColumn<double>(
    'gis_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uniId,
    brandCode,
    name,
    price,
    distanceM,
    gisX,
    gisY,
    productCode,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'station_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<StationCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uni_id')) {
      context.handle(
        _uniIdMeta,
        uniId.isAcceptableOrUnknown(data['uni_id']!, _uniIdMeta),
      );
    } else if (isInserting) {
      context.missing(_uniIdMeta);
    }
    if (data.containsKey('brand_code')) {
      context.handle(
        _brandCodeMeta,
        brandCode.isAcceptableOrUnknown(data['brand_code']!, _brandCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_brandCodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('gis_x')) {
      context.handle(
        _gisXMeta,
        gisX.isAcceptableOrUnknown(data['gis_x']!, _gisXMeta),
      );
    } else if (isInserting) {
      context.missing(_gisXMeta);
    }
    if (data.containsKey('gis_y')) {
      context.handle(
        _gisYMeta,
        gisY.isAcceptableOrUnknown(data['gis_y']!, _gisYMeta),
      );
    } else if (isInserting) {
      context.missing(_gisYMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uniId, productCode};
  @override
  StationCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StationCacheData(
      uniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uni_id'],
      )!,
      brandCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      gisX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gis_x'],
      )!,
      gisY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gis_y'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $StationCacheTable createAlias(String alias) {
    return $StationCacheTable(attachedDatabase, alias);
  }
}

class StationCacheData extends DataClass
    implements Insertable<StationCacheData> {
  /// 주유소 고유 ID (UNI_ID)
  final String uniId;

  /// 정유사 코드 (HDO, GSC, SKE, SOL...)
  final String brandCode;

  /// 상호명
  final String name;

  /// 가격 (원)
  final int price;

  /// 거리 (m)
  final double distanceM;

  /// KATEC X 좌표
  final double gisX;

  /// KATEC Y 좌표
  final double gisY;

  /// 기름 종류 (B027/D047...)
  final String productCode;

  /// 캐시 저장 시각 (TTL 판정용)
  final DateTime fetchedAt;
  const StationCacheData({
    required this.uniId,
    required this.brandCode,
    required this.name,
    required this.price,
    required this.distanceM,
    required this.gisX,
    required this.gisY,
    required this.productCode,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uni_id'] = Variable<String>(uniId);
    map['brand_code'] = Variable<String>(brandCode);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<int>(price);
    map['distance_m'] = Variable<double>(distanceM);
    map['gis_x'] = Variable<double>(gisX);
    map['gis_y'] = Variable<double>(gisY);
    map['product_code'] = Variable<String>(productCode);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  StationCacheCompanion toCompanion(bool nullToAbsent) {
    return StationCacheCompanion(
      uniId: Value(uniId),
      brandCode: Value(brandCode),
      name: Value(name),
      price: Value(price),
      distanceM: Value(distanceM),
      gisX: Value(gisX),
      gisY: Value(gisY),
      productCode: Value(productCode),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory StationCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StationCacheData(
      uniId: serializer.fromJson<String>(json['uniId']),
      brandCode: serializer.fromJson<String>(json['brandCode']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int>(json['price']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      gisX: serializer.fromJson<double>(json['gisX']),
      gisY: serializer.fromJson<double>(json['gisY']),
      productCode: serializer.fromJson<String>(json['productCode']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uniId': serializer.toJson<String>(uniId),
      'brandCode': serializer.toJson<String>(brandCode),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int>(price),
      'distanceM': serializer.toJson<double>(distanceM),
      'gisX': serializer.toJson<double>(gisX),
      'gisY': serializer.toJson<double>(gisY),
      'productCode': serializer.toJson<String>(productCode),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  StationCacheData copyWith({
    String? uniId,
    String? brandCode,
    String? name,
    int? price,
    double? distanceM,
    double? gisX,
    double? gisY,
    String? productCode,
    DateTime? fetchedAt,
  }) => StationCacheData(
    uniId: uniId ?? this.uniId,
    brandCode: brandCode ?? this.brandCode,
    name: name ?? this.name,
    price: price ?? this.price,
    distanceM: distanceM ?? this.distanceM,
    gisX: gisX ?? this.gisX,
    gisY: gisY ?? this.gisY,
    productCode: productCode ?? this.productCode,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  StationCacheData copyWithCompanion(StationCacheCompanion data) {
    return StationCacheData(
      uniId: data.uniId.present ? data.uniId.value : this.uniId,
      brandCode: data.brandCode.present ? data.brandCode.value : this.brandCode,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      gisX: data.gisX.present ? data.gisX.value : this.gisX,
      gisY: data.gisY.present ? data.gisY.value : this.gisY,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StationCacheData(')
          ..write('uniId: $uniId, ')
          ..write('brandCode: $brandCode, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('distanceM: $distanceM, ')
          ..write('gisX: $gisX, ')
          ..write('gisY: $gisY, ')
          ..write('productCode: $productCode, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uniId,
    brandCode,
    name,
    price,
    distanceM,
    gisX,
    gisY,
    productCode,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StationCacheData &&
          other.uniId == this.uniId &&
          other.brandCode == this.brandCode &&
          other.name == this.name &&
          other.price == this.price &&
          other.distanceM == this.distanceM &&
          other.gisX == this.gisX &&
          other.gisY == this.gisY &&
          other.productCode == this.productCode &&
          other.fetchedAt == this.fetchedAt);
}

class StationCacheCompanion extends UpdateCompanion<StationCacheData> {
  final Value<String> uniId;
  final Value<String> brandCode;
  final Value<String> name;
  final Value<int> price;
  final Value<double> distanceM;
  final Value<double> gisX;
  final Value<double> gisY;
  final Value<String> productCode;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const StationCacheCompanion({
    this.uniId = const Value.absent(),
    this.brandCode = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.gisX = const Value.absent(),
    this.gisY = const Value.absent(),
    this.productCode = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StationCacheCompanion.insert({
    required String uniId,
    required String brandCode,
    required String name,
    required int price,
    required double distanceM,
    required double gisX,
    required double gisY,
    required String productCode,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : uniId = Value(uniId),
       brandCode = Value(brandCode),
       name = Value(name),
       price = Value(price),
       distanceM = Value(distanceM),
       gisX = Value(gisX),
       gisY = Value(gisY),
       productCode = Value(productCode),
       fetchedAt = Value(fetchedAt);
  static Insertable<StationCacheData> custom({
    Expression<String>? uniId,
    Expression<String>? brandCode,
    Expression<String>? name,
    Expression<int>? price,
    Expression<double>? distanceM,
    Expression<double>? gisX,
    Expression<double>? gisY,
    Expression<String>? productCode,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uniId != null) 'uni_id': uniId,
      if (brandCode != null) 'brand_code': brandCode,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (distanceM != null) 'distance_m': distanceM,
      if (gisX != null) 'gis_x': gisX,
      if (gisY != null) 'gis_y': gisY,
      if (productCode != null) 'product_code': productCode,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StationCacheCompanion copyWith({
    Value<String>? uniId,
    Value<String>? brandCode,
    Value<String>? name,
    Value<int>? price,
    Value<double>? distanceM,
    Value<double>? gisX,
    Value<double>? gisY,
    Value<String>? productCode,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return StationCacheCompanion(
      uniId: uniId ?? this.uniId,
      brandCode: brandCode ?? this.brandCode,
      name: name ?? this.name,
      price: price ?? this.price,
      distanceM: distanceM ?? this.distanceM,
      gisX: gisX ?? this.gisX,
      gisY: gisY ?? this.gisY,
      productCode: productCode ?? this.productCode,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uniId.present) {
      map['uni_id'] = Variable<String>(uniId.value);
    }
    if (brandCode.present) {
      map['brand_code'] = Variable<String>(brandCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (gisX.present) {
      map['gis_x'] = Variable<double>(gisX.value);
    }
    if (gisY.present) {
      map['gis_y'] = Variable<double>(gisY.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationCacheCompanion(')
          ..write('uniId: $uniId, ')
          ..write('brandCode: $brandCode, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('distanceM: $distanceM, ')
          ..write('gisX: $gisX, ')
          ..write('gisY: $gisY, ')
          ..write('productCode: $productCode, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CarProfilesTable carProfiles = $CarProfilesTable(this);
  late final $FuelingHistoriesTable fuelingHistories = $FuelingHistoriesTable(
    this,
  );
  late final $StationCacheTable stationCache = $StationCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    carProfiles,
    fuelingHistories,
    stationCache,
  ];
}

typedef $$CarProfilesTableCreateCompanionBuilder =
    CarProfilesCompanion Function({
      Value<int> id,
      required String modelName,
      Value<String> brand,
      required String fuelType,
      Value<double> tankSizeL,
      Value<double> avgFuelEfficiency,
      Value<double?> manualFuelEfficiency,
      Value<double?> latestRecordedKmPerL,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });
typedef $$CarProfilesTableUpdateCompanionBuilder =
    CarProfilesCompanion Function({
      Value<int> id,
      Value<String> modelName,
      Value<String> brand,
      Value<String> fuelType,
      Value<double> tankSizeL,
      Value<double> avgFuelEfficiency,
      Value<double?> manualFuelEfficiency,
      Value<double?> latestRecordedKmPerL,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });

final class $$CarProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $CarProfilesTable, CarProfile> {
  $$CarProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FuelingHistoriesTable, List<FuelingHistory>>
  _fuelingHistoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fuelingHistories,
    aliasName: $_aliasNameGenerator(
      db.carProfiles.id,
      db.fuelingHistories.carProfileId,
    ),
  );

  $$FuelingHistoriesTableProcessedTableManager get fuelingHistoriesRefs {
    final manager = $$FuelingHistoriesTableTableManager(
      $_db,
      $_db.fuelingHistories,
    ).filter((f) => f.carProfileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fuelingHistoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CarProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CarProfilesTable> {
  $$CarProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tankSizeL => $composableBuilder(
    column: $table.tankSizeL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgFuelEfficiency => $composableBuilder(
    column: $table.avgFuelEfficiency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get manualFuelEfficiency => $composableBuilder(
    column: $table.manualFuelEfficiency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latestRecordedKmPerL => $composableBuilder(
    column: $table.latestRecordedKmPerL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fuelingHistoriesRefs(
    Expression<bool> Function($$FuelingHistoriesTableFilterComposer f) f,
  ) {
    final $$FuelingHistoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelingHistories,
      getReferencedColumn: (t) => t.carProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelingHistoriesTableFilterComposer(
            $db: $db,
            $table: $db.fuelingHistories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CarProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CarProfilesTable> {
  $$CarProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tankSizeL => $composableBuilder(
    column: $table.tankSizeL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgFuelEfficiency => $composableBuilder(
    column: $table.avgFuelEfficiency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get manualFuelEfficiency => $composableBuilder(
    column: $table.manualFuelEfficiency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latestRecordedKmPerL => $composableBuilder(
    column: $table.latestRecordedKmPerL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CarProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CarProfilesTable> {
  $$CarProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<double> get tankSizeL =>
      $composableBuilder(column: $table.tankSizeL, builder: (column) => column);

  GeneratedColumn<double> get avgFuelEfficiency => $composableBuilder(
    column: $table.avgFuelEfficiency,
    builder: (column) => column,
  );

  GeneratedColumn<double> get manualFuelEfficiency => $composableBuilder(
    column: $table.manualFuelEfficiency,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latestRecordedKmPerL => $composableBuilder(
    column: $table.latestRecordedKmPerL,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> fuelingHistoriesRefs<T extends Object>(
    Expression<T> Function($$FuelingHistoriesTableAnnotationComposer a) f,
  ) {
    final $$FuelingHistoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelingHistories,
      getReferencedColumn: (t) => t.carProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelingHistoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelingHistories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CarProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CarProfilesTable,
          CarProfile,
          $$CarProfilesTableFilterComposer,
          $$CarProfilesTableOrderingComposer,
          $$CarProfilesTableAnnotationComposer,
          $$CarProfilesTableCreateCompanionBuilder,
          $$CarProfilesTableUpdateCompanionBuilder,
          (CarProfile, $$CarProfilesTableReferences),
          CarProfile,
          PrefetchHooks Function({bool fuelingHistoriesRefs})
        > {
  $$CarProfilesTableTableManager(_$AppDatabase db, $CarProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CarProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CarProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CarProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> fuelType = const Value.absent(),
                Value<double> tankSizeL = const Value.absent(),
                Value<double> avgFuelEfficiency = const Value.absent(),
                Value<double?> manualFuelEfficiency = const Value.absent(),
                Value<double?> latestRecordedKmPerL = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CarProfilesCompanion(
                id: id,
                modelName: modelName,
                brand: brand,
                fuelType: fuelType,
                tankSizeL: tankSizeL,
                avgFuelEfficiency: avgFuelEfficiency,
                manualFuelEfficiency: manualFuelEfficiency,
                latestRecordedKmPerL: latestRecordedKmPerL,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String modelName,
                Value<String> brand = const Value.absent(),
                required String fuelType,
                Value<double> tankSizeL = const Value.absent(),
                Value<double> avgFuelEfficiency = const Value.absent(),
                Value<double?> manualFuelEfficiency = const Value.absent(),
                Value<double?> latestRecordedKmPerL = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CarProfilesCompanion.insert(
                id: id,
                modelName: modelName,
                brand: brand,
                fuelType: fuelType,
                tankSizeL: tankSizeL,
                avgFuelEfficiency: avgFuelEfficiency,
                manualFuelEfficiency: manualFuelEfficiency,
                latestRecordedKmPerL: latestRecordedKmPerL,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CarProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fuelingHistoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (fuelingHistoriesRefs) db.fuelingHistories,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fuelingHistoriesRefs)
                    await $_getPrefetchedData<
                      CarProfile,
                      $CarProfilesTable,
                      FuelingHistory
                    >(
                      currentTable: table,
                      referencedTable: $$CarProfilesTableReferences
                          ._fuelingHistoriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CarProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).fuelingHistoriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.carProfileId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CarProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CarProfilesTable,
      CarProfile,
      $$CarProfilesTableFilterComposer,
      $$CarProfilesTableOrderingComposer,
      $$CarProfilesTableAnnotationComposer,
      $$CarProfilesTableCreateCompanionBuilder,
      $$CarProfilesTableUpdateCompanionBuilder,
      (CarProfile, $$CarProfilesTableReferences),
      CarProfile,
      PrefetchHooks Function({bool fuelingHistoriesRefs})
    >;
typedef $$FuelingHistoriesTableCreateCompanionBuilder =
    FuelingHistoriesCompanion Function({
      Value<int> id,
      required int carProfileId,
      required DateTime fueledAt,
      required double odometerKm,
      required double liters,
      required double totalAmountWon,
      required String stationName,
      Value<String> stationUniId,
    });
typedef $$FuelingHistoriesTableUpdateCompanionBuilder =
    FuelingHistoriesCompanion Function({
      Value<int> id,
      Value<int> carProfileId,
      Value<DateTime> fueledAt,
      Value<double> odometerKm,
      Value<double> liters,
      Value<double> totalAmountWon,
      Value<String> stationName,
      Value<String> stationUniId,
    });

final class $$FuelingHistoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $FuelingHistoriesTable, FuelingHistory> {
  $$FuelingHistoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CarProfilesTable _carProfileIdTable(_$AppDatabase db) =>
      db.carProfiles.createAlias(
        $_aliasNameGenerator(
          db.fuelingHistories.carProfileId,
          db.carProfiles.id,
        ),
      );

  $$CarProfilesTableProcessedTableManager get carProfileId {
    final $_column = $_itemColumn<int>('car_profile_id')!;

    final manager = $$CarProfilesTableTableManager(
      $_db,
      $_db.carProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_carProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FuelingHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $FuelingHistoriesTable> {
  $$FuelingHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fueledAt => $composableBuilder(
    column: $table.fueledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get odometerKm => $composableBuilder(
    column: $table.odometerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmountWon => $composableBuilder(
    column: $table.totalAmountWon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationUniId => $composableBuilder(
    column: $table.stationUniId,
    builder: (column) => ColumnFilters(column),
  );

  $$CarProfilesTableFilterComposer get carProfileId {
    final $$CarProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.carProfileId,
      referencedTable: $db.carProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarProfilesTableFilterComposer(
            $db: $db,
            $table: $db.carProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelingHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelingHistoriesTable> {
  $$FuelingHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fueledAt => $composableBuilder(
    column: $table.fueledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get odometerKm => $composableBuilder(
    column: $table.odometerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmountWon => $composableBuilder(
    column: $table.totalAmountWon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationUniId => $composableBuilder(
    column: $table.stationUniId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CarProfilesTableOrderingComposer get carProfileId {
    final $$CarProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.carProfileId,
      referencedTable: $db.carProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.carProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelingHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelingHistoriesTable> {
  $$FuelingHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fueledAt =>
      $composableBuilder(column: $table.fueledAt, builder: (column) => column);

  GeneratedColumn<double> get odometerKm => $composableBuilder(
    column: $table.odometerKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get liters =>
      $composableBuilder(column: $table.liters, builder: (column) => column);

  GeneratedColumn<double> get totalAmountWon => $composableBuilder(
    column: $table.totalAmountWon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stationUniId => $composableBuilder(
    column: $table.stationUniId,
    builder: (column) => column,
  );

  $$CarProfilesTableAnnotationComposer get carProfileId {
    final $$CarProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.carProfileId,
      referencedTable: $db.carProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.carProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelingHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelingHistoriesTable,
          FuelingHistory,
          $$FuelingHistoriesTableFilterComposer,
          $$FuelingHistoriesTableOrderingComposer,
          $$FuelingHistoriesTableAnnotationComposer,
          $$FuelingHistoriesTableCreateCompanionBuilder,
          $$FuelingHistoriesTableUpdateCompanionBuilder,
          (FuelingHistory, $$FuelingHistoriesTableReferences),
          FuelingHistory,
          PrefetchHooks Function({bool carProfileId})
        > {
  $$FuelingHistoriesTableTableManager(
    _$AppDatabase db,
    $FuelingHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelingHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelingHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelingHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> carProfileId = const Value.absent(),
                Value<DateTime> fueledAt = const Value.absent(),
                Value<double> odometerKm = const Value.absent(),
                Value<double> liters = const Value.absent(),
                Value<double> totalAmountWon = const Value.absent(),
                Value<String> stationName = const Value.absent(),
                Value<String> stationUniId = const Value.absent(),
              }) => FuelingHistoriesCompanion(
                id: id,
                carProfileId: carProfileId,
                fueledAt: fueledAt,
                odometerKm: odometerKm,
                liters: liters,
                totalAmountWon: totalAmountWon,
                stationName: stationName,
                stationUniId: stationUniId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int carProfileId,
                required DateTime fueledAt,
                required double odometerKm,
                required double liters,
                required double totalAmountWon,
                required String stationName,
                Value<String> stationUniId = const Value.absent(),
              }) => FuelingHistoriesCompanion.insert(
                id: id,
                carProfileId: carProfileId,
                fueledAt: fueledAt,
                odometerKm: odometerKm,
                liters: liters,
                totalAmountWon: totalAmountWon,
                stationName: stationName,
                stationUniId: stationUniId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FuelingHistoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({carProfileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (carProfileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.carProfileId,
                                referencedTable:
                                    $$FuelingHistoriesTableReferences
                                        ._carProfileIdTable(db),
                                referencedColumn:
                                    $$FuelingHistoriesTableReferences
                                        ._carProfileIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FuelingHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelingHistoriesTable,
      FuelingHistory,
      $$FuelingHistoriesTableFilterComposer,
      $$FuelingHistoriesTableOrderingComposer,
      $$FuelingHistoriesTableAnnotationComposer,
      $$FuelingHistoriesTableCreateCompanionBuilder,
      $$FuelingHistoriesTableUpdateCompanionBuilder,
      (FuelingHistory, $$FuelingHistoriesTableReferences),
      FuelingHistory,
      PrefetchHooks Function({bool carProfileId})
    >;
typedef $$StationCacheTableCreateCompanionBuilder =
    StationCacheCompanion Function({
      required String uniId,
      required String brandCode,
      required String name,
      required int price,
      required double distanceM,
      required double gisX,
      required double gisY,
      required String productCode,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$StationCacheTableUpdateCompanionBuilder =
    StationCacheCompanion Function({
      Value<String> uniId,
      Value<String> brandCode,
      Value<String> name,
      Value<int> price,
      Value<double> distanceM,
      Value<double> gisX,
      Value<double> gisY,
      Value<String> productCode,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$StationCacheTableFilterComposer
    extends Composer<_$AppDatabase, $StationCacheTable> {
  $$StationCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uniId => $composableBuilder(
    column: $table.uniId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandCode => $composableBuilder(
    column: $table.brandCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gisX => $composableBuilder(
    column: $table.gisX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gisY => $composableBuilder(
    column: $table.gisY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StationCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $StationCacheTable> {
  $$StationCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uniId => $composableBuilder(
    column: $table.uniId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandCode => $composableBuilder(
    column: $table.brandCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gisX => $composableBuilder(
    column: $table.gisX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gisY => $composableBuilder(
    column: $table.gisY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StationCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $StationCacheTable> {
  $$StationCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uniId =>
      $composableBuilder(column: $table.uniId, builder: (column) => column);

  GeneratedColumn<String> get brandCode =>
      $composableBuilder(column: $table.brandCode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get gisX =>
      $composableBuilder(column: $table.gisX, builder: (column) => column);

  GeneratedColumn<double> get gisY =>
      $composableBuilder(column: $table.gisY, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$StationCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StationCacheTable,
          StationCacheData,
          $$StationCacheTableFilterComposer,
          $$StationCacheTableOrderingComposer,
          $$StationCacheTableAnnotationComposer,
          $$StationCacheTableCreateCompanionBuilder,
          $$StationCacheTableUpdateCompanionBuilder,
          (
            StationCacheData,
            BaseReferences<_$AppDatabase, $StationCacheTable, StationCacheData>,
          ),
          StationCacheData,
          PrefetchHooks Function()
        > {
  $$StationCacheTableTableManager(_$AppDatabase db, $StationCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uniId = const Value.absent(),
                Value<String> brandCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<double> gisX = const Value.absent(),
                Value<double> gisY = const Value.absent(),
                Value<String> productCode = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StationCacheCompanion(
                uniId: uniId,
                brandCode: brandCode,
                name: name,
                price: price,
                distanceM: distanceM,
                gisX: gisX,
                gisY: gisY,
                productCode: productCode,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uniId,
                required String brandCode,
                required String name,
                required int price,
                required double distanceM,
                required double gisX,
                required double gisY,
                required String productCode,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => StationCacheCompanion.insert(
                uniId: uniId,
                brandCode: brandCode,
                name: name,
                price: price,
                distanceM: distanceM,
                gisX: gisX,
                gisY: gisY,
                productCode: productCode,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StationCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StationCacheTable,
      StationCacheData,
      $$StationCacheTableFilterComposer,
      $$StationCacheTableOrderingComposer,
      $$StationCacheTableAnnotationComposer,
      $$StationCacheTableCreateCompanionBuilder,
      $$StationCacheTableUpdateCompanionBuilder,
      (
        StationCacheData,
        BaseReferences<_$AppDatabase, $StationCacheTable, StationCacheData>,
      ),
      StationCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CarProfilesTableTableManager get carProfiles =>
      $$CarProfilesTableTableManager(_db, _db.carProfiles);
  $$FuelingHistoriesTableTableManager get fuelingHistories =>
      $$FuelingHistoriesTableTableManager(_db, _db.fuelingHistories);
  $$StationCacheTableTableManager get stationCache =>
      $$StationCacheTableTableManager(_db, _db.stationCache);
}
