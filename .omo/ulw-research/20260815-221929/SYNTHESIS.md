# SYNTHESIS — Oil Checker 구현 현황 + 개선 방향 리서치

- 세션: 20260815-221929 (2026-08-15)
- 쿼리: "지금까지 한 것을 정리하고, 리서치를 통해 개선할 수 있는 방향 알아보기"
- 대상: `E:\OpenCode_OilMaker\oil_checker` — Flutter 3.41.5 / Dart 3.11.3, 웹(Vercel) + Android
- 산출물: 본 문서 + `verify-build-state.md` (검증) + `expansion-log.md` (리서치 로그)

---

## 1. 핵심 요약 (TL;DR)

**구현 상태: 견고하다.** 66개 테스트 전부 통과, `lib/` analyze 0 이슈, 3단 TTL 캐시 + 오프라인 폴백, KATEC 좌표 변환, 정체 반영까지 설계대로 동작한다. 웹 + Android 단일 코드베이스로 배포 가능한 상태.

**하지만 3가지가 시급하다:**
1. **Opinet API 키 노출** — `kOpinetApiCode`가 클라이언트 코드에 하드코딩되어 웹 빌드 JS에 그대로 포함됨 (일일 1,500건 한도 탈취 가능).
2. **OSRM 공개 데모 서버 의존** — `router.project-osrm.org`는 공식 정책상 비상업·1 req/s 이하·SLA 없음. 과부하/차단 이력이 실재함.
3. **git 저장소 부재** — 버전관리가 전혀 없음. 회귀 추적·배포 롤백 불가.

**기술부채:** sqlite3_flutter_libs가 EOL(0.6.0+eol) → Android 크래시 실사례 있음. Riverpod 3에서 `StateProvider`를 legacy import로 사용. economy 엔진에 `dynamic` dispatch.

**경쟁 리스크 (가장 중요한 발견):** 오피넷 공식앱이 2026-02 v4.0.1 리뉴얼로 **"거리+가격+차량연비+평균주유량 4요소 종합 추천순"** 을 도입. Oil Checker의 핵심 가치(연비 반영 경제적 주유소 추천)가 공공 앱에 흡수됨 → 차별화 포인트 재정의 필요.

---

## 2. 검증된 구현 현황 (근거: verify-build-state.md)

| 항목 | 결과 |
|---|---|
| `flutter analyze` | 3 issues, 전부 `info` (`tool/katec_probe.dart` print만) — **`lib/` 클린** |
| `flutter test` | **66개 전부 통과** (README의 64보다 +2) |
| `flutter pub outdated` | 33개 신버전 존재 (하단 참조) |
| 빌드 산출물 | web **38.6MB / 43파일**, release APK **57.2MB** (debug 172MB), CSV 367.7KB/4,204줄 |
| git | **없음** (버전관리 부재) |

### 의존성 업그레이드 경로 (major bump만)

| 패키지 | 현재 | 최신 | 비고 |
|---|---|---|---|
| sqlite3_flutter_libs | 0.5.42 | **0.6.0+eol** | EOL — 마이그레이션 필수 (P1) |
| sqlite3 (transitive) | 2.9.4 | 3.5.1 | 3.x에서 네이티브 SQLite 자동 번들 |
| geolocator | 13.0.4 | 14.0.3 | major |
| proj4dart | 2.1.0 | 3.0.0 | major (KATEC 변환) |
| csv | 6.0.0 | 8.0.0 | major |
| drift / drift_dev | 2.31.0 | 2.34.3 / 2.34.5 | minor |
| flutter_riverpod | 3.3.2 | 3.4.2 | minor (resolvable은 3.3.2 제한) |

---

## 3. 코드 인벤토리 vs PLAN (Oil Checker PLAN.md)

### 구현됨 (동작 확인)
- Opinet 클라이언트: `aroundAll.do`(반경 내 주유소), `detailById.do`(상세) — **실제 호출은 이 2개뿐**
- KATEC↔WGS84 변환 (`katec.dart`), Opinet 예외 체계
- 3단 캐시 저장소: 신선(TTL 6h) → API → 오래된 캐시 폴백, KATEC 기반 위치 무관 캐시
- 경제성 엔진: `calculateEconomy`(절약액·우회비용·시간비용·경제성점수·isSavings), `computeDetourKm`(목적지 왕복 2배), `applyCongestion`(정체 1.5배) — **테스트 17개로 견고**
- OSRM `table` 서비스: 1회 호출로 N×N 거리/시간 행렬
- Drift DB: 차량 프로필·주유이력·주유소 캐시 (오프라인 지원)
- 화면: 홈/경제적 주유소 랭킹/주유이력/설정/차량 등록, 정체 배너
- 웹 배포: Vercel 정적 호스팅 + Opinet CORS 프록시 서버리스 함수

