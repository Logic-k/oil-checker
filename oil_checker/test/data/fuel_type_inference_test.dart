import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/data/car_spec/fuel_type_inference.dart';

/// 모델명 → Opinet 제품 코드 추론 (공단 CSV 실제 모델명 표본)
void main() {
  const gasoline = 'B027';
  const diesel = 'D047';
  const lpg = 'K015';

  group('inferFuelProductCode', () {
    test('LPG 표기(LPI/LPG/LPe)는 LPG', () {
      expect(inferFuelProductCode('K5(JF) 2.0LPI 6MT(15)'), lpg);
      expect(inferFuelProductCode('K7 3.0 LPI (PE/17"타이어)'), lpg);
      expect(inferFuelProductCode('아반떼(PE) 1.6LPI 17인치 타이어'), lpg);
      expect(inferFuelProductCode('스파크 LPe'), lpg);
    });

    test('국산 디젤 표기는 경유', () {
      expect(inferFuelProductCode('포터2.5디젤 덤프4X4장축 슈퍼캡(MT)(22)'), diesel);
      expect(inferFuelProductCode('QM6 New 2.0 DIESEL (4WD 19" Tire)'), diesel);
      expect(inferFuelProductCode('싼타페 R2.2'), diesel);
      expect(inferFuelProductCode('투싼 2.0 e-VGT'), diesel);
      expect(inferFuelProductCode('코란도 e-XDi220'), diesel);
    });

    test('수입 디젤 표기(TDI·d·Dnnn·BlueHDi)는 경유', () {
      expect(inferFuelProductCode('A4 40 TDI quattro'), diesel);
      expect(inferFuelProductCode('Tiguan 2.0TDI 4Motion'), diesel);
      expect(inferFuelProductCode('BMW 320d'), diesel);
      expect(inferFuelProductCode('BMW X5 xDrive30d'), diesel);
      expect(inferFuelProductCode('벤츠 E 220 d'), diesel);
      expect(inferFuelProductCode('Mercedes-Benz S350 d'), diesel);
      expect(inferFuelProductCode('더 뉴 레인지로버 D350 LWB'), diesel);
      expect(inferFuelProductCode('DS7 Crossback 1.5 BlueHDi'), diesel);
    });

    test('가솔린·하이브리드는 휘발유', () {
      expect(inferFuelProductCode('그랜저(GN7) 2.5 GDi'), gasoline);
      expect(inferFuelProductCode('쏘나타(DN8) 2.0 가솔린'), gasoline);
      expect(inferFuelProductCode('BMW 320i'), gasoline);
      expect(inferFuelProductCode('A4 40 TFSI'), gasoline);
      expect(inferFuelProductCode('쏘렌토 1.6 T-GDi 하이브리드 2WD'), gasoline);
      expect(inferFuelProductCode('벨로스터 N 2.0T-GDI (STD)'), gasoline);
    });

    test('영문자 사이의 lpi·ev는 오탐하지 않는다', () {
      expect(inferFuelProductCode('Alpine A110'), gasoline); // a-LPI-ne
      expect(inferFuelProductCode('Chevrolet Trax'), gasoline); // ch-EV-rolet
    });

    test('전기·수소차는 주유 대상이 아니므로 휘발유 기본값', () {
      expect(inferFuelProductCode('아이오닉5 롱레인지 EV'), gasoline);
      expect(inferFuelProductCode('넥쏘 17인치 24MY'), gasoline);
      expect(inferFuelProductCode('Tesla Model S 90D'), gasoline); // 90D ≠ 디젤
    });

    test("'유형' 열에 연료가 직접 있으면 그대로 따른다 (하위 호환)", () {
      expect(inferFuelProductCode('아무 모델', typeColumn: '경유'), diesel);
      expect(inferFuelProductCode('아무 모델', typeColumn: 'LPG'), lpg);
      expect(inferFuelProductCode('아무 모델', typeColumn: '일반형'), gasoline);
    });
  });
}
