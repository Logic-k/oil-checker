/// Opinet API 주유소 모델
///
/// 실제 응답 형식 (2026-08-02 실측):
/// UNI_ID, POLL_DIV_CD(정유사코드), OS_NM(상호), PRICE(가격),
/// DISTANCE(거리 m), GIS_X_COOR, GIS_Y_COOR (KATEC 좌표)
class OpinetStation {
  const OpinetStation({
    required this.uniId,
    required this.brandCode,
    required this.name,
    required this.price,
    required this.distanceM,
    required this.gisX,
    required this.gisY,
  });

  /// 주유소 고유 ID
  final String uniId;

  /// 정유사 코드 (HDO, GSC, SKE, SOL 등)
  final String brandCode;

  /// 상호명
  final String name;

  /// 가격 (원)
  final int price;

  /// 현재 위치로부터 거리 (미터)
  final double distanceM;

  /// KATEC X 좌표
  final double gisX;

  /// KATEC Y 좌표
  final double gisY;

  factory OpinetStation.fromJson(Map<String, dynamic> json) {
    return OpinetStation(
      uniId: json['UNI_ID'] as String? ?? '',
      brandCode: json['POLL_DIV_CD'] as String? ?? '',
      name: json['OS_NM'] as String? ?? '',
      price: _toInt(json['PRICE']),
      distanceM: _toDouble(json['DISTANCE']),
      gisX: _toDouble(json['GIS_X_COOR']),
      gisY: _toDouble(json['GIS_Y_COOR']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

/// 주유소 상세 정보 (detailById.do 응답)
///
/// 실제 응답 형식 (2026-08-02 실측):
/// UNI_ID, POLL_DIV_CO, OS_NM, VAN_ADR(지번주소), NEW_ADR(도로명주소),
/// TEL(전화), LPG_YN, MAINT_YN(경정비), CAR_WASH_YN(세차), KPETRO_YN,
/// CVS_YN(편의점), GIS_X_COOR, GIS_Y_COOR, OIL_PRICE[{PRODCD, PRICE, ...}]
///
/// 주의: Opinet은 **영업시간(OPEN/CLOSE)을 제공하지 않는다.**
class OpinetStationDetail {
  const OpinetStationDetail({
    required this.uniId,
    required this.brandCode,
    required this.name,
    required this.vanAddress,
    required this.newAddress,
    required this.tel,
    required this.hasMaintenance,
    required this.hasCarWash,
    required this.hasConvenienceStore,
    required this.isQualityCertified,
    required this.gisX,
    required this.gisY,
    required this.prices,
  });

  /// 주유소 고유 ID
  final String uniId;

  /// 정유사 코드 (HDO, GSC, SKE, SOL...)
  final String brandCode;

  /// 상호명
  final String name;

  /// 지번주소 (VAN_ADR)
  final String vanAddress;

  /// 도로명주소 (NEW_ADR)
  final String newAddress;

  /// 전화번호 (TEL)
  final String tel;

  /// 경정비 시설 존재 여부 (MAINT_YN)
  final bool hasMaintenance;

  /// 세차장 존재 여부 (CAR_WASH_YN)
  final bool hasCarWash;

  /// 편의점 존재 여부 (CVS_YN)
  final bool hasConvenienceStore;

  /// 품질인증주유소 여부 (KPETRO_YN)
  final bool isQualityCertified;

  /// KATEC X 좌표
  final double gisX;

  /// KATEC Y 좌표
  final double gisY;

  /// 유종별 가격 (PRODCD → PRICE)
  final Map<String, int> prices;

  /// 표시용 주소 — 도로명 우선, 없으면 지번
  String get displayAddress => newAddress.isNotEmpty ? newAddress : vanAddress;

  bool get hasPhone => tel.isNotEmpty;

  factory OpinetStationDetail.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['OIL_PRICE'];
    final prices = <String, int>{};
    if (rawPrices is List) {
      for (final e in rawPrices) {
        if (e is! Map<String, dynamic>) continue;
        final prodcd = e['PRODCD'] as String? ?? '';
        if (prodcd.isEmpty) continue;
        prices[prodcd] = OpinetStation._toInt(e['PRICE']);
      }
    }
    return OpinetStationDetail(
      uniId: json['UNI_ID'] as String? ?? '',
      brandCode: (json['POLL_DIV_CD'] as String? ?? '')
          .trim()
          .isNotEmpty
          ? (json['POLL_DIV_CD'] as String).trim()
          : (json['POLL_DIV_CO'] as String? ?? '').trim(),
      name: json['OS_NM'] as String? ?? '',
      vanAddress: (json['VAN_ADR'] as String? ?? '').trim(),
      newAddress: (json['NEW_ADR'] as String? ?? '').trim(),
      tel: (json['TEL'] as String? ?? '').trim(),
      hasMaintenance: _toBool(json['MAINT_YN']),
      hasCarWash: _toBool(json['CAR_WASH_YN']),
      hasConvenienceStore: _toBool(json['CVS_YN']),
      isQualityCertified: _toBool(json['KPETRO_YN']),
      gisX: OpinetStation._toDouble(json['GIS_X_COOR']),
      gisY: OpinetStation._toDouble(json['GIS_Y_COOR']),
      prices: prices,
    );
  }

  static bool _toBool(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      final v = value.trim().toUpperCase();
      return v == 'Y' || v == 'TRUE' || v == '1';
    }
    if (value is num) return value != 0;
    return false;
  }
}