### 미구현 / PLAN 대비 갭
- `lowTop10.do`(최저가 TOP10), `avgSidoPrice.do`(시도별 평균), `avgSigunPrice.do`(시군구별 평균), `areaCode.do`(지역코드) — PLAN에는 있었으나 실제 호출 없음
- Opinet 공식 API 목록상 활용 가능한 무료 API 다수 미사용: 상호 검색, 최근 7일 평균, 면세유 TOP20 등

---

## 4. 리스크 & 개선 방향 (우선순위)

### 🔴 P0 — 지금 (안정성·보안·자산 보호)

**1. Opinet API 키를 클라이언트에서 제거**
- 현황: `lib/presentation/providers.dart:20` `kOpinetApiCode = 'F251228319'` 하드코딩. 웹 빌드는 JS에 그대로 포함 → 누구나 추출 가능. Android APK도 디컴파일 가능.
- 한도: 코드상 일일 1,500건 (사용자 문서에는 15,000건으로 표기 — 불일치, 확인 필요).
- 해결: Vercel 프록시(`api/opinet/[...path].js`)가 **서버측에서 키를 주입**하도록 변경. 클라이언트는 키 미보유. 프록시에 `path` 화이트리스트(`aroundAll.do`/`detailById.do`만 허용) + IP rate limit 추가. Vercel env 변수로 키 관리.
- 주의: 현재 프록시는 query string을 그대로 전달하므로 `code=...` 파라미터가 클라이언트에서 오고 있음 — 키를 서버로 옮기면 이 파라미터 제거.

**2. git 저장소 초기화 + 첫 커밋**
- 현황: `E:\OpenCode_OilMaker`도 `oil_checker\`도 git 아님. 지금까지 만든 것에 대한 이력이 없음.
- 해결: `.gitignore`(build/, .dart_tool/ 등) 작성 → `git init` → 첫 커밋. **키 제거(위 1번)를 먼저 하고 커밋**해야 키가 히스토리에 남지 않음.

**3. OSRM 라우팅 의존 재설계** (상세 비교 §5)
- 현황: `osrm_client.dart:51` `https://router.project-osrm.org` 하드코딩. 공식 정책: "1 request per second max", 데모 서버는 운영 SLA 없음, 과부하/차단 이력(issue #7162).
- 해결 옵션 (권장 순): ① **자체 OSRM 서버** (한국 extract, 동일 `table` 규격이라 코드 변경 최소 — `baseUrl` 교체만으로 가능) ② Kakao 길찾기로 전환 (N개 후보 주유소 → N콜, 쿼터 10,000/일) ③ 단기: 후보 주유소 수 축소 + 클라이언트 스로틀 + 행렬 캐시로 데모 서버 부담 경감.

### 🟠 P1 — 다음 (기술부채 정리)

**4. sqlite3_flutter_libs EOL 마이그레이션**
- 근거: 패키지가 `0.6.0+eol` (빈 껍데기, sqlite3 3.x에서 불필요). wger-project PR #1155: EOL 버전이 Android에서 `libsqlite3.so` 미번들 → **DriftRemoteException 시작 크래시** 실사례. drift 2.32.0+는 sqlite3 3.x 내장(hooks로 자동 번들).
- 절차: `pubspec`에서 `sqlite3_flutter_libs` 제거 → `drift ^2.34` + `drift_flutter`(`driftDatabase()`) → `sqlite3.wasm`(웹) 업데이트 → 회귀 테스트.
- 리스크: DB 마이그레이션(스키마 변경 아님, 라이브러리 교체)이라 기존 사용자 데이터는 보존됨. 단, 이미 출시된 앱이 없으므로 지금이 최적기.

