import 'dart:convert';

import 'package:dio/dio.dart';

import 'opinet_station.dart';

/// Opinet API 호출 실패 시 던지는 예외
class OpinetException implements Exception {
  const OpinetException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'OpinetException: $message';
}

/// Opinet (한국석유공사 유가정보) API 클라이언트
///
/// - 무료 API 인증 파라미터는 `code` (오픈API의 `certkey` 아님)
/// - 좌표는 WGS84가 아닌 KATEC(EPSG:5174) 사용 → [KatecCoord] 참고
/// - 일일 1,500건 한도, 가격 갱신 1/2/9/12/16/19시
///
/// API 키 보안: [apiCode]가 null이면 `code` 파라미터를 보내지 않는다.
/// 웹은 같은 origin의 프록시(`/opinet`)가 서버측에서 환경변수
/// `OPINET_API_CODE`로 키를 주입하므로, 클라이언트 JS 번들에 키가
/// 노출되지 않는다. 네이티브는 `--dart-define=OPINET_API_CODE`로 주입한다.
class OpinetClient {
  OpinetClient({
    required Dio dio,
    this.apiCode,
    this.baseUrl = defaultBaseUrl,
  }) : _dio = dio;

  final Dio _dio;

  /// Opinet 무료 API 인증 코드. null이면 `code` 파라미터 생략
  /// (프록시가 서버측에서 주입하는 경로).
  final String? apiCode;

  /// Opinet API 기본 엔드포인트.
  ///
  /// 웹에서는 같은 origin의 프록시(`/opinet`)를 사용해 CORS를 회피하고,
  /// 네이티브에서는 실제 Opinet 서버를 직접 호출한다. ([providers.dart] 참고)
  static const String defaultBaseUrl = 'https://www.opinet.co.kr/api';

  final String baseUrl;

  /// 휘발유
  static const String productGasoline = 'B027';
  /// 고급휘발유
  static const String productPremium = 'B034';
  /// 경유
  static const String productDiesel = 'D047';
  /// LPG
  static const String productLpg = 'K015';

  /// 반경 내 주유소 조회 (`aroundAll.do`)
  ///
  /// [x], [y]는 KATEC 좌표. [radiusM]은 5000m 이하만 허용.
  /// [sort] 1=가격순, 2=거리순.
  Future<List<OpinetStation>> fetchStationsAround({
    required double x,
    required double y,
    int radiusM = 5000,
    String productCode = productGasoline,
    int sort = 1,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'x': x,
        'y': y,
        'radius': radiusM,
        'prodcd': productCode,
        'sort': sort,
        'out': 'json',
      };
      if (apiCode != null) queryParameters['code'] = apiCode;
      final data = await _getJson(
        '$baseUrl/aroundAll.do',
        queryParameters: queryParameters,
      );

      final result = data['RESULT'] as Map<String, dynamic>?;
      final oil = result?['OIL'] as List<dynamic>?;
      if (oil == null) {
        throw const OpinetException('RESULT.OIL 응답이 없습니다.');
      }

      return oil
          .map((e) => OpinetStation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw OpinetException('Opinet API 호출 실패: ${e.message}', cause: e);
    }
  }

  /// 주유소 상세 정보 조회 (`detailById.do`)
  ///
  /// [uniId]는 aroundAll 응답의 UNI_ID. 주소(도로명/지번), 전화, 부가서비스,
  /// 유종별 가격을 반환한다. **영업시간은 Opinet이 제공하지 않는다.**
  ///
  /// 주의: 상세 API의 요청 파라미터 이름은 `id` (uni_id나 os_id가 아님).
  /// 실제 응답의 상표 필드는 `POLL_DIV_CO` (aroundAll은 `POLL_DIV_CD`).
  Future<OpinetStationDetail?> fetchStationDetail({
    required String uniId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'id': uniId,
        'out': 'json',
      };
      if (apiCode != null) queryParameters['code'] = apiCode;
      final data = await _getJson(
        '$baseUrl/detailById.do',
        queryParameters: queryParameters,
      );

      final result = data['RESULT'] as Map<String, dynamic>?;
      final oil = result?['OIL'] as List<dynamic>?;
      if (oil == null || oil.isEmpty) {
        return null; // 상세 정보 없음 (유효하지 않은 ID 등)
      }
      return OpinetStationDetail.fromJson(oil.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OpinetException('Opinet 상세 조회 실패: ${e.message}', cause: e);
    }
  }

  /// Opinet 응답을 JSON Map으로 파싱한다.
  ///
  /// Opinet은 `Content-Type: text/html; charset=utf-8`로 JSON을 반환한다.
  /// Dio의 기본 `ResponseType.json`은 JSON이 아닌 Content-Type에 대해
  /// 디코딩을 생략하고 `String`을 반환해 타입 캐스팅이 실패한다.
  /// 따라서 raw string으로 받아 직접 [jsonDecode]한다.
  Future<Map<String, dynamic>> _getJson(
    String url, {
    required Map<String, dynamic> queryParameters,
  }) async {
    final response = await _dio.get<String>(
      url,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.plain),
    );
    final body = response.data;
    if (body == null || body.trim().isEmpty) {
      throw const OpinetException('Opinet 응답이 비어 있습니다.');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw OpinetException('Opinet 응답 형식이 올바르지 않습니다: $decoded');
    }
    return decoded;
  }
}
