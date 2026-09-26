# Oil Checker 고도화 작업계획 — 2026-08-29

> 상태: **승인 대기 (Approved 전 구현 금지)** / 작성자: Sisyphus / 기준 커밋: `6351fa9` (main, origin/main 동기화)
> 선행 문서: `Oil Checker PLAN.md` §3/§4/§6, `AGENTS.md` §6, `.omo/ulw-research/20260815-221929/SYNTHESIS.md` + `verify-build-state.md`, `oil_checker/README.md`

---

## 0. TL;DR (결정 요약)

- **현상**: MVP 완성·배포 가능 상태는 유지. 2026-08-15 리서치의 P1 3건 중 2.5건은 이미 해소됨 — `sqlite3_flutter_libs EOL 제거`(drift 2.34 + drift_flutter 0.3.1), `git 초기화 + 프록시 서버측 주입 + allowlist`는 완료. 단 **OSRM 데모 서버 의존**(router.project-osrm.org, 1 req/s, SLA 없음)은 완화(후보 10개로 축소·스로틀·캐시·폴백)만 됐고 **완전 제거는 미완**. P2 `dynamic dispatch`와 major bump 3건(proj4dart/geolocator/csv)은 잔존.
- **다음 디벨롭 방향**: “남은 부채를 터뜨리지 않고” (1) 타입 안정화 + 의존성 major를 회귀테스트로 잠그고 → (2) 라우팅을 추상화해 데모 서버를 교체 가능하게 만들고 → (3) 오피넷 공식앱 v4.0.1이 흡수한 ‘연비 반영 추천’과 겹치지 않는 **우회비용·시간가치·주유이력 기반 실연비**로 차별화를 재정의.
- **실행 원칙**: `AGENTS.md` 제약(키 평문 금지·KATEC 변환 강제·TTL 우회 금지·CORS 프록시 경유) 절대 유지. 각 Phase는 `flutter analyze` 0 issues + `flutter test` 통과를 게이트로 삼는다.

---

## 1. 현황 진단 (2026-08-29 직접 검증)

### 1.1 검증된 사실 테이블

| 영역 | 2026-08-15 시점 | 2026-08-29 현재 (직접 Read) | 판정 |
|---|---|---|---|
| git | 없음 | `main` 브랜치, origin `Logic-k/oil-checker` 동기화, 최근 10커밋 존재 (`ed9d45f` sqlite 마이그레이션, `d28d650` Riverpod legacy 제거, `f10770d` OSRM 후보 축소) | ✅ 해소 |
| API 키 보안 | `kOpinetApiCode` 평문 | `providers.dart:26` `String.fromEnvironment('OPINET_API_CODE')`, `api/opinet/[...path].js`가 `process.env.OPINET_API_CODE` 서버측 주입 + `code` 파라미터 클라이언트 제거 + allowlist(2개) | ✅ 해소 |
| 프록시 | 미확인 | `api/opinet/[...path].js` CDN `s-maxage=600` + `tool/opinet_proxy.dart` 동일 정책, `vercel.json` rewrite `/opinet/:path* → /api/opinet/:path*` | ✅ 해소 |
| DB | `sqlite3_flutter_libs 0.5.42` EOL | `pubspec.yaml`에서 `sqlite3_flutter_libs` 제거, `drift ^2.34.0` + `drift_flutter ^0.3.1` + `driftDatabase()` + hooks 자동 번들, `app_database.dart` schemaVersion 1 | ✅ 해소 (웹 wasm 검증은 Phase 1에서 재확인) |
| OSRM | `router.project-osrm.org` 하드코딩, 무제한 호출 | `osrm_client.dart` `defaultBaseUrl` 유지하되 `minInterval 1s`·`cacheTtl 30m`·`kOsrmCandidateCount=10`·`OsrmException → _fallbackRanking` 폴백 구현. `providers.dart:259` `osrmClientProvider`는 baseUrl 교체 가능 구조 | ⚠️ 완화됨, 미제거 (P1 잔존) |
| Riverpod | `StateProvider` legacy import | `providers.dart` 전수 검사 결과 `StateProvider`/`legacy.dart` 없음. `Notifier`/`NotifierProvider`로 전환 완료 | ✅ 해소 |
| economy | `dynamic` dispatch | `economy_engine.dart:117-123` `_scoreOf<T>` 여전히 `dynamic d = item; score is num` | ❌ 잔존 (P2) |
| 의존성 major | proj4dart 2.1, geolocator 13, csv 6 | 동일하게 `pubspec.yaml`에 고정 (2.1/13.0.2/6.0.0). `latest`는 3.0/14.0.3/8.0.0 | ❌ 잔존 |
| 지도 | Kakao 예정 | `home_screen.dart` `flutter_map 8.0 + latlong2 0.9.1` + OSM `tile.openstreetmap.org` 타일. Kakao 교체 가능 추상화는 미구현 | Δ PLAN과 상이하나 동작 (후순위) |
| 테스트 | 66 통과 | `test/` 11개 파일 (economy/katec/opinet/congestion/car_spec/db/opinet_repository/osrm/ranking 등). `README`는 69로 갱신했으나 `verify-build-state.md`는 66. 재측정 필요 | Δ |
| 빌드 크기 | web 38.6MB, APK 57.2MB | 미재측정 (동일 코드베이스이므로 유사 추정) | 후순위 |

