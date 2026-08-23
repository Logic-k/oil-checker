import 'package:flutter_test/flutter_test.dart';
import 'package:oil_checker/core/coordinate/katec.dart';

void main() {
  group('KATEC 변환 (WGS84 ↔ KATEC)', () {
    // 서울 시청 (WGS84)
    const seoulWgs = (lat: 37.5665, lng: 126.9780);
    // 충주 (문서 예제 좌표 근처) - 대략적 WGS84
    const chungjuWgs = (lat: 36.9707, lng: 127.9323);

    test('WGS84 → KATEC 왕복 변환이 오차 0.001° 이내로 복원된다 (서울)', () {
      final katec = wgs84ToKatec(
        latitude: seoulWgs.lat,
        longitude: seoulWgs.lng,
      );
      final back = katecToWgs84(x: katec.x, y: katec.y);

      expect(back.latitude, closeTo(seoulWgs.lat, 0.001));
      expect(back.longitude, closeTo(seoulWgs.lng, 0.001));
    });

    test('WGS84 → KATEC 왕복 변환이 오차 0.001° 이내로 복원된다 (충주)', () {
      final katec = wgs84ToKatec(
        latitude: chungjuWgs.lat,
        longitude: chungjuWgs.lng,
      );
      final back = katecToWgs84(x: katec.x, y: katec.y);

      expect(back.latitude, closeTo(chungjuWgs.lat, 0.001));
      expect(back.longitude, closeTo(chungjuWgs.lng, 0.001));
    });

    test('KATEC 좌표가 한국 영역의 합리적인 범위 내에 있다', () {
      // 서울 시청은 KATEC 기준 대략 (530xxx, 540xxx) 근처여야 함
      final katec = wgs84ToKatec(
        latitude: seoulWgs.lat,
        longitude: seoulWgs.lng,
      );
      expect(katec.x, greaterThan(100000));
      expect(katec.x, lessThan(1000000));
      expect(katec.y, greaterThan(100000));
      expect(katec.y, lessThan(1000000));
    });

    test('동일 입력 → 동일 출력 (결정성)', () {
      final a = wgs84ToKatec(latitude: 35.1796, longitude: 129.0756);
      final b = wgs84ToKatec(latitude: 35.1796, longitude: 129.0756);
      expect(a.x, b.x);
      expect(a.y, b.y);
    });
  });
}
