// Opinet API CORS 프록시 (Vercel 서버리스 함수)
//
// 웹 빌드(Flutter web)는 같은 origin의 `/opinet/*` 경로로 호출한다.
// Opinet API는 CORS 헤더를 제공하지 않아 브라우저 직접 호출이 차단되므로,
// 이 함수가 `https://www.opinet.co.kr/api/*`로 중계해 CORS를 우회한다.
// 로컬 개발 시에는 `tool/opinet_proxy.dart`가 같은 역할을 한다.
//
// API 키 보안: Opinet 인증 코드는 클라이언트가 보내지 않고, 이 함수가
// 서버측 환경변수 `OPINET_API_CODE`에서 읽어 주입한다. 이로써 배포된
// 웹 JS 번들에 키가 노출되지 않는다. (Vercel 프로젝트 환경변수로 설정)
//
// 배포: 이 파일만으로 Vercel Functions로 자동 배포된다 (프로젝트 루트의 api/ 디렉터리).
// 로컬 테스트: `vercel dev` 실행 후 http://localhost:3000/opinet/aroundAll.do?... 로 확인.

// 앱이 사용하는 Opinet 엔드포인트만 허용한다 (무분별한 프록시 남용·키 도용 방지).
const ALLOWED_ENDPOINTS = new Set(['aroundAll.do', 'detailById.do']);

export default async function handler(req, res) {
  try {
    // /opinet/aroundAll.do?x=... → path = ["aroundAll.do"], 나머지는 query params
    const segments = Array.isArray(req.query.path)
      ? req.query.path
      : req.query.path
        ? [req.query.path]
        : [];
    const targetPath = segments.join('/');

    // 화이트리스트 검사 — 허용된 엔드포인트 외에는 403
    if (!ALLOWED_ENDPOINTS.has(targetPath)) {
      res.status(403).json({ error: `Forbidden Opinet endpoint: ${targetPath}` });
      return;
    }

    // 키가 없으면 500 — 배포 환경변수 누락을 즉시 드러낸다.
    const apiCode = process.env.OPINET_API_CODE;
    if (!apiCode) {
      res.status(500).json({ error: 'OPINET_API_CODE is not configured' });
      return;
    }

    // 클라이언트가 보낸 code는 무시하고 서버측에서 키를 주입한다.
    const { path: _omit, code: _clientCode, ...rest } = req.query;
    const qs = new URLSearchParams({ ...rest, code: apiCode }).toString();
    const target = `https://www.opinet.co.kr/api/${targetPath}${qs ? `?${qs}` : ''}`;

    const upstream = await fetch(target, {
      headers: {
        'User-Agent': 'oil_checker-vercel-proxy/1.0',
        Accept: 'application/json, */*',
        Referer: 'https://www.opinet.co.kr/',
      },
    });

    const body = await upstream.text();
    res.status(upstream.status);
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    // 가격 갱신 시각(1/2/9/12/16/19시) 기준 짧은 CDN 캐시 — API 일일 한도(1,500건) 절약
    res.setHeader('Cache-Control', 'public, s-maxage=600, max-age=60');
    res.send(body);
  } catch (err) {
    res.status(502).json({ error: `Opinet proxy error: ${err.message}` });
  }
}