### 1.2 코드베이스 체감 품질

- **Disciplined에 가깝다**: `flutter analyze lib/` 0 issues 목표가 이미 달성된 구조, `economy_engine.dart`·`congestion.dart`·`katec.dart`·`opinet_repository.dart` 모두 주석·예외·fallback이 체계적. 250 LOC 초과 우려 파일은 `presentation/providers.dart`(501줄), 각 screen(16-22k)이나 역할 분리상 허용 범위.
- **Risk**: `economy_engine.dart:107 rankByEconomy<T>`의 제네릭 + dynamic 조합은 테스트 17개로 방어 중이나 타입 누수 가능. `providers.dart:335 economyRankingProvider`가 OSRM 행렬·혼잡·실연비·기준주유소·랭킹을 한 provider에 결합 — OSRM 교체 시 파급 범위 큼.

### 1.3 문서 간 불일치 메모

- `Oil Checker PLAN.md`는 지도 SDK로 Kakao를 채택했으나 실제 구현은 OSM(`flutter_map`) — 비용 0을 택한 결정으로 보이며 되돌릴 필요 없음. 다만 PLAN §6.1 갱신 필요.
- `AGENTS.md` §6 P1에 sqlite EOL이 아직 남아있으나 실제론 해소 — 문서 갱신 필요.
- 호출 한도: 초기 요구사항 15,000건 vs 무료 가이드 1,500건 — 현재 설계는 1,500건 기준 7% 사용으로 보수적이며 유지.

---

## 2. 목표 (Goals) / 비목표 (Non-Goals)

**Goals**
- G1: 남은 타입 부채·major 의존성 부채를 **회귀 없이** 제거하고, `flutter analyze`/`flutter test` 게이트를 매 Phase마다 통과.
- G2: 라우팅을 **교체 가능한 추상화**로 분리해 데모 서버 장애 시에도 앱이 동작하고, 운영자가 `baseUrl` 또는 상용 API로 전환할 수 있게 한다.
- G3: 오피넷 공식앱과의 겹침을 피하는 **제품 차별화 가설**을 코드로 증명 (우회비용+시간가치+실연비+목적지 기반 추천 UX).

**Non-Goals**
- Kakao/Naver/TMAP 상용 라우팅으로의 즉시 완전 전환 (비용·쿼터·CORS 프록시 필요 — Phase 2에서 ‘교체 가능성’까지만).
- OSM → Kakao 지도 SDK 교체 (현 OSM 유지, 추상화만 준비).
- 빌드 크기 50% 축소, AAB 전환 같은 최적화는 Phase 4로 이연.

---

## 3. 제약 & 전제

