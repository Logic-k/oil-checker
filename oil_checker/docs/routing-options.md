# Routing Options — Oil Checker Phase 2-C PoC

> 작성일: 2026-08-29 | 상태: PoC 브랜치 검증용 (main 미병합, 승인 후 병합) | 기준: `Oil Checker PLAN.md` §4 + `.omo/plans/20260829-oil-checker-next.md` ADR-1

## 1. 결론 (TL;DR)

- **현재 동작 유지**: `RoutingClient` 추상화 + `OsrmClient` 구현 + `ROUTING_BASE_URL` 오버라이드 + `kOsrmCandidateCount=10` + `minInterval 1s` + `cacheTtl 30m` + `RoutingException → _fallbackRanking` 으로 **데모 서버 장애 시에도 앱 동작 보장**. 데모 서버 기본값(`router.project-osrm.org`) 그대로 사용 가능.
- **교체 1순위**: **자가 OSRM Docker** (`osrm-backend` + 한국 OSM extract) — API 규격 동일(`table` 1회 호출 → N×N 행렬)이라 `baseUrl`만 교체하면 코드 변경 최소화. CORS/쿼터 걱정 없음, SLA 자체 확보.
- **교체 2순위**: Kakao 모빌리티 다중 경유지 (`/v1/waypoints/directions`) — N×N 필요 시 N회 호출로 변환 필요, CORS는 `tool/opinet_proxy.dart`에 `/routing` 프록시 추가 또는 서버리스 프록시로 우회. 무료 쿼터 감안 시 후보 축소(10개)와 캐시 필수.

## 2. 옵션 비교

| 공급자 | API | 무료 쿼터 | OSRM `table` 1회 ↔ 변환 비용 | CORS | PoC 코드 변경량 | 권장 |
|---|---|---|---|---|---|---|
| **자가 OSRM** | `POST /table/v1/driving/:coords?annotations=distance,duration` | 무제한(자체 운영) | **0 — 규격 동일** | 없음(자체 호스트 CORS 허용 가능) | `ROUTING_BASE_URL`만 | **P1 권장** |
| Kakao | `GET /v1/waypoints/directions` (다중 경유지) | 장거리/다중 경유지 별도 쿼터(문서 기준 수천/일) | **N회 호출로 변환** (행렬 N×N → 왕복 N회) | **필요 — 프록시 추가** | 어댑터 1개 + 프록시 | 조건부 |
| Kakao | `GET /v1/directions` (단일 목적지) | 유사 | N회 | 필요 | 어댑터 + 루프 | 비권장 |
| OSRM Demo | `GET /table/v1/driving/:coords` | 비공식 1 req/s, SLA 없음 | 0 | 없음(CORS `*`) | 현재 그대로 | **완화만으로 운영 가능하나 장기 리스크** |

## 3. 교체 경로 (코드 기준)

### 3.1 현재 (데모 유지)

```dart
// providers.dart
final routingClientProvider = Provider<RoutingClient>((ref) {
  final dio = Dio(BaseOptions(connectTimeout: 10s, receiveTimeout: 20s));
  return OsrmClient(
    dio: dio,
    baseUrl: _routingBaseUrlOverride.isNotEmpty
        ? _routingBaseUrlOverride
        : OsrmClient.defaultBaseUrl, // router.project-osrm.org
  );
});
```

- `economyRankingProvider`는 `ref.watch(routingClientProvider)` + `on RoutingException → _fallbackRanking` 로 데모 장애 시 직선거리 폴백.
- 운영 오버라이드: `flutter run --dart-define=ROUTING_BASE_URL=https://your-osrm.host` 또는 `--dart-define=ROUTING_BASE_URL=http://10.0.2.2:8899/routing` (에뮬레이터 프록시 경유).

### 3.2 자가 OSRM Docker (권장 PoC)