**5. Riverpod 3 정리 (legacy import 제거)**
- 현황: `providers.dart:6` `import 'package:flutter_riverpod/legacy.dart' show StateProvider;` — Riverpod 3 공식 마이그레이션 가이드가 StateProvider를 legacy로 분리. 반패턴.
- 해결: `Notifier`/`AsyncNotifier` 기반으로 전환. 기능 변경 없음, 순수 코드 정리.

**6. economy_engine `dynamic` dispatch 제거**
- 현황: `rankByEconomy`의 `_scoreOf`가 런타임 타입 분기 — 타입 안전성 저하.
- 해결: sealed class 또는 enum 기반 정적 분기. 기존 테스트 17개가 안전망이므로 리팩터 후 그대로 통과해야 함.

### 🟡 P2 — 여유 있을 때 (최적화·확장)

**7. 빌드 크기 절감**
- 웹 38.6MB: CanvasKit wasm(~1.5MB) + 폰트가 주범. deferred import, 폰트 서브셋, 불필요 에셋 제거, wasm(dart2wasm) 평가.
- APK 57.2MB: 50MB 임계 초과 → AAB/split-per-abi로 축소 (아직 스토어 출시 전이라 AAB 전환이 정답).

**8. 경쟁 차별화 재정의** (§6 상세)
- 오피넷이 "4요소 추천"을 흡수했으므로, Oil Checker는 **"우회 경로 왕복 절약금액을 원 단위로 명확히"** 계산하는 것 + **주유이력 기반 실연비 자동 추적**(오피넷은 직접 입력만) + **목적지 기반 우회 추천**(가는 길에 들르는 주유소)으로 포지셔닝.

**9. 미구현 Opinet API 활용 검토**
- `lowTop10`(주변 최저가 TOP10)은 "전국 최저가 여행" 시나리오, `avgSidoPrice`/`avgSigunPrice`는 "이 동네가 비싸다" 판단용. UX 가치 판단 후 추가.

---

## 5. 라우팅 API 대안 비교 (OSRM 교체 검토)

| 공급자 | API | 무료 한도 | 특징 | OSRM table 대체 |
|---|---|---|---|---|
| **OSRM (자체)** | table | 무제한 | 현재 코드와 동일 규격, baseUrl만 교체 | ✅ 완벽 (N×N 행렬 1콜) |
| Kakao | 자동차 길찾기 | 10,000건/일 | 1:1 경로, CORS 제약 (프록시 필요) | △ 후보 N개 → N콜 |
| Kakao | 다중 경유지 | 5,000건/일 | 1:N 경유지 | △ |
| Kakao | 다중 출발지 | 1,000건/일 | N:1 (반대 방향) | △ |
| Naver | Directions 5 | **60,000건/월** | goal 최대 10개, **최저비용 목적지 1개만 반환** | △ (랭킹엔 N콜 필요) |
| Naver | Directions 15 | 3,000건/월 | 경유지 15 | △ |
| TMAP | 자동차 경로안내 | 1,000건/일 | 저장 24h 제한 | △ |
| TMAP | 경로 매트릭스 | **20건/일** | 진짜 행렬이지만 쿼터가 너무 작음 | ✗ |
| OSRM (데모) | table | 비공식 (1 req/s) | **현재 사용 중 — 차단/중단 리스크** | — |

**결론:** 행렬 1콜 방식(현재 아키텍처)을 유지하려면 **자체 OSRM 서버**가 유일한 정석. 그 전까지는 후보 주유소 수 축소(예: 가격 상위 10개) + 클라이언트 스로틀 + 6h 캐시(이미 있음)로 데모 서버 부담을 줄이는 임시 방안.

---

## 6. 경쟁 분석 — 오피넷 공식앱 v4.0.1 (2026-02 리뉴얼)

### 오피넷이 추가한 것 (Oil Checker와 겹침)
- **추천순 정렬**: 거리 + 가격 + 차량연비 + **평균주유량** 4요소 종합 (기존 최저가순/거리순에 추천순 추가)
- 공인연비 자동 제공(한국에너지공단) + **실연비 직접 입력** 가능
- 검색 반경 10km → **20km 확대**, 장소명 직접 검색
- 경로별 주유소 (목적지 기준) — 단, **개수 부족이 단점**: 동일 경로에 오피넷 3곳 vs 네이버지도 7곳 (IT동아 실측)
- 트래픽: 석유 최고가격제(2026-03) 시행 후 일일 최대 200만 명 — 접속 지연/대기열 발생 (공공 인프라 한계)

