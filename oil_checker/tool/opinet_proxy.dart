import 'dart:convert';
import 'dart:io';

/// 로컬 개발용 서버: build/web 정적 파일 서빙 + Opinet API CORS 프록시
///
/// 사용법:
///   dart run tool/opinet_proxy.dart [port] [webDir]
///
/// 동작:
///   GET /opinet/경로?query  → https://www.opinet.co.kr/api/경로?query 로 중계
///   그 외 경로              → build/web 정적 파일 (SPA 폴백: index.html)
///
/// 브라우저와 같은 origin에서 호출하므로 CORS 정책에 걸리지 않는다.
/// 네이티브(Android) 앱은 프록시 없이 Opinet API를 직접 호출한다.
///
/// API 키 보안: Opinet 인증 코드는 클라이언트가 보내지 않고, 이 프록시가
/// 환경변수 `OPINET_API_CODE`에서 읽어 서버측에서 주입한다. (배포 프록시
/// `api/opinet/[...path].js`와 동일한 정책 — 웹 JS 번들에 키 미노출)
/// 환경변수가 없으면 프로젝트 루트의 `api-keys.json`(gitignored)을 읽는다.
void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args[0]) ?? 8899 : 8899;
  final webDir = args.length > 1
      ? Directory(args[1])
      : Directory('${Directory.current.path}${Platform.pathSeparator}build${Platform.pathSeparator}web');

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('[opinet_proxy] listening on http://localhost:$port');
  stdout.writeln('[opinet_proxy] web dir: ${webDir.path}');

  await for (final request in server) {
    _handle(request, webDir);
  }
}

Future<void> _handle(HttpRequest request, Directory webDir) async {
  final path = request.uri.path;
  try {
    // Opinet API 프록시: /opinet/<endpoint>?<query> → https://www.opinet.co.kr/api/<endpoint>?<query>
    if (path.startsWith('/opinet/')) {
      await _proxyOpinet(request);
      return;
    }

    // 정적 파일 서빙
    final relative = path == '/' ? 'index.html' : path.substring(1);
    final file = File('${webDir.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}');
    if (await file.exists()) {
      final resp = request.response;
      resp.headers.contentType = _contentType(file.path);
      await resp.addStream(file.openRead());
      await resp.close();
      return;
    }

    // SPA 폴백
    final index = File('${webDir.path}${Platform.pathSeparator}index.html');
    if (await index.exists()) {
      final resp = request.response;
      resp.headers.contentType = ContentType.html;
      await resp.addStream(index.openRead());
      await resp.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found: $path');
    await request.response.close();
  } catch (e, st) {
    stdout.writeln('[opinet_proxy] error handling $path: $e');
    stdout.writeln(st);
    try {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Proxy error: $e');
      await request.response.close();
    } catch (_) {}
  }
}

/// 앱이 사용하는 Opinet 엔드포인트만 허용한다 (무분별한 프록시 남용·키 도용 방지).
// Phase 3-A: lowTop10 / avgSidoPrice / avgAllPrice 읽기 전용 추가 (3건/일 예산 내)
const Set<String> _allowedEndpoints = {
  'aroundAll.do',
  'detailById.do',
  'lowTop10.do',
  'avgSidoPrice.do',
  'avgAllPrice.do',
};

/// https://www.opinet.co.kr/api 로 중계. CORS 헤더를 붙여준다.
///
/// Opinet 인증 코드는 클라이언트가 보내지 않으며, 환경변수 `OPINET_API_CODE`
/// 에서 읽어 서버측에서 주입한다. 클라이언트가 보낸 code는 무시한다.
Future<void> _proxyOpinet(HttpRequest request) async {
  final targetPath = request.uri.path.substring('/opinet'.length); // "/aroundAll.do" 등

  // 화이트리스트 검사 — 허용된 엔드포인트 외에는 403
  final endpoint = targetPath.split('/').last;
  if (!_allowedEndpoints.contains(endpoint)) {
    request.response
      ..statusCode = HttpStatus.forbidden
      ..write('Forbidden Opinet endpoint: $targetPath');
    await request.response.close();
    return;
  }

  // 키가 없으면 500 — 개발 키 누락을 즉시 드러낸다.
  final apiCode = _loadApiCode();
  if (apiCode == null || apiCode.isEmpty) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('OPINET_API_CODE is not configured (환경변수 또는 api-keys.json을 설정하세요).');
    await request.response.close();
    return;
  }

  // 클라이언트가 보낸 code는 무시하고 서버측에서 키를 주입한다.
  final query = Map<String, String>.from(request.uri.queryParameters)
    ..remove('code')
    ..['code'] = apiCode;
  final targetUri = Uri.parse('https://www.opinet.co.kr/api$targetPath').replace(
    queryParameters: query,
  );

  final client = HttpClient();
  try {
    final proxyReq = await client.getUrl(targetUri);
    // 브라우저 fetch와 유사한 헤더 구성 (인증서/리퍼러 이슈 최소화)
    proxyReq.headers.set('User-Agent', 'oil_checker-dev-proxy/1.0');
    proxyReq.headers.set('Accept', 'application/json, */*');
    proxyReq.headers.set('Referer', 'https://www.opinet.co.kr/');

    final proxyResp = await proxyReq.close();
    final bodyBytes = await proxyResp.fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );

    final resp = request.response;
    resp.statusCode = proxyResp.statusCode;
    // CORS — 브라우저가 같은 origin으로 호출하지만 안전을 위해 추가
    resp.headers.set('Access-Control-Allow-Origin', '*');
    resp.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    resp.headers.set('Access-Control-Allow-Headers', '*');
    resp.headers.contentType = ContentType.json;
    resp.add(bodyBytes);
    await resp.close();
  } catch (e) {
    stdout.writeln('[opinet_proxy] upstream error: $e');
    request.response
      ..statusCode = HttpStatus.badGateway
      ..write('Upstream error: $e');
    await request.response.close();
  } finally {
    client.close(force: true);
  }
}

/// `OPINET_API_CODE` 해석 — 환경변수 우선, 없으면 `api-keys.json` 폴백.
/// 파일은 CWD(프로젝트 루트에서 실행 가정) → 스크립트 기준 상위 디렉터리 순으로 찾는다.
String? _loadApiCode() {
  final env = Platform.environment['OPINET_API_CODE'];
  if (env != null && env.isNotEmpty) return env;

  final candidates = <File>[
    File('api-keys.json'),
    File.fromUri(Platform.script.resolve('../api-keys.json')),
  ];
  for (final file in candidates) {
    try {
      if (!file.existsSync()) continue;
      final json = jsonDecode(file.readAsStringSync());
      final code = json is Map ? json['OPINET_API_CODE'] : null;
      if (code is String && code.isNotEmpty) return code;
    } catch (_) {}
  }
  return null;
}

ContentType _contentType(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'html' => ContentType.html,
    'js' => ContentType('application', 'javascript'),
    'mjs' => ContentType('application', 'javascript'),
    'css' => ContentType('text', 'css'),
    'png' => ContentType('image', 'png'),
    'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
    'svg' => ContentType('image', 'svg+xml'),
    'ico' => ContentType('image', 'x-icon'),
    'wasm' => ContentType('application', 'wasm'),
    'json' => ContentType('application', 'json'),
    'otf' => ContentType('font', 'otf'),
    'ttf' => ContentType('font', 'ttf'),
    'map' => ContentType('application', 'json'),
    _ => ContentType.binary,
  };
}
