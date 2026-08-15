import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/format/distance_format.dart';

void main() {
  group('formatDistance', () {
    test('1000m 미만은 미터 단위로 표시한다', () {
      expect(formatDistance(0), '0m');
      expect(formatDistance(840), '840m');
      expect(formatDistance(999), '999m');
    });

    test('1000m 이상은 km 단위로 표시한다', () {
      expect(formatDistance(1000), '1.0km');
      expect(formatDistance(1234), '1.2km');
      expect(formatDistance(4149.3), '4.1km');
      expect(formatDistance(10000), '10.0km');
    });
  });
}