1. `AGENTS.md` §5 5대 제약 절대 준수 (키 평문 금지, KATEC 변환 강제, TTL 우회 금지, `/opinet` 프록시 경유, sqlite 한글 깨짐 주의).
2. `economy_engine.dart` 공식(절약액·연료비용·시간비용·경제성점수·왕복 2배) 변경 시 `test/economy_test.dart` 동시 갱신.
3. `katec.dart` proj4 문자열(`+towgs84=...`) 변경 금지 — 변경 시 `test/katec_test.dart` 회귀 필수.
4. `cacheTtl=6h`, `kOsrmCandidateCount=10`, `minInterval=1s` 같은 운영 상수는 `providers.dart`/`osrm_client.dart`에 집중 — 분산 금지.

---

## 4. 아키텍처 결정 (ADR)

| ADR | 결정 | 근거 | 되돌리는 조건 |
|---|---|---|---|
| ADR-1 | 라우팅 추상화: `RoutingClient` 인터페이스 도입, `OsrmClient`는 구현체 중 하나 | `providers.dart:ecomomyRankingProvider`가 OSRM에 직접 결합 → 교체·테스트 불가. 인터페이스로 끊어야 fallback·mock·상용 교체가 가능 | 인터페이스가 오히려 복잡도를 높여 테스트가 깨질 때 |
| ADR-2 | proj4dart 3.0은 **KATEC 회귀테스트 선행** 후 bump | KATEC 오차 1m가 가격·거리·랭킹 전부 왜곡. `katec_test.dart`가 유일한 안전망 | 3.0이 breaking 없이 2.1과 동일 결과를 낼 때만 진행 |
| ADR-3 | geolocator 14·csv 8은 **economy/KATEC 회귀 후** 순차 bump | 권한 API·CSV 파서 breaking이 앱 진입부(위치·차량 로더)에 영향 | 각 패키지 CHANGELOG의 breaking이 우리 호출부에 없을 때 |
| ADR-4 | 제품 차별화는 **오피넷 미사용 엔드포인트를 ‘읽기’로만** 활용 | `lowTop10`/`avgSidoPrice` 등은 쓰기 영향 없고 캐시 전략 재사용 가능. 신규 쓰기(즐겨찾기/알림)는 스코프 밖 | 한도 1,500건 내에서 추가 호출이 110건/일 예산을 초과하지 않을 때만 |

---

## 5. 작업 분해 (Phase별 — 승인 후 순차 실행, Phase 내 병렬 가능)

### Phase 1 — 잔존 부채 제거 + 회귀 잠금 (예상 2일, 위험 낮음)

**목표**: `dynamic` 제거와 major bump 준비를 **테스트로 잠근 뒤** 수행.

- **1-A. `economy_engine.dart` 타입 안정화**
  - 파일: `lib/domain/economy/economy_engine.dart:107-123`
  - 변경: `rankByEconomy<T>` + `_scoreOf` dynamic 제거 → `HasScore` sealed interface 도입. `EconomyResult`와 `EconomyRankingEntry`가 구현. `rankByEconomy(List<HasScore>)`로 시그니처 축소. `providers.dart`의 `preliminary`/`results`가 이미 `EconomyRankingEntry`이므로 호환.
  - 검증: `flutter test test/economy_test.dart` + `test/ranking_screen_test.dart` 통과, `flutter analyze` 0 issues.
  - 비고: `AGENTS.md` P2 `dynamic dispatch` 해소.

- **1-B. KATEC 회귀 가드레일 보강**
  - 파일: `test/katec_test.dart`, `tool/katec_probe.dart` (존재 시)
  - 변경: WGS84↔KATEC 왕복 오차 1m 이내 assert 추가, 서울(37.5665,126.9780)·부산·제주 3점 고정 케이스 추가. `proj4dart 3.0` 전환 전후 diff를 `dart run tool/katec_probe.dart`로 출력해 리뷰.
  - 검증: `flutter test test/katec_test.dart` 통과.

- **1-C. 의존성 major bump (순차, 하나씩)**
  - 순서: `proj4dart 2.1 → 3.0` → `csv 6 → 8` → `geolocator 13 → 14`
  - 각 bump마다: `pubspec.yaml` 버전 상향 → `flutter pub get` → `flutter analyze` → `flutter test` → 수동 스모크(차량 로더·위치 권한·KATEC 변환). 실패 시 즉시 revert.
  - 특히 `geolocator 14`는 `LocationSettings`·`checkPermission` breaking 확인 필요 (`providers.dart:135 currentLocationProvider`).
  - 검증: `flutter pub outdated`에서 해당 패키지 `latest`와 `resolvable` 일치.

