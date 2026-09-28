# oil_checker

주유소 가격 비교 + 경제적 주유소 추천 앱 (Flutter 단일 코드베이스 — 웹/Android 병행)

## 핵심 아키텍처

**Opinet(한국석유공사 유가정보) API 접근 방식** — 플랫폼별로 다르다:

| 플랫폼 | baseUrl | CORS 처리 |
|---|---|---|
| 웹 (개발) | `/opinet` (같은 origin) | `tool/opinet_proxy.dart` 로컬 프록시 (8899) |
| 웹 (배포) | `/opinet` (같은 origin) | `api/opinet/[...path].js` Vercel 서버리스 함수 |
| Android (기기) | `https://www.opinet.co.kr/api` 직접 호출 | 불필요 |
| Android (에뮬레이터) | `http://10.0.2.2:8899/opinet` (호스트 프록시 경유) | `--dart-define=OPINET_BASE_URL` |

Opinet API는 CORS 헤더를 제공하지 않아 **브라우저 직접 호출이 차단**된다.
따라서 웹은 같은 origin의 프록시 경로(`/opinet/*`)를 통해 중계한다.
네이티브는 프록시 없이 직접 호출한다.

### Opinet API 키 보안 (중요)

API 키는 소스코드에 평문으로 두지 않는다. 플랫폼별로 키 주입 경로가 다르다:

| 플랫폼 | 키 주입 방법 | 키 위치 |
|---|---|---|
| 웹 (배포) | Vercel 환경변수 `OPINET_API_CODE` → 프록시가 서버측 주입 | JS 번들에 **미포함** |
| 웹 (개발) | `api-keys.json` 파일 또는 `OPINET_API_CODE` 환경변수 → 로컬 프록시가 서버측 주입 | JS 번들에 **미포함** |
| 네이티브 (Android) | `--dart-define-from-file=api-keys.json` 빌드 시 주입 | dart-define (빌드 인자) |
| 에뮬레이터 (프록시 경유) | 프록시가 서버측 주입 (키 불필요) | 미포함 |

**로컬 키 파일 `api-keys.json`** (gitignored — 커밋되지 않는 로컬 전용 파일):

```json
{
  "OPINET_API_CODE": "<키>"
}
```

```powershell
# 네이티브 빌드 시 키 주입 (실기기/에뮬레이터 직접 호출용)
flutter build apk --debug --dart-define-from-file=api-keys.json

# 로컬 프록시 실행 시 (웹 개발 / 에뮬레이터 경유) — api-keys.json을 자동으로 읽는다
dart run tool/opinet_proxy.dart 8899

# 환경변수는 api-keys.json보다 우선
$env:OPINET_API_CODE="<키>"; dart run tool/opinet_proxy.dart 8899
```

> 참고: Opinet API 키는 일일 1,500건 한도, 무료 인증 파라미터는 `code`.

- 좌표: Opinet은 WGS84가 아닌 **KATEC(EPSG:5174)** 사용 — `lib/core/coordinate/katec.dart`가 변환

## 개발 환경

- Flutter SDK (웹/Android 활성화됨)
- Android SDK + 에뮬레이터 (AVD: `QA_Device`, `OilTest`)

### 에뮬레이터 네트워크 제약 (중요)

에뮬레이터가 외부 인터넷으로 나가지 못하는 환경(방화벽 등)에서는
Android 앱이 Opinet에 **직접 접근할 수 없다**. 해결책:

```powershell
# 1. 호스트에서 로컬 프록시 실행
dart run tool/opinet_proxy.dart 8899

# 2. 에뮬레이터용 APK 빌드 — 호스트 프록시(10.0.2.2)를 baseUrl로 지정
flutter build apk --debug --dart-define=OPINET_BASE_URL=http://10.0.2.2:8899/opinet
```

실기기에서는 이 옵션 없이 빌드하면 된다 (직접 호출).

## 로컬 개발

### 웹

