import 'package:oil_checker/core/opinet/opinet_client.dart';

/// 차종 모델명 → Opinet 제품 코드(휘발유 B027 / 경유 D047 / LPG K015) 추론.
///
/// 공단 연비 CSV에는 연료 종류 열이 없다. '유형' 열(`CarSpecEntry.fuelType`)은
/// 일반형·다목적형·화물 같은 차체 구분이라, 예전처럼 그 열에서 '경유'·'LPG'를
/// 찾으면 모든 차량이 휘발유로 저장된다. 그래서 모델명에 적힌 엔진 표기로
/// 추론하고, 확신이 없으면 휘발유로 둔다(사용자가 STEP 2·설정에서 바꿀 수 있다).
///
/// 규칙 (공단 CSV 3,522개 모델명으로 점검 — 경유 769 / LPG 108 / 전기·수소 159):
/// - 전기·수소차: 주유 대상이 아니므로 휘발유 기본값 유지
/// - LPG: LPI · LPG · LPe · 엘피지 (앞뒤가 영문자가 아닐 때만 — 'Alpine' 오탐 방지)
/// - 경유: 디젤 · DIESEL · CRDi · VGT · TDI · BlueHDi · BlueTEC · dCi · CDI ·
///   e-XDi · 멀티젯 · EcoBlue · i-DTEC, 벤츠·BMW식 '320d'·'E 220 d'·'xDrive30d',
///   랜드로버 'D250'·'SD4'·'TDV6', 볼보 'D4', 현대·기아 R엔진 'R2.2'
///
/// [typeColumn]은 하위 호환용 — 값에 '경유'/'LPG'가 직접 있으면 그대로 따른다.
String inferFuelProductCode(String modelName, {String typeColumn = ''}) {
  if (typeColumn.contains('경유')) return OpinetClient.productDiesel;
  if (typeColumn.contains('LPG')) return OpinetClient.productLpg;

  if (_electricPattern.hasMatch(modelName)) return OpinetClient.productGasoline;
  if (_lpgPattern.hasMatch(modelName)) return OpinetClient.productLpg;
  if (_dieselPatterns.any((p) => p.hasMatch(modelName))) {
    return OpinetClient.productDiesel;
  }
  return OpinetClient.productGasoline;
}

final RegExp _electricPattern = RegExp(
  r'(?<![a-z])ev(?![a-z])|전기|electric|일렉트릭|수소|넥쏘|fcev|e-tron|taycan|'
  r'tesla|테슬라|model\s?[3sxy](?![a-z0-9])',
  caseSensitive: false,
);

final RegExp _lpgPattern =
    RegExp(r'(?<![a-z])lp[ige](?![a-z])|엘피지', caseSensitive: false);

final List<RegExp> _dieselPatterns = [
  RegExp(
    r'디젤|diesel|멀티젯|multijet|ecoblue|skyactiv-?d|d-4d|i-?dtec',
    caseSensitive: false,
  ),
  RegExp(
    r'(?<![a-z])(?:crdi|tdci|tdi|bluehdi|hdi|bluetec|dci|cdi|jtd|vgt)(?![a-z])'
    r'|e-?vgt|e-?xdi',
    caseSensitive: false,
  ),
  // 벤츠·BMW: 320d / E 220 d / S350 d / 20d
  RegExp(r'(?<![0-9.])\d{2,3}\s?d(?![a-z])', caseSensitive: false),
  // BMW: xDrive30d / sDrive20d
  RegExp(r'[xs]drive\d{2}d(?![a-z])', caseSensitive: false),
  // 랜드로버 D250 / D350
  RegExp(r'(?<![a-z0-9])d\d{3}(?![0-9])', caseSensitive: false),
  // 랜드로버 SD4 / TD4 / SDV6 / TDV6
  RegExp(r'(?<![a-z0-9])(?:s|t)dv?[4-8](?![0-9a-z])', caseSensitive: false),
  // 볼보 D4 / D5
  RegExp(r'(?<![a-z0-9])d[345](?![0-9a-z])', caseSensitive: false),
  // 현대·기아 R엔진(디젤 전용): R2.0 / R2.2
  RegExp(r'(?<![a-z])r\s?2\.[02](?![0-9])', caseSensitive: false),
];
