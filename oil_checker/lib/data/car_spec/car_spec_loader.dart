import 'package:csv/csv.dart';

/// 차종 연비 정보 (한국에너지공단 자동차 표시연비 CSV 기준)
class CarSpecEntry {
  const CarSpecEntry({
    required this.modelName,
    required this.manufacturer,
    required this.vehicleType,
    required this.fuelType,
    required this.combinedKmPerL,
    required this.oneChargeRangeKm,
    required this.cityKmPerL,
    required this.highwayKmPerL,
    required this.grade,
  });

  /// 모델명
  final String modelName;

  /// 제조(수입사)
  final String manufacturer;

  /// 차종 (승용차, 화물차 등)
  final String vehicleType;

  /// 유형 (일반형, 하이브리드 등)
  final String fuelType;

  /// 복합 연비 (km/L)
  final double combinedKmPerL;

  /// 1회충전 주행거리 (km, EV) — 없으면 0
  final int oneChargeRangeKm;

  /// 도심 연비 (km/L)
  final double cityKmPerL;

  /// 고속도로 연비 (km/L)
  final double highwayKmPerL;

  /// 등급
  final String grade;

  factory CarSpecEntry.fromRow(List<dynamic> row) {
    String at(int i) => (i < row.length ? row[i]?.toString() : '') ?? '';
    double dbl(int i) => double.tryParse(at(i).trim()) ?? 0;
    int intg(int i) => int.tryParse(at(i).trim()) ?? 0;

    return CarSpecEntry(
      modelName: at(0).trim(),
      manufacturer: at(1).trim(),
      vehicleType: at(2).trim(),
      fuelType: at(3).trim(),
      combinedKmPerL: dbl(4),
      oneChargeRangeKm: intg(5),
      cityKmPerL: dbl(6),
      highwayKmPerL: dbl(7),
      grade: at(8).trim(),
    );
  }
}

/// 연료탱크 용량 규칙 — fuel_tank_capacity.csv의 한 행.
/// [parts]는 AND 조건: 정규화된 모델명이 모든 부분을 포함해야 매칭.
class _TankRule {
  const _TankRule(this.parts, this.liters);

  final List<String> parts;
  final double liters;

  /// 매칭 우선순위 — 부분어 총 길이가 긴 규칙이 더 구체적.
  int get specificity =>
      parts.fold(0, (sum, p) => sum + p.length);
}

/// 차종·연비 CSV 로더
///
/// 한국에너지공단_자동차 표시연비 정보 (data.go.kr /15083023/fileData.do) 파일을
/// 앱에 임베드해 파싱한다. API 호출이 아니므로 Opinet 일일 한도와 무관.
class CarSpecLoader {
  CarSpecLoader._(this._entries, this._tankRules);

  final List<CarSpecEntry> _entries;
  final List<_TankRule> _tankRules;

  /// CSV 문자열을 파싱해 로더 생성. [tankCsv]는 선택 —
  /// 모델명 패턴→연료탱크 용량 매핑(fuel_tank_capacity.csv 형식).
  factory CarSpecLoader.fromCsv(String csv, {String? tankCsv}) {
    return CarSpecLoader._(
      CarSpecLoader.parseCsv(csv),
      tankCsv == null ? const [] : _parseTankCsv(tankCsv),
    );
  }

  /// 모델명 정규화 — 소문자화 + 공백·괄호·기호 제거
  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');

  /// 연료탱크 용량 CSV 파싱 (pattern,liters)
  static List<_TankRule> _parseTankCsv(String csv) {
    final rules = <_TankRule>[];
    for (final line in csv.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final comma = t.lastIndexOf(',');
      if (comma < 0) continue;
      final pattern = t.substring(0, comma).trim();
      final liters = double.tryParse(t.substring(comma + 1).trim());
      if (liters == null || pattern.isEmpty || pattern == 'pattern') {
        continue;
      }
      rules.add(_TankRule(
        pattern.split('+').map(_norm).where((p) => p.isNotEmpty).toList(),
        liters,
      ));
    }
    rules.sort((a, b) => b.specificity.compareTo(a.specificity));
    return rules;
  }

  /// 모델명 → 공칭 연료탱크 용량(L).
  /// 반환값: 용량 / 0이면 전기·수소차(주유 대상 아님) / null이면 모름.
  double? tankCapacityL(String modelName) {
    final norm = _norm(modelName);
    for (final rule in _tankRules) {
      if (rule.parts.every(norm.contains)) return rule.liters;
    }
    return null;
  }

  /// 주유 대상이 아닌 전기·수소 차종 여부
  bool isElectric(String modelName) => tankCapacityL(modelName) == 0;

  /// CSV 문자열을 파싱해 [CarSpecEntry] 목록 반환
  static List<CarSpecEntry> parseCsv(String csv) {
    final rows = const CsvDecoder().convert(csv);

    if (rows.isEmpty) return const [];

    // 첫 행은 헤더
    final dataRows = rows.skip(1).where((row) {
      final first = row.isNotEmpty ? row.first.toString().trim() : '';
      return first.isNotEmpty;
    });

    return dataRows.map(CarSpecEntry.fromRow).toList();
  }

  /// 모델명 부분일치 검색 (대소문자 무시)
  List<CarSpecEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _entries
        .where((e) => e.modelName.toLowerCase().contains(q))
        .toList();
  }

  /// 모델명과 정확히 일치하는 모든 행의 복합연비 평균 (km/L)
  double averageCombinedKmPerL(String modelName) {
    final matched = _entries
        .where((e) => e.modelName == modelName)
        .where((e) => e.combinedKmPerL > 0)
        .toList();
    if (matched.isEmpty) return 0;
    return matched.fold<double>(0, (sum, e) => sum + e.combinedKmPerL) /
        matched.length;
  }

  /// 전체 차종 수
  int get length => _entries.length;
}