```powershell
# 터미널 1: 프록시 (정적 서빙 + /opinet 중계)
dart run tool/opinet_proxy.dart 8899

# 터미널 2: 웹 빌드 후 프록시로 접속
flutter build web
# → http://localhost:8899 에서 접속
```

또는 개발 중 `flutter run -d chrome` (프록시 경유가 아니라 CORS 오류가 날 수 있음 —
빌드 후 프록시로 확인하는 것이 정확하다).

### Android (에뮬레이터)

```powershell
# AVD 부팅
flutter emulators --launch QA_Device

# 빌드 + 설치 + 실행
flutter run -d emulator-5554   # 또는 dart-define 필요 시 위 "에뮬레이터 네트워크 제약" 참고
```

## 웹 배포 (Vercel)

정적 호스팅 + Opinet CORS 프록시 서버리스 함수를 함께 배포한다.

- `vercel.json` — 빌드 설정(Framework Preset: Other) + `/opinet/:path*` rewrite
- `scripts/install_flutter.sh` — 빌드 환경에 Flutter SDK 설치 (`$HOME/flutter`, repo 오염 방지)
- `scripts/build_flutter.sh` — `flutter build web --release` (산출물 `build/web`)
- `api/opinet/[...path].js` — Opinet API 중계 함수 (`https://www.opinet.co.kr/api/*`)

### 배포 절차

```powershell
# 1. Vercel CLI 설치 & 로그인
npm i -g vercel
vercel login

# 2. 배포 (프로젝트 루트 oil_checker/에서)
vercel --prod
```

GitHub 연결 시 커밋마다 자동 배포된다. 배포 설정(설치/빌드 명령)은
`vercel.json`에 고정되어 있어 대시보드 설정과 충돌하지 않는다.

### 로컬에서 서버리스 함수 테스트

```powershell
vercel dev   # http://localhost:3000 — /opinet/* 프록시 포함 전체 동작 확인
```

## Android 앱 (APK)

```powershell
# 디버그 APK (실기기/에뮬레이터)
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# 릴리스 APK (서명 설정 후)
flutter build apk --release
```

## 테스트 / 정적 분석

```powershell
flutter analyze   # 0 issues (tool/katec_probe.dart의 print info 제외)
flutter test       # 106 tests 통과 (KATEC 8건, 연료 추론·절약 기준가·DB 마이그레이션 포함)
```

## 프로젝트 구조

```
lib/
  core/opinet/       # Opinet API 클라이언트/모델 (KATEC 좌표, 예외)
  core/coordinate/   # KATEC ↔ WGS84 변환
  core/traffic/      # 도로 혼잡도 (예상 시간 반영)
  data/car_spec/     # 차량 제원 로더
  data/db/           # Drift DB (차량 프로필, 주유 이력, 주유소 캐시)
  data/opinet/       # 저장소 (TTL 캐시 + 오프라인 폴백)
  data/routing/      # OSRM 경로 계산
  domain/economy/    # 경제성 엔진 (경유지 왕복 거리 등)
  presentation/      # Riverpod providers + 화면 (홈/경제적 주유소/주유 이력/설정)
tool/opinet_proxy.dart  # 로컬 개발용 프록시 (정적 서빙 + /opinet 중계)
api/opinet/[...path].js # Vercel 서버리스 CORS 프록시
scripts/               # Vercel 빌드 스크립트
```

## 주의사항

- **Opinet 일일 1,500건 한도** — 클라이언트는 6시간 TTL 캐시(`opinet_repository.dart`)로 절약,
  배포 프록시는 CDN 캐시(s-maxage=600)로 2차 절약.
- 가격 갱신 시각: 01/02/09/12/16/19시.
- 에뮬레이터 GPS는 `adb emu geo fix <경도> <위도>`로 서울 등 원하는 위치로 설정 가능.
- DB 직접 주입 시 sqlite3 CLI의 CP949 인코딩 문제로 한글 데이터가 깨질 수 있다.
  (에뮬레이터 검증 시 ASCII 모델명 사용 권장)