### Oil Checker만의 남은 차별점
1. **우회 왕복 절약금액을 원 단위로 명시** — 오피넷은 "추천"까지만, 비용/절약의 정량 비교 UX 부재
2. **주유이력 기반 실연비 자동 추적** (Drift DB) — 오피넷은 사용자가 직접 입력해야 함
3. **목적지 기반 우회 추천** — "가는 길에 들르는 주유소" 시나리오 (오피넷은 주변 위주)
4. **시간비용 + 도로정체 반영** — 오피넷 추천은 정체를 반영하지 않음
5. 오피넷의 경로별 주유소 개수 부족 → **후보 커버리지로 승부 가능**

### 전략 제안
- UI 카피에서 "추천" 대신 **"절약금액 정산"** ("이 주유소 들르면 1,420원 절약")으로 포지셔닝.
- 실연비 자동 기록을 메인 기능으로 전면화 (주유이력 화면 강화, 절약 누적 대시보드).

---

## 7. 근거 자료 (출처)

**OSRM**
- https://map.project-osrm.org/about.html (데모 서버 정책: 1 req/s, 비상업)
- https://github.com/Project-OSRM/osrm-backend/issues/7162 (2025-05 과부하/차단 이력)

**sqlite3 / drift EOL**
- https://pub.dev/packages/sqlite3_flutter_libs (0.6.0+eol, "update to 3.x of package:sqlite3")
- https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md
- https://github.com/simolus3/drift/releases/tag/drift-2.32.0 (sqlite3 3.x 마이그레이션)
- https://github.com/wger-project/flutter/pull/1155 (Android DriftRemoteException 크래시 실사례)

**Riverpod 3**
- https://riverpod.dev/docs/3.0_migration (StateProvider → legacy.dart)

**라우팅 쿼터**
- https://developers.kakao.com/docs/ko/getting-started/quota (Kakao 무료 쿼터)
- https://api.ncloud-docs.com/docs/ai-naver-mapsdirections-driving (Naver Directions 5)
- https://tmapapi.tmapmobility.com/terms.html (TMAP 무료 한도 — 경로안내 1,000/일, 매트릭스 20/일)

**오피넷 API (certkey 불일치 확인용)**
- https://www.opinet.co.kr/user/custapi/openApiInfoDtl.do?apiId=3 (aroundAll: certkey 필수 — 앱은 `code` 사용, 실측 주석 기반. 재확인 필요)
- https://www.opinet.co.kr/user/custapi/custApiInfo.do (무료/유료 API 목록)

**경쟁 (오피넷 리뉴얼)**
- https://designcompass.org/2026/06/15/opinet-app-renewal-2026/
- https://www.joongang.co.kr/article/25401269
- https://www.donga.com/news/It/article/all/20260325/133606508/1 (IT동아: 추천순 4요소, 경로별 주유소 개수 실측, 트래픽 대기열)

**Flutter 웹 최적화**
- https://flutter.dev/blog/best-practices-for-optimizing-flutter-web-loading-speed (CanvasKit ~1.5MB, deferred imports)

---

## 8. 다음 액션 (제안)

| 순서 | 작업 | 담당 | 리스크 |
|---|---|---|---|
| 1 | 키를 Vercel env + 프록시 주입으로 이동, 프록시 화이트리스트 | — | 낮음 (구조 변경) |
| 2 | git init + .gitignore + 첫 커밋 (키 제거 후) | — | 낮음 |
| 3 | sqlite3 3.x + drift 2.34 + drift_flutter 마이그레이션 | — | 중간 (회귀 테스트 필수) |
| 4 | Riverpod legacy import 정리 (Notifier 전환) | — | 낮음 |
| 5 | economy_engine dynamic 제거 | — | 낮음 (테스트 17개 안전망) |
| 6 | OSRM: 후보 축소 + 스로틀 (임시) → 자체 서버 (정식) | — | 중간 |
| 7 | 경쟁 대응: 절약금액 정산 UX + 실연비 자동 기록 강화 | — | 중간 (제품 결정 필요) |
| 8 | AAB 전환 + 웹 번들 축소 | — | 낮음 |
