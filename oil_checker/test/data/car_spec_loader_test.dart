import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/data/car_spec/car_spec_loader.dart';

/// 실제 CSV 데이터에서 추출한 샘플 행 (assets/data/car_fuel_economy.csv)
const String kSampleCsv = '''
모델명,제조(수입사),차종,유형,복합_연비,1회충전주행거리,도심_연비,고속도로_연비,등급
한국상용1톤롱바디EV트럭,현대,화물차,일반형,2.7,177,3.2,2.3,5등급
피아트 500C,크라이슬러,승용차,일반형,12,,10.7,14,3등급
피아트 500C,크라이슬러,승용차,일반형,12.4,,11.3,14,3등급
그랜저,현대,승용차,일반형,12.1,900,10.5,15.1,3등급
쏘나타,현대,승용차,하이브리드,19.2,1200,18.5,20.1,1등급
''';

void main() {
  group('CarSpecLoader.parseCsv', () {
    test('CSV를 파싱해 CarSpecEntry 목록을 만든다', () {
      final entries = CarSpecLoader.parseCsv(kSampleCsv);

      expect(entries, hasLength(5));
      expect(entries[0].modelName, '한국상용1톤롱바디EV트럭');
      expect(entries[0].manufacturer, '현대');
      expect(entries[0].vehicleType, '화물차');
      expect(entries[0].fuelType, '일반형');
      expect(entries[0].combinedKmPerL, closeTo(2.7, 0.001));
      expect(entries[0].oneChargeRangeKm, 177);
      expect(entries[0].grade, '5등급');
    });

    test('빈 값(1회충전주행거리)은 0으로 처리한다', () {
      final entries = CarSpecLoader.parseCsv(kSampleCsv);

      expect(entries[1].modelName, '피아트 500C');
      expect(entries[1].oneChargeRangeKm, 0);
    });

    test('도심/고속도로 연비도 파싱한다', () {
      final entries = CarSpecLoader.parseCsv(kSampleCsv);

      expect(entries[1].cityKmPerL, closeTo(10.7, 0.001));
      expect(entries[1].highwayKmPerL, closeTo(14, 0.001));
    });
  });

  group('CarSpecLoader.search', () {
    test('모델명 부분일치로 검색한다', () {
      final loader = CarSpecLoader.fromCsv(kSampleCsv);

      final results = loader.search('그랜저');
      expect(results, hasLength(1));
      expect(results.first.modelName, '그랜저');
    });

    test('대소문자 무시 검색', () {
      final loader = CarSpecLoader.fromCsv(kSampleCsv);

      // 모델명 '피아트 500C'의 'C' → 소문자 'c'로 검색해도 매치
      final results = loader.search('500c');
      expect(results, hasLength(2)); // 피아트 500C 2행
    });

    test('검색 결과가 없으면 빈 리스트', () {
      final loader = CarSpecLoader.fromCsv(kSampleCsv);

      expect(loader.search('존재하지않는차'), isEmpty);
    });
  });

  group('CarSpecLoader 평균 연비', () {
    test('동일 모델 복수 행이면 복합연비 평균을 구한다', () {
      final loader = CarSpecLoader.fromCsv(kSampleCsv);

      // 피아트 500C: 12, 12.4 → 평균 12.2
      final avg = loader.averageCombinedKmPerL('피아트 500C');
      expect(avg, closeTo(12.2, 0.001));
    });
  });
}
