import 'package:proj4dart/proj4dart.dart' as proj4;

/// KATEC(EPSG:5174) 좌표계 변환 모듈
///
/// Opinet API는 WGS84(위경도)가 아닌 KATEC 미터 좌표를 사용한다.
/// - GPS는 WGS84 → API 호출 전에 KATEC으로 변환
/// - API 응답(GIS_X_COOR/GIS_Y_COOR)은 지도 표시 전에 WGS84로 변환
class KatecCoord {
  const KatecCoord({required this.x, required this.y});

  final double x;
  final double y;

  @override
  String toString() => 'KatecCoord(x: $x, y: $y)';
}

class Wgs84Coord {
  const Wgs84Coord({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() => 'Wgs84Coord(lat: $latitude, lng: $longitude)';
}

// KATEC 프로젝션 정의 (한국측지계 Bessel, 중부원점)
// 주의: proj4dart는 '38N' 같은 단위 접미사를 지원하지 않아 데시멀 각도 사용
const String kKatecProj4 =
    '+proj=tmerc +lat_0=38 +lon_0=128 +ellps=bessel '
    '+x_0=400000 +y_0=600000 +k=0.9999 +units=m '
    '+towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43';

proj4.Projection? _katecProj;

proj4.Projection _katec() =>
    _katecProj ??= proj4.Projection.parse(kKatecProj4);

proj4.Projection _wgs84() => proj4.Projection.WGS84;

/// WGS84(위경도) → KATEC(x, y)
KatecCoord wgs84ToKatec({
  required double latitude,
  required double longitude,
}) {
  final converted = proj4.ProjectionTuple(
    fromProj: _wgs84(),
    toProj: _katec(),
  ).forward(proj4.Point(x: longitude, y: latitude));
  return KatecCoord(x: converted.x, y: converted.y);
}

/// KATEC(x, y) → WGS84(위경도)
Wgs84Coord katecToWgs84({required double x, required double y}) {
  final converted = proj4.ProjectionTuple(
    fromProj: _katec(),
    toProj: _wgs84(),
  ).forward(proj4.Point(x: x, y: y));
  return Wgs84Coord(latitude: converted.y, longitude: converted.x);
}
