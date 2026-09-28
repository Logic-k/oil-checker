import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/opinet/fuel_products.dart';

void main() {
  test('실내등유 등 비자동차 제품은 빼고 고정 순서로 정렬한다', () {
    final prices = {
      'D047': 1819,
      'C004': 1890, // 실내등유
      'B027': 1840,
      'K015': 0, // 미판매
      'B034': 2100,
    };
    expect(carFuelPrices(prices), [
      ('B027', 1840),
      ('B034', 2100),
      ('D047', 1819),
    ]);
  });

  test('자동차 연료가 하나도 없으면 빈 목록', () {
    expect(carFuelPrices({'C004': 1890}), isEmpty);
  });
}