```powershell
# 1. 한국 extract 다운로드 (예: Geofabrik South Korea)
# 2. OSRM 전처리 (car.lua 프로파일)
docker run -t -v "${PWD}/data:/data" osrm/osrm-backend osrm-extract -p /opt/car.lua /data/south-korea-latest.osm.pbf
docker run -t -v "${PWD}/data:/data" osrm/osrm-backend osrm-partition /data/south-korea-latest.osrm
docker run -t -v "${PWD}/data:/data" osrm/osrm-backend osrm-customize /data/south-korea-latest.osrm

# 3. 서버 기동 (table 지원)
docker run -p 5000:5000 -v "${PWD}/data:/data" osrm/osrm-backend osrm-routed --algorithm mld /data/south-korea-latest.osrm

# 4. 앱 연결
flutter run --dart-define=ROUTING_BASE_URL=http://localhost:5000
# 또는 에뮬레이터: --dart-define=ROUTING_BASE_URL=http://10.0.2.2:5000
```

- 검증: `curl "http://localhost:5000/table/v1/driving/126.9780,37.5665;129.0756,35.1796?annotations=distance,duration"` 가 `code: Ok` + `distances/durations` 반환 여부. 동일 `table` 규격이므로 앱 코드 변경 불필요.
- 프록시 불필요 (CORS 허용 시). 필요하면 `tool/opinet_proxy.dart`에 `/routing` → `ROUTING_BASE_URL` 중계 추가 가능 (현재 설계상 OSRM은 CORS 허용이라 불필요).

### 3.3 Kakao 어댑터 (선택 PoC, 시간박스 1일)

```dart
class KakaoRoutingClient implements RoutingClient {
  KakaoRoutingClient({required Dio dio, required String restApiKey, this.baseUrl = 'https://apis-navi.kakaomobility.com'});
  final Dio _dio; final String baseUrl; final String restApiKey;

  @override
  Future<({List<List<double>> distances, List<List<double>> durations})> table({required List<LatLng> points}) async {
    // Kakao는 단일 목적지/다중 경유지 단위이므로 N×N을 N회 호출로 변환 (왕복 기준 2N회 또는 N회 + 대칭 가정)
    // 예: 내위치(0) ↔ 후보(i) 왕복을 위해 directions 2회 호출 → 합산
    // rate limit/쿼터 소모 높음 → 후보 축소(10개) + 캐시 + 스로틀 필수
    // CORS 필요 → tool/opinet_proxy.dart에 /routing 프록시 추가 후 Authorization: KakaoAK 헤더 주입
    throw UnimplementedError('PoC 브랜치에서 검증 후 문서화');
  }
}
```

- PoC 브랜치에서만 검증, main 병합은 승인 후. 쿼터·비용·CORS 프록시 필요성을 이 문서에 기록 후 결정.

## 4. 운영 권고

- **Phase 2 종료 기준**: `flutter test` (osrm 캐시/스로틀/폴백 5건 포함) 통과 + `ROUTING_BASE_URL` 오버라이드로 자가 OSRM에 연결해 동일 테스트 통과 + `fallbackRanking`이 데모 차단 시에도 동작.
- **비용**: 자가 OSRM은 서버 비용(메모리 2-4GB 권장)만 발생, 쿼터 없음. Kakao는 무료 쿼터 내 운영 시 후보 축소·캐시로 충분하나, 일 1,000건 이상 랭킹 호출 시 초과 가능성 → 자가 OSRM이 안정적.
- **문서 유지**: 이 파일은 PoC 결과(성공/실패, 쿼터 실측, 비용)를 추적하는 살아있는 문서로 유지.

## 5. 검증 로그 (초기)

- 2026-08-29: `RoutingClient` 추상화 + `OsrmClient implements RoutingClient` + `ROUTING_BASE_URL` 적용, `flutter analyze` lib 0 issues (tool print만), `flutter test` 73 passed (KATEC 8건 포함) — 데모 기반 동작 검증 완료.
- 2026-08-29 (예정): 자가 OSRM Docker 기동 후 `curl /table` 검증 → 성공 시 `ROUTING_BASE_URL=http://localhost:5000` 으로 동일 테스트 재실행.
- 2026-08-29 (예정): Kakao 다중 경유지 PoC — 시간박스 1일, 실패 시에도 “프록시·쿼터·코드 변경량” 기록만 남기고 main 병합 보류.
