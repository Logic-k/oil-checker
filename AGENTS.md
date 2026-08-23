# AGENTS.md — Oil Checker 작업 가이드 (Codex/Claude 등 AI 에이전트용)

> 이 문서는 에이전트가 이 저장소에서 작업을 **이어서** 시작할 때 필요한 모든 맥락을 담는다.
> 상세한 실행 절차는 `oil_checker/README.md`, 설계 전체는 `Oil Checker PLAN.md`를 읽을 것.

## 1. 프로젝트 개요

**Oil Checker** — "기름값을 금값처럼!" 오피넷(한국석유공사) 유가정보 + 내 차 연비 + 경로 우회거리를 결합해
**절약금액(원) 기준으로 가장 경제적인 주유소를 자동 추천**하는 Flutter 앱.

- 스택: Flutter (웹 + Android 단일 코드베이스), Riverpod, Drift(SQLite), OSRM
- 배포: 웹은 Vercel (정적 호스팅 + Opinet CORS 프록시 서버리스 함수)
- Flutter 3.41.x / Dart 3.11.x 기준

## 2. 저장소 구조

```
oil_checker/            # Flutter 앱 (메인 코드베이스)
  lib/
    core/opinet/        # Opinet API 클라이언트·모델·예외
    core/coordinate/    # KATEC(EPSG:5174) ↔ WGS84 변환 (Opinet은 KATEC 좌표계!)
    core/traffic/       # 도로 혼잡도 반영
    data/car_spec/      # 차량 제원 로더 (CSV 임베드)
    data/db/            # Drift DB (차량 프로필 / 주유 이력 / 주유소 캐시)
    data/opinet/        # 저장소 — 3단 TTL 캐시 + 오프라인 폴백
    data/routing/       # OSRM table 서비스 (N×N 거리/시간 행렬)
    domain/economy/     # 경제성 엔진 (절약액·우회비용·경제성점수) ⭐ 핵심
    presentation/       # 화면 (홈/경제적 주유소 랭킹/주유 이력/설정) + providers
  api/opinet/[...path].js   # Vercel 서버리스 CORS 프록시 (키 서버측 주입)
  tool/opinet_proxy.dart    # 로컬 개발용 프록시 (정적 서빙 + /opinet 중계, 포트 8899)
  scripts/                  # Vercel 빌드 스크립트 (Flutter SDK 설치 + web 빌드)
  test/                     # flutter test 대상
# 루트의 나머지:
Oil Checker PLAN.md    # 앱 설계 전문 (API 스펙, 캐시 전략, 로드맵)
# Oil Checker.md       # 초기 요구사항 문서
*.yml (루트)           # Playwright UI 검증 스냅샷 (탭/배지/네비 구조 확인용)
screenshots/           # UI 검증 스크린샷
Opinet_API_Free.pdf    # Opinet 무료 API 공식 가이드
.opencode/omo          # 리서치 아카이브: .omo/ulw-research/<날짜>/SYNTHESIS.md — 구현 현황 분석 + 개선 방향 리서치 결과
```

## 3. 현재 상태 (2026-08-23 기준, 검증된 사실)

| 항목 | 상태 |
|---|---|
| MVP 기능 | ✅ 완성 — 주변 주유소 찾기, 차량 프로필, 경제성 랭킹, 주유 이력, 설정 |
| 테스트 | ✅ README 기준 69개 통과 (`flutter test`) |
| 정적 분석 | ✅ `lib/` analyze 0 이슈 (tool/katec_probe.dart의 print info만 존재) |
| 웹 배포 | ✅ Vercel 배포 구축 완료 (`vercel.json` + `api/opinet` 프록시) |
| Android | ✅ debug/release APK 빌드 절차 확립 (에뮬레이터 프록시 우회법 포함) |
| API 키 보안 | ✅ 소스 평문 제거 — `String.fromEnvironment('OPINET_API_CODE')` 주입 방식 |
| 버전관리 | ✅ 2026-08-23 GitHub 업로드로 시작 (`Logic-k/oil-checker`) |

### 완료된 설계 검증
- Opinet API 인증 파라미터는 `code` (`certkey` 아님 — 실측 확인, 잘못 쓰면 HTTP 200 + 빈 배열)
- KATEC ↔ WGS84 변환 구현 및 PoC 완료 (`lib/core/coordinate/katec.dart`)
- 일일 호출 예산 ~110건/일 (한도 1,500건의 7%) — 6시간 TTL 캐시로 달성