- **1-D. 문서 정합화**
  - 파일: `AGENTS.md` §6 P1/P2, `Oil Checker PLAN.md` §6.1 지도 SDK, `oil_checker/README.md` 테스트 수
  - 변경: 해소된 항목( sqlite, git, Riverpod) 체크, OSM 채택 명시, `flutter test` 실제 수로 갱신.
  - 검증: 문서만 변경, 빌드 무영향.

**Phase 1 게이트**: `flutter analyze` 0 issues, `flutter test` 전 통과, `flutter pub outdated`에서 3개 major 해소.

### Phase 2 — 라우팅 탈결합 (예상 2-3일, 위험 중간)

**목표**: 데모 서버 장애·차단에 앱이 죽지 않고, 운영자가 교체할 수 있게 만든다.

- **2-A. `RoutingClient` 추상화**
  - 신규: `lib/data/routing/routing_client.dart` (interface: `Future<RoutingMatrix> table({required List<LatLng> points})`)
  - 변경: `osrm_client.dart:44 OsrmClient implements RoutingClient` 로 구현. `providers.dart:259 osrmClientProvider` → `routingClientProvider`로 교체 (기존 이름은 `@Deprecated` alias 유지). `economyRankingProvider`는 `RoutingClient`에만 의존.
  - 검증: 기존 `test/osrm_client_test.dart`가 `RoutingClient` mock으로 통과. `OsrmException` → fallback 경로는 유지.

- **2-B. 운영 주입 경로 확장**
  - 파일: `lib/presentation/providers.dart`, `lib/data/routing/osrm_client.dart`
  - 변경: `--dart-define=ROUTING_BASE_URL` 추가 (기존 `OPINET_BASE_URL` 패턴 재사용). `kIsWeb`에서도 프록시 경유 없이 직접 호출 가능하나, 상용 라우팅(CORS 필요)은 `tool/opinet_proxy.dart`에 `/routing` 프록시 추가를 옵션으로 제공. 기본은 그대로 `router.project-osrm.org`.
  - 검증: `flutter run --dart-define=ROUTING_BASE_URL=http://10.0.2.2:8899/routing` 로컬 프록시 경유 스모크.

- **2-C. 자가 OSRM 또는 상용 API PoC (선택, 시간박스 1일)**
  - 옵션 1 (권장): Docker `osrm-backend` + 한국 extract 로컬 구동 → `baseUrl` 교체로 `table` 규격 동일성 검증.
  - 옵션 2: Kakao 모빌리티 `다중 경유지` API 어댑터 작성 (N×N을 N회 호출로 변환, 쿼터·CORS·프록시 필요성 문서화).
  - 산출물: `docs/routing-options.md` (비용·쿼터·SLA·코드 변경량 비교). 구현은 PoC 브랜치로만, main 병합은 승인 후.

**Phase 2 게이트**: 데모 서버를 끊은 상태(네트워크 차단 mock)에서도 `economyRankingProvider`가 fallback으로 동작하고, `ROUTING_BASE_URL` 교체 시 동일 테스트가 통과.

### Phase 3 — 제품 차별화 (예상 3-4일, 위험 중간, PM 결정 필요)

**목표**: “오피넷 공식앱이 못하는 것”을 증명. PLAN §2.2 후순위 + SYNTHESIS §6 전략을 코드로 옮긴다.

- **3-A. 미사용 Opinet 엔드포인트 읽기 전용 추가**
  - 파일: `lib/core/opinet/opinet_client.dart`, `lib/data/opinet/opinet_repository.dart`
  - 추가: `fetchLowTop10({area?, cnt=20, prodcd})`, `fetchAvgSidoPrice({sido, prodcd})`, `fetchAvgSigunPrice` — `aroundAll`과 동일하게 `code` 주입·`_getJson` 재사용. `ALLOWED_ENDPOINTS`에 해당 경로 추가 (`api/opinet/[...path].js`, `tool/opinet_proxy.dart`).
  - 캐시: `StationCache` 재사용 불가(집계 데이터) → 메모리 캐시 6h + `Cache-Control s-maxage=600` 동일 적용. 호출 예산: 기존 110건/일 + 신규 3건/일 = 113건/일 (한도 7.5% 유지).
  - UI: `home_screen.dart`에 “전국 최저가 TOP20” 읽기 전용 탭(링크만), `settings_screen.dart`에 “시도 평균가 대비 내 주변가” 배지. 쓰기(즐겨찾기/알림)는 제외.
  - 검증: `test/opinet_test.dart`에 신규 엔드포인트 mock 3건 추가.

