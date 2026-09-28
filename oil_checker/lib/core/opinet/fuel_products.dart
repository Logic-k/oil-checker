import 'package:oil_checker/core/opinet/opinet_client.dart';

/// 자동차 연료만 고정 순서로 — 휘발유, 고급휘발유, 경유, LPG.
///
/// 주유소 상세(detailById)는 실내등유(C004) 같은 비자동차 제품 가격도 준다.
/// 차량 운전자에게는 혼란만 주므로 화면에서는 이 목록만 보여준다.
const List<String> kCarFuelProductOrder = [
  OpinetClient.productGasoline,
  OpinetClient.productPremium,
  OpinetClient.productDiesel,
  OpinetClient.productLpg,
];

/// 제품 코드별 가격 → 자동차 연료만 [kCarFuelProductOrder] 순서로 (0원 이하 제외)
List<(String code, int price)> carFuelPrices(Map<String, int> prices) => [
      for (final code in kCarFuelProductOrder)
        if (prices[code] case final price? when price > 0) (code, price),
    ];
