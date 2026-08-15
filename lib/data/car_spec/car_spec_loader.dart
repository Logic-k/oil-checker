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

/// 차종·연비 CSV 로더
///
/// 한국에너지공단_자동차 표시연비 정보 (data.go.kr /15083023/fileData.do) 파일을
/// 앱에 임베드해 파싱한다. API 호출이 아니므로 Opinet 일일 한도와 무관.
class CarSpecLoader {
  CarSpecLoader._(this._entries);

  final List<CarSpecEntry> _entries;

  /// CSV 문자열을 파싱해 로더 생성
  factory CarSpecLoader.fromCsv(String csv) {
    return CarSpecLoader._(CarSpecLoader.parseCsv(csv));
  }

  /// CSV 문자열을 파싱해 [CarSpecEntry] 목록 반환
  static List<CarSpecEntry> parseCsv(String csv) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csv);

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
