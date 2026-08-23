import 'package:oil_checker/core/coordinate/katec.dart';

void main() {
  // 서울 시청 (37.5665, 126.9780)
  final seoul = wgs84ToKatec(latitude: 37.5665, longitude: 126.9780);
  print('Seoul City Hall KATEC: x=${seoul.x.toStringAsFixed(3)}, y=${seoul.y.toStringAsFixed(3)}');
  // 부산 시청 (35.1796, 129.0756)
  final busan = wgs84ToKatec(latitude: 35.1796, longitude: 129.0756);
  print('Busan City Hall KATEC: x=${busan.x.toStringAsFixed(3)}, y=${busan.y.toStringAsFixed(3)}');
  // 역변환 검증
  final back = katecToWgs84(x: seoul.x, y: seoul.y);
  print('Round-trip Seoul: lat=${back.latitude.toStringAsFixed(6)}, lng=${back.longitude.toStringAsFixed(6)}');
}
