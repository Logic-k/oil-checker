import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/traffic/congestion.dart';

void main() {
  const model = CongestionModel();

  group('CongestionModel.levelAt', () {
    test('주중 출근 시간(07-09시)은 혼잡', () {
      // 2026-08-03은 월요일
      final time = DateTime(2026, 8, 3, 8);
      expect(model.levelAt(time), CongestionLevel.heavy);
    });

    test('주중 퇴근 시간(18-20시)은 혼잡', () {
      final time = DateTime(2026, 8, 3, 19);
      expect(model.levelAt(time), CongestionLevel.heavy);
    });

    test('주중 주간(09-18시)은 보통', () {
      final time = DateTime(2026, 8, 3, 12);
      expect(model.levelAt(time), CongestionLevel.moderate);
    });

    test('주중 심야(20-07시)는 원활', () {
      final time = DateTime(2026, 8, 3, 23);
      expect(model.levelAt(time), CongestionLevel.smooth);
    });

    test('주말은 원활 (출퇴근 혼잡 없음)', () {
      // 2026-08-02은 일요일
      final saturday = DateTime(2026, 8, 1, 8); // 토요일 출근시간대
      final sunday = DateTime(2026, 8, 2, 8); // 일요일 출근시간대
      expect(model.levelAt(saturday), CongestionLevel.smooth);
      expect(model.levelAt(sunday), CongestionLevel.smooth);
    });
  });

  group('CongestionModel.factorAt', () {
    test('혼잡 시간대는 1.5배', () {
      final time = DateTime(2026, 8, 3, 8);
      expect(model.factorAt(time), 1.5);
    });

    test('주간은 1.2배', () {
      final time = DateTime(2026, 8, 3, 12);
      expect(model.factorAt(time), 1.2);
    });

    test('주말·심야는 1.0배', () {
      expect(model.factorAt(DateTime(2026, 8, 3, 23)), 1.0);
      expect(model.factorAt(DateTime(2026, 8, 2, 8)), 1.0);
    });
  });

  test('혼잡 단계 라벨', () {
    expect(CongestionModel.labelOf(CongestionLevel.smooth), '원활');
    expect(CongestionModel.labelOf(CongestionLevel.moderate), '보통');
    expect(CongestionModel.labelOf(CongestionLevel.heavy), '혼잡');
  });
}