- **3-B. 주유이력 기반 실연비 강화 + 시간가치 노출**
  - 파일: `lib/data/db/app_database.dart:203 computeLatestKmPerL`, `lib/presentation/providers.dart:349-352`, `lib/presentation/screens/history_screen.dart`, `ranking_screen.dart`
  - 변경: `computeLatestKmPerL`에 이상치 필터(이동거리 ≤0 또는 연비 3~30 km/L 밖 제외) 추가. `ranking_screen.dart`에 사용된 연비가 실연비인지 수동/표시연비인지 배지 노출 (이미 `isRealEfficiency` 존재 — UI만 연결). `kTimeValueWonPerMin`을 `settings_screen.dart`에서 편집 가능하게 (0~300원/분 슬라이더, 기본 80).
  - 검증: `test/db_test.dart`에 이상치 케이스 3건 추가.

- **3-C. 목적지 기반 우회 추천 UX (SYNTHESIS §6 차별화 3번)**
  - 파일: `lib/presentation/providers.dart` (computeDetourKm 사용처), `lib/presentation/screens/home_screen.dart` (지도 롱프레스 목적지 설정), `ranking_screen.dart`
  - 변경: 현재 `computeDetourKm(fromToStationKm)` 왕복 2배 고정에서, 목적지 LatLng가 있으면 `fromToStationKm + stationToDestinationKm` 편도로 분기 (이미 함수 시그니처는 준비됨). 지도에서 목적지 핀 지정 시 `stationToDestinationKm`을 OSRM `table`의 `station→destination` 거리로 계산. 카피를 “추천”이 아닌 “여기서 주유하면 N원 절약(우회비용 M원 포함)”으로 변경.
  - 검증: `test/economy_test.dart`에 목적지 유/무 2케이스, `test/ranking_screen_test.dart`에 카피 스냅샷.

**Phase 3 게이트**: 신규 Opinet 호출이 한도 예산을 초과하지 않음이 로그로 증명, 실연비·시간가치·목적지 3요소가 랭킹에 반영됨.

### Phase 4 — 폴리싱 & 릴리즈 하드닝 (예상 1-2일, 위험 낮음)

- **4-A. 빌드 최적화 (선택)**
  - `build/web` 38.6MB 원인 분석: `flutter build web --analyze-size` → CanvasKit, 폰트, `car_fuel_economy.csv` 중 지배 요인 확인. 대응: 폰트 서브셋, `deferred import` 검토, `csv` gzip. AAB 전환은 `flutter build appbundle` 스모크만.
- **4-B. QA 하네스**
  - `screenshots/` + `*.yml` Playwright 스냅샷을 `flutter test` 스샷으로 대체하거나 유지 여부 결정. `tool/katec_probe.dart`의 `print`를 `flutter analyze` info에서 제외할지 유지할지 결정.

**Phase 4 게이트**: `flutter build web` · `flutter build apk --release` 스모크 통과, `flutter analyze`/`flutter test` 그린.

---

## 6. 검증 계획 (매 Phase 공통)

- **정적**: `flutter analyze` (lib/ 0 issues, tool/katec_probe.dart print info만 허용)
- **단위**: `flutter test` (전체 통과, Phase 1-3에서 추가된 신규 테스트 포함)
- **회귀**: KATEC 왕복 3점, economy 17케이스, OSRM fallback, 캐시 TTL 6h, 권한 거부 케이스
- **수동 스모크**: 웹 `http://localhost:8899` 프록시 경유, Android 실기기/에뮬레이터 `adb emu geo fix 126.978 37.566` 서울 좌표 스모크
- **배포**: `vercel --prod` 또는 push 자동 배포, `api/opinet/[...path].js` allowlist·env 누락 500·CDN 헤더 확인