## 4. 개발 명령 (oil_checker/ 디렉토리에서)

```powershell
# 웹 개발 (프록시 필수 — Opinet은 CORS 미제공)
$env:OPINET_API_CODE="<키>"; dart run tool/opinet_proxy.dart 8899   # 터미널 1
flutter build web                                                     # 터미널 2 → http://localhost:8899

# Android (에뮬레이터 — 외부 네트워크 차단 환경이면 호스트 프록시 경유)
dart run tool/opinet_proxy.dart 8899
flutter build apk --debug --dart-define=OPINET_BASE_URL=http://10.0.2.2:8899/opinet

# 검증 (커밋 전 반드시)
flutter analyze   # lib/ 0 issues 목표
flutter test      # 전부 통과 목표

# Vercel 배포
vercel --prod     # oil_checker/ 에서. 커밋 push 시 자동 배포도 가능
```

## 5. 절대 지켜야 할 제약 (실수하기 쉬운 것들)

1. **API 키 평문 금지** — 소스/문서 어디에도 키를 하드코딩하지 않는다.
   웹: Vercel 환경변수 `OPINET_API_CODE` (서버리스 프록시가 서버측 주입).
   네이티브: `--dart-define=OPINET_API_CODE=...`.
2. **좌표계 함정** — Opinet은 WGS84가 아니라 **KATEC(EPSG:5174)**. GPS→KATEC 변환 후 호출,
   KATEC→WGS84 변환 후 지도 표시. 변환은 `katec.dart` 사용 (직접 구현 금지).
3. **호출 한도** — 일일 1,500건. 동일 좌표 재호출 금지. 캐시(TTL 6h) 우회하는 코드 추가 금지.
4. **CORS** — 브라우저에서 Opinet 직접 호출 불가. 반드시 `/opinet` 프록시 경로 사용.
5. **DB 직접 주입 시 한글 깨짐** — sqlite3 CLI의 CP949 문제. 에뮬레이터 검증엔 ASCII 모델명 권장.

## 6. 다음 작업 우선순위 (근거: .omo/ulw-research/20260815-221929/SYNTHESIS.md)

P1 (긴급):
- [ ] **sqlite3_flutter_libs EOL 마이그레이션** — 0.5.x는 EOL, Android 크래시 실사례. 0.6.x/sqlite3 3.x로 이전.
- [ ] **OSRM 데모 서버 의존 제거** — `router.project-osrm.org`는 SLA 없음(비상업·1req/s). 자체 OSRM 인스턴스 또는 상용 라우팅 API 전환 검토.

P2 (기술부채):
- [ ] Riverpod 3에서 legacy `StateProvider` import 제거
- [ ] economy 엔진의 `dynamic` dispatch 제거 (타입 안정화)
- [ ] 의존성 major bump: proj4dart 3.0, geolocator 14, csv 8 (KATEC 회귀테스트 선행)

P3 (제품):
- [ ] 차별화 재정의 — 오피넷 공식앱 v4.0.1(2026-02)이 "연비 반영 종합 추천" 흡수. PLAN §2.2 후순위(OBD 연동, 즐겨찾기/알림, 고속도로 휴게소 유가) 또는 UX 우위로 대응 방안 결정.
- [ ] 미구현 Opinet 엔드포인트 활용: lowTop10(최저가 TOP20), avgSidoPrice(시도별 평균) 등 — PLAN §3.1 참조

## 7. 문서 관계도

- 요구사항 원본: `# Oil Checker.md`
- 설계 전문(스펙·전략·로드맵): `Oil Checker PLAN.md`
- 실행 매뉴얼(빌드·배포·디버깅): `oil_checker/README.md`
- 현황 분석 + 개선 리서치: `.omo/ulw-research/20260815-221929/SYNTHESIS.md` (+ `verify-build-state.md`)
- UI 구조 스냅샷(과거 검증): 루트 `*.yml`

## 8. 커밋 규칙

- 한국어 커밋 메시지, Conventional Commits 접두어 사용 (예: `feat: ...`, `fix: ...`, `docs: ...`)
- 빌드 산출물(`build/`, `.dart_tool/`, `android/.gradle/`)은 커밋 금지 (.gitignore 유지)
- API 키·개인정보 커밋 금지