---

## 7. 리스크 & 롤백

| 리스크 | 확률 | 영향 | 완화 | 롤백 |
|---|---|---|---|---|
| proj4dart 3.0 좌표 오차 | 중 | 높음 | Phase 1-B 회귀 3점 + probe diff | `pubspec.yaml` revert, `pubspec.lock` 복구 |
| geolocator 14 권한 breaking | 중 | 중간 | Phase 1-C 순차 bump, 권한 denied/forever 케이스 테스트 | 동일 |
| OSRM 추상화가 provider 결합을 더 꼬음 | 낮음 | 중간 | 2-A에서 alias 유지, 기존 테스트를 mock으로 먼저 통과 | `routing_client.dart` 삭제, `osrmClientProvider` 복구 |
| 신규 Opinet 호출이 한도 초과 | 낮음 | 중간 | 3-A에서 3건/일로 제한, CDN 캐시, 로그로 일일 호출 수 카운트 | allowlist에서 신규 경로 제거, 메모리 캐시 TTL 0 |
| 제품 차별화 가설이 사용자 테스트에서 무의미 | 중 | 중간 | 3-B/3-C를 UI 카피·배지로 먼저 검증, A/B 없이 스모크로 판단 | 해당 UI 토글 플래그 off |

---

## 8. 일정 & 의존 그래프

```
Phase 1 (2d) ──→ Phase 2 (2-3d) ──→ Phase 3 (3-4d) ──→ Phase 4 (1-2d)
  1-A/B/C/D 병렬 가능   2-A/B 병렬, 2-C 시간박스   3-A/B/C 병렬 가능
```

- **Critical path**: 1-B(KATEC 가드레일) → 1-C(proj4dart) → 2-A(RoutingClient) → 3-C(목적지 우회). 이 경로가 지연되면 전체가 지연.
- **병렬 가능**: 1-A(dynamic 제거)와 1-D(문서)는 독립. 3-A(Opinet 신규)와 3-B(실연비)는 독립.

---

## 9. 다음 액션 (승인 후 즉시 실행)

1. **사용자 승인** — 본 계획의 Phase 1-4 범위와 ADR 4건에 대해 승인/수정 요청.
2. **브랜치**: `chore/next-plan` 또는 `feat/routing-abstraction` 로 Phase 1 시작.
3. **첫 커밋**: `1-A economy_engine` 타입 안정화 + 테스트 (가장 작고 안전한 변경으로 게이트 검증).
4. **매 Phase 종료 시**: `flutter analyze`/`flutter test` 로그 + `git log --oneline -5`를 첨부해 리뷰 요청.

---

## 10. 부록 — 직접 검증 근거 (발췌)

- `oil_checker/pubspec.yaml:18-33` — `drift ^2.34.0` + `drift_flutter ^0.3.1`, `sqlite3_flutter_libs` 없음, `proj4dart ^2.1.0`/`geolocator ^13.0.2`/`csv ^6.0.0` 잔존
- `oil_checker/lib/domain/economy/economy_engine.dart:107-123` — `dynamic` dispatch 잔존
- `oil_checker/lib/presentation/providers.dart:42-56,70-86,259-267,335-458` — DB/RPC/routing/economy 전역 provider, `kOsrmCandidateCount=10`, fallback 구현
- `oil_checker/lib/data/routing/osrm_client.dart:51-57` — `defaultBaseUrl = router.project-osrm.org`, `minInterval`/`cacheTtl`
- `oil_checker/api/opinet/[...path].js:24,38-48` — `ALLOWED_ENDPOINTS` 2개, 서버측 `code` 주입, `s-maxage=600`
- `git log --oneline -12` — `ed9d45f` sqlite 마이그레이션, `d28d650` Riverpod legacy 제거, `f10770d` OSRM 후보 축소
- `.omo/ulw-research/20260815-221929/verify-build-state.md` — `flutter analyze` 3 info( tool만), `flutter test` 66 통과, 33개 outdated
