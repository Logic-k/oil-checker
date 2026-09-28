# Track C — Flutter 프로덕트 디자인·엔지니어링 리서치

- 세션: 20260928-214100 · 작성/확인일: **2026-09-28**
- 대상: `E:\OpenCode_OilMaker\oil_checker` — Flutter 주유 절약 앱 "Oil Checker"
- 로컬 SDK: Flutter **3.41.5 / Dart 3.11.3** · 원격 개발 환경 lock: Flutter ≥3.44 / Dart ≥3.12
- 범위: 디자인 디벨롭 방법 · 최고 수준 Flutter 앱 사례 · 2025~2026 비주얼 기술 · 한국 프로덕트 원칙 · 지도/마커/타이포/데이터 시각화 · 앱 밖 접점 · 접근성 — **모션은 선행 리서치(20260925-193225 / oil-motion SKILL)와 중복하지 않고 "그 다음 단계" 관점만** 다룬다.

> **모션 리서치와의 경계.** 스프링 토큰, 카운트업, OpenContainer 카드→상세, 마커 팝인·펄스, Pressable 터치감, 스태거, reduceMotion 헬퍼 등은 이미 `oil-motion` 스킬에 실행 스펙으로 존재하고 코드(`app_motion.dart`, `motion_widgets.dart`, `splash_intro.dart`, `drive_island.dart`)에 일부 반영됨. 본 문서는 **정적 비주얼 시스템(색·타이포·지도 렌더링·데이터 시각화·아이콘·에셋·다크모드·접근성·앱 밖 접점)** 과, 그 위에서 모션이 "다음 단계"로 어디에 얹힐지를 다룬다.

---

## 1. 요약 (TL;DR)

**Oil Checker의 정적 디자인 언어는 이미 상위권이다.** 잉크(#12181F)+골드(#FFB020) 절제된 팔레트, 헤어라인 보더, 거대 숫자 히어로, 브랜드 컬러 스트라이프, tabular figures — 토스/당근식 "숫자 중심·신뢰형" 방향을 정확히 밟고 있다(근거: `app_theme.dart`, `station_widgets.dart`, 스크린샷 02·03·06b). AI슬롭(보라 그래디언트·글래스 남용)은 없다.

**가장 큰 갭은 "지도 렌더링 품질"이다.** 홈·상세는 `flutter_map` + **래스터 OSM 타일**(`tile.openstreetmap.org`)을 쓰는데(`home_screen.dart:370-371`, `station_detail_screen.dart:113-115`), 반면 드라이브 모드는 이미 **MapLibre 벡터(OpenFreeMap dark, 3D 건물)** 다(`drive_screen.dart:8,26,237`). 즉 앱 안에 지도 스택이 둘로 갈려 있고, 정작 사용자가 가장 오래 보는 홈 지도가 가장 낮은 품질이다(래스터 = 흐릿·회전 라벨 안 됨·다크모드 없음·마커 대비 낮음, 스크린샷 05). **홈/상세를 벡터 타일로 통일하는 것이 단일 최대 임팩트.**

**두 번째 갭은 폰트다.** `app_theme.dart`에 `fontFamily: 'Pretendard'`가 **주석 처리**돼 있어 현재 플랫폼 기본 폰트(웹=Roboto/시스템, 한글은 Noto 대체)로 렌더된다. Pretendard 번들만으로 한글 자간·행간·숫자 정렬이 즉시 프리미엄해진다.

**세 번째는 데이터 시각화 부재.** 앱의 킬러 가치가 "N원 절약"인데 주유 이력·가격 추세를 **차트로 보여주는 화면이 없다**(스파크라인 draw-on은 모션 스킬에서 계획만). `fl_chart`로 "이번 달 절약 누적", "내 주유 단가 추이" 같은 히어로 차트를 넣으면 오피넷 공식앱 대비 명확한 차별화가 된다.

**기술 지형(2026):** M3 Expressive는 **아직 공식 미탑재**(flutter/flutter#168813, "not planned/paused") — 대신 **Flutter 3.47(2026-08)에서 material_ui/cupertino_ui가 독립 패키지 1.0으로 분리**되어 여기서 개발될 예정. Impeller는 iOS·Android 양쪽 기본. iOS 26 Liquid Glass 공식 지원 없음(커뮤니티 패키지/네이티브 플랫폼뷰). 이 앱은 **현 SDK 3.11에 맞춰 보수적으로**, 원격 lock(≥3.44)에서만 신규 패키지 채택을 검토해야 한다.

---

## 2. 최고 수준 Flutter 앱 사례 분석 (2024~2026)

출처: flutter.dev/showcase (확인 2026-09-28) 및 각 사례 페이지.

| 앱 | Flutter 사용 확인 | 뛰어난 점 / 구현 기법 | Oil Checker 시사점 |
|---|---|---|---|
| **Wonderous** (gskinner, 오픈소스 데모) | ✅ flutter.gskinner.com/wonderous | "디자인 벤치마크"의 표준. 풀블리드 이미지, 강한 타이포 스케일, 부드러운 페이지 전환, 커스텀 컬러 테마 per-wonder. 코드 공개 → 구조·모션·테마 학습 자료 | 히어로 이미지/타이포 위계·per-context 테마(주유 유종별 컬러) 학습 |
| **Nubank** | ✅ /showcase/nubank | 4,800만+ 사용자 핀테크. 극단적 미니멀·숫자 중심·보라 단색 브랜드. "복잡함을 제거한 금융 UI" | 숫자 히어로 + 단색 브랜드 절제 = Oil Checker 방향과 동일 |
| **Google Pay / Wallet** | ✅ /showcase/google-pay (레거시 170만 줄 → 단일 코드베이스) | 금액 카드, 부드러운 리스트, 결제 성공 모먼트 | 금액 표기·성공 모먼트 벤치마크 |
| **BMW / Toyota** | ✅ BMW(/showcase/bmw), Toyota 인포테인먼트(2026-05) | 차량 앱·**차량 내 인포테인먼트**를 Flutter로. 대화면/저사양 GPU 대응, 다크 기본 | 드라이브 모드·(장기) 카 디스플레이의 현실적 근거 |
| **Kakao Mobility** | ✅ /showcase/kakao-mobility (2024-09) | 국내 모빌리티. 지도+실시간+한글 밀도 높은 UI | 국내 지도 UX·한글 라벨 밀도 벤치마크 |
| **SoFi** | ✅ /showcase/sofi (250만+ 줄) | 금융 슈퍼앱. 대규모 디자인 시스템 운영 | 토큰화·컴포넌트화 규율 |
| **NotebookLM / LG webOS / Universal Studios / Headspace** | ✅ 각 showcase | NotebookLM(4.8★, 7개월), LG 차세대 webOS, Universal 테마파크, Headspace(명상 부드러운 비주얼) | 앰비언트/캄 비주얼·대화면 대응 사례 |

**핵심 교훈:** 최고 사례들의 공통점은 화려함이 아니라 (1) **강한 타이포 위계**, (2) **콘텐츠 풀블리드**(지도·이미지가 화면을 채움), (3) **절제된 단색 브랜드 + 1개 액센트**, (4) **성공/핵심 모먼트에만 집중된 모션**이다. Oil Checker는 1·3·4는 이미 갖췄고, **2(지도 풀블리드 품질)** 가 약하다.

---

## 3. 2025~2026 Flutter 디자인 기술 지도

> 버전은 확인일(2026-09-28) 기준 pub.dev/GitHub 표기값. **현 로컬 SDK는 3.11이므로 상당수 최신 패키지는 원격 lock(≥3.44)에서만 채택 가능**하다.

### 3.1 렌더링·모션·디자인 시스템 기반

| 기술/패키지 | 최신(확인일) | SDK 제약 | 용도 | Oil Checker 채택 판정 |
|---|---|---|---|---|
| **Impeller** (엔진) | 2026 기준 iOS·Android **기본** | 자동(API29+ Vulkan, 미만은 GL 폴백) | 셰이더 사전컴파일 → first-run jank 제거 | ✅ 자동 수혜. 셰이더/블러 쓸 근거가 됨 |
| **material_ui / cupertino_ui** (독립 패키지) | **1.0** (Flutter 3.47, 2026-08) | ≥3.47 (원격 lock 초과) | Material/Cupertino가 SDK에서 분리, 주간 릴리스, 마이그레이션 `dart fix --code=migrate_design_widgets`. **M3 Expressive는 여기서 개발 예정** | 🔸 **관망**. 현 SDK 미해당. 3.47+ 올린 뒤 검토 |
| **M3 Expressive** (스펙) | 공식 Flutter **미탑재/보류** (#168813) | — | 스프링 모션·강조 타이포·확장 셰이프·비비드 컬러 | ⚠️ 공식 대기. 커뮤니티 `material_3_expressive`(비공식)만 존재 → 프로덕션 의존 금지 |
| **FragmentProgram** 셰이더 | SDK 내장(GLSL→`.frag`) | 현 SDK OK | 커스텀 그라디언트/글로우/노이즈. Impeller로 jank 없음 | 🔸 선택 — 골드 히어로 배경 글로우 등 절제 사용 |
| **Rive** (`rive` + `rive_native`) | Flutter 런타임 **0.15** | **최소 Flutter 3.32** | 스테이트머신 인터랙티브 벡터·성공 애니메이션 | 🔸 원격 lock에서만. 저장 성공/빈 상태 1회용 |
| **Lottie** (`lottie`) | 활발 유지 | 현 SDK OK | JSON 애니메이션(빈 상태·성공) | 🔸 선택 — 에셋 제작 필요 |
| **flutter_animate** | 유지보수 모드(커밋 뜸) | 현 SDK OK | 선언형 이펙트 체이닝 | ⚠️ 핵심 경로 금지, 장식만 |
| `animations` | **2.2.0**(현재 채택) | 3.0.0은 Dart≥3.12 | FadeThrough/OpenContainer/SharedAxis | ✅ 유지(pubspec에 2.2.0 고정 확인) |

### 3.2 지도

| 기술/패키지 | 최신(확인일) | SDK/과금 | 용도 | Oil Checker 채택 판정 |
|---|---|---|---|---|
| **flutter_map** | **8.x**(현재 채택) | 무료 | 타일 지도 + 마커 위젯 레이어 | ✅ 유지 — 홈/상세 |
| **벡터 타일**: `vector_map_tiles`(greensopinion) + `vector_map_tiles_pmtiles`(josxha) | 활발 | 무료 | flutter_map에 MVT 벡터·GPU 렌더·PMTiles | ⭐ **강력 채택 후보** — 홈/상세 래스터→벡터 전환의 핵심 |
| **OpenFreeMap** 스타일(positron/bright/dark) | 유지(하지만 OpenMapTiles 업스트림 스타일은 abandoned → OpenFreeMap 자체 포크가 사실상 표준) | 무료·키 불필요 | positron(라이트)·dark 벡터 스타일 | ⭐ 채택 — 드라이브 모드가 이미 OpenFreeMap dark 사용 중 → 홈도 positron으로 통일 |
| **Protomaps** (PMTiles) | API 제공 | 무료 티어/자가호스팅 | 단일 파일 벡터 타일, 오프라인 유리 | 🔸 대안 — 자가 타일/오프라인 로드맵용 |
| **flutter_map_animations** | **0.10.0**(현재 채택) | 무료 | 카메라 플라이·애니메이션 마커 | ✅ 유지 |
| **flutter_map_marker_cluster** (lpongetti) | 활발 | 무료 | 애니메이션 클러스터(다수 마커) | 🔸 채택 검토 — 후보 축소 정책과 병행 |
| **flutter_map_supercluster** (rorystephenson) | 활발 | 무료 | 고성능 클러스터(애니메이션↓ 속도↑) | 🔸 대안 — 마커 수가 많아지면 |
| **maplibre_gl** (`maplibre_gl` 0.27.x, 현재 드라이브 모드) | 유지(구 fork) | 무료 | 3D·벡터·기울임. 웹은 GL JS | ✅ 드라이브 모드 유지 |
| **flutter-maplibre**(josxha, 신규 federated) | **0.3.x**(2026 활발) | 무료·vendor-neutral | 차세대 MapLibre 바인딩(구 gl 대비 유지 활발) | 🔸 드라이브 모드 차기 이전 후보(원격 lock에서) |
| **mapbox_maps_flutter** | v11.31 (v3 pre-release=웹 지원) | **MAU 과금** · Standard 3D/조명 | Standard 벡터·3D 지형·동적 조명 프리셋 | ❌ 과금 — 무료 정책·예산과 충돌. 채택 안 함 |
| **flutter_naver_map**(비공식, note11g) | 활발(NCP 신규 인증 대응) | Naver Cloud 키 필요 | 국내 최적 한글 라벨·POI | 🔸 국내 가독성 필요 시. 키·약관 관리 부담 |
| **kakao map**(kakaomap_webview 등) | WebView 위주 | Kakao 키 | 국내 지도·길안내 연동 | 🔸 이미 "카카오맵으로 길안내" 딥링크 사용 중(스크린샷 07) — 지도 렌더 자체는 부담 |

### 3.3 타이포·아이콘·데이터 시각화

| 기술/패키지 | 최신(확인일) | SDK/라이선스 | 용도 | Oil Checker 채택 판정 |
|---|---|---|---|---|
| **Pretendard** | 활발 · **OFL** · Variable + dynamic subset | 폰트 번들 | 한글/라틴 통합 네오그로테스크. Inter+Source Han Sans+M+ 기반 | ⭐ **즉시 채택** — `app_theme.dart`의 주석 해제 + 폰트 번들. 서브셋으로 용량 관리 |
| **tabular figures** (`FontFeature.tabularFigures()`) | SDK 내장 | 현 SDK OK | 숫자 세로 정렬(가격·절약액) | ✅ 이미 마커·카드에 적용됨(`station_widgets.dart`). 히어로/차트/이력에도 확대 |
| **fl_chart** (imaNNeo) | 활발 · Line/Bar/Pie/Scatter/Radar/Candlestick | 현 SDK OK(버전 확인 필요) | 절약 누적·단가 추이·유종별 비교 | ⭐ **채택** — 데이터 시각화 부재 해소의 핵심 |
| **graphic** (grammar-of-graphics) | 활발 | 현 SDK OK | 선언형 통계 그래픽 | 🔸 대안 — fl_chart로 충분하면 불필요 |
| **material_symbols_icons** (timmaffett) | **2.960**(2026-07, 4264개) | 현 SDK OK | Material Symbols 가변 아이콘(weight/fill/grade) | 🔸 채택 검토 — 현재 기본 Material 아이콘 대비 톤 통일·가변 축 |
| **phosphor_flutter** (phosphor-icons) | 활발 | 현 SDK OK | 얇고 일관된 아이콘 패밀리(6 weight) | 🔸 대안 — 브랜드 톤(얇은 라인)에 맞으면. **한 세트만 통일** 원칙 |

### 3.4 앱 밖 접점

| 기술/패키지 | 최신(확인일) | 제약 | 용도 | 판정 |
|---|---|---|---|---|
| **home_widget** (ABausG) | 활발 | **위젯 UI는 네이티브 코드로 작성**(Flutter가 위젯을 그리지 못함), 데이터 브리지만 제공 | 홈 화면 "오늘 최저가/절약" 위젯 | 🔸 Phase 후반 — Android/iOS 네이티브 위젯 별도 작업 필요 |
| **flutter_carplay** (oguzhnatly 등) | 유지(포크 다수) | CarPlay 중심, Android Auto는 부분 | 차량 내 최저가 리스트·핀 | 🔸 장기 — 안전 UX·심사 부담. Toyota/BMW 사례로 방향성만 |
| **googlemaps/flutter-navigation-sdk** | Android Auto base screen 제공 | Google Maps 종속 | 내비 화면 | ❌ 정책·종속 |
| **flutter_local_notifications** (관례) | — | — | 최저가 변동·목적지 근처 알림 디자인 | 🔸 알림 카피/디자인 대상 |

---

## 4. 한국 프로덕트 디자인 원칙 (벤치마크)

출처: toss.tech/article/interaction(2023, 확인 2026-09-28), tossmini-docs.toss.im(TDS), github.com/daangn/seed-design.

- **토스 TDS.** 색상 시스템을 "개발자·디자이너 공통 이름"으로 토큰화(예: `grey`, `blue` 스케일)해 일관 UI를 쉽게 구현. Oil Checker의 `AppColors`(의미 기반 네이밍: `best`/`saving`/`traffic*`)는 이미 같은 철학 → **여기에 스케일(50~900)과 다크 매핑 토큰을 더 촘촘히**.
- **토스 인터랙션 팀 원칙(Simplicity23):**
  1. **인터랙션 = 정보 전달 도구** (예뻐지기가 아니라 이탈률/전환율 지표 개선). "대출 심사 로딩을 실제 상품 노출로 바꿔 신뢰↑·이탈↓" → Oil Checker: 로딩 스켈레톤을 "가격 갱신 중" 정보로 활용(이미 시머 있음).
  2. **터치 이펙트부터.** 회색 리플→"눌리는" 모션이 전사 반응을 바꿈 → oil-motion의 Pressable이 정확히 이 지점.
  3. **모션의 눈속임.** 실제 리스트 애니메이트 대신 레이어를 띄워 한 화면처럼 → 공수↓.
  4. **모션 시스템화.** easing을 토큰(`bezier.expo`, `spring.quick`)으로, 플랫폼 공통 스펙(Rally) → Oil Checker의 `app_motion.dart` 토큰과 동형.
- **당근 SEED Design(오픈소스, daangn/seed-design).** `@seed-design/design-token`(파운데이션) + `stylesheet` + `icon` 구조. **토큰→스타일시트→아이콘의 3층 분리**가 참고점. (React 기반이라 코드 직접 이식은 불가, **구조·네이밍 철학만** 차용.)
- **공통 한국 프로덕트 문법(토스/당근/뱅크샐러드):**
  - **숫자가 주인공** — 금액을 가장 크게, 굵게, tabular로. (Oil Checker `+18,097원` 히어로는 정확히 이 문법 — 스크린샷 02·06b.)
  - **해요체 카피** — "지금 도로 상황이 반영됐어요", "N원 아껴요"(이미 사용 중, 스크린샷 05·08c). 명령형/딱딱한 한자어 지양.
  - **신뢰 표현** — 근거를 함께 보임("우회비용 빼고도 1회당 N원 이득", "L당 545원 저렴"). Oil Checker는 이 근거 노출이 강점 → 유지·강화.

---

## 5. Oil Checker 디자인 디벨롭 방향

각 제안에 **현재 코드 위치**와 **스크린샷 근거**를 명시. 모션 세부는 oil-motion 스킬 참조(중복 회피).

### 5.1 비주얼 아이덴티티 — "이미 좋다, 토큰을 촘촘히"
- **현재:** `AppColors`(ink/best/saving/brand/traffic) — 의미 기반 팔레트 잘 잡힘(`app_theme.dart:15-79`). 시드=골드, primary=ink(라이트)/gold(다크)로 M3 스킴 파생.
- **디벨롭:**
  1. **Pretendard 번들.** `app_theme.dart`의 `// fontFamily: 'Pretendard'`(약 `_base` 내부, 주석) 해제 + `pubspec` fonts 등록 + `assets/fonts/`에 서브셋. **가장 낮은 공수·가장 높은 체감**(한글 자간/행간/숫자 정렬 즉시 개선). Variable 축을 쓰면 w600/w700/w800/w900을 단일 파일로.
  2. **컬러 스케일 토큰화.** `best`/`saving`을 단일 값이 아니라 50~900 스케일 + 다크 대응쌍으로(SEED/TDS 방식). 예: 골드 펄스·배지·히어로 배경이 같은 계열의 다른 명도를 쓰도록.
  3. **온도/의미 색 유지.** trafficSmooth/Moderate/Heavy(#0E9F6E/#F5A524/#E5484D)는 색맹 대비 위해 **아이콘/텍스트 병기**(§5.7).

### 5.2 지도/마커 시스템 — **최우선**
- **현재:** 홈·상세 = flutter_map **래스터 OSM**(`home_screen.dart:370-371`, `station_detail_screen.dart:113-115`); 드라이브 = MapLibre **벡터 OpenFreeMap dark 3D**(`drive_screen.dart:8,26,237`). 마커 = `PriceMarker`(가격 pill+tail, best=골드+주유아이콘, tabular figures) + `BrandBadge`(브랜드 컬러 워드마크) (`station_widgets.dart`). 스크린샷 02·05.
- **문제점(스크린샷 05 근거):**
  - 래스터 타일이 흐릿하고 라벨 밀도가 높아 흰색 가격 pill과 대비가 약함 → 가격 비교 가독성↓.
  - 다크 모드 지도 없음(래스터는 라이트만).
  - 마커 다수 시 겹침(충돌 회피/클러스터 없음) — 스크린샷 05에서 남산 일대 pill 4개 이미 겹침.
  - best가 아닌 마커는 브랜드 컬러가 안 보임(pill이 흰색 단일) → 지도만으로 브랜드 식별 불가.
- **디벨롭:**
  1. ⭐ **홈/상세를 벡터 타일로 통일.** `vector_map_tiles` + OpenFreeMap **positron(라이트)/dark(다크)** 스타일. 드라이브 모드와 톤 통일, 라벨 선명·회전 가능·다크 지원. (원격 lock에서 패키지 SDK 제약 확인 필수.)
  2. **마커 대비·위계 재설계.** best=골드(유지). 상위 3위는 pill에 **브랜드 컬러 좌측 도트/링** 추가(카드의 브랜드 스트라이프와 일관). 비상위는 회색 최소 pill. **가격 pill에 흰색 외곽선(할로)** 을 둘러 벡터 배경 위 가독성 확보(현재 best만 흰 테두리 — `station_widgets.dart` PriceMarker의 border 로직 확장).
  3. **충돌 회피/클러스터.** 줌아웃 시 `flutter_map_marker_cluster`(또는 supercluster)로 묶고, 클러스터 라벨은 "최저 N원"으로. 겹칠 땐 최저가 우선 노출(z-index).
  4. **"최저가 강조" 규칙 문서화.** 최저가=골드+아이콘, 내 위치=파란 점(현재 스타일 유지), 선택=확대+그림자 강화(모션은 oil-motion 마커 펄스로 다음 단계).

### 5.3 숫자 히어로 / 차트 — **차별화 핵심**
- **현재:** 절약액 `+18,097원`이 카드 우측·상세 히어로 카드에 크게(초록, w800, tabular) — 스크린샷 02·06b. 하지만 **추세/누적 시각화 없음**. 주유 이력(`history_screen.dart`)은 리스트 위주로 추정.
- **디벨롭:**
  1. ⭐ **`fl_chart` 도입.** (a) 홈 상단 또는 이력 탭에 **"이번 달 절약 누적" 영역 차트**(월별 막대 또는 라인), (b) **"내 주유 단가 추이"** 라인(내 실주유 단가 vs 지역 평균), (c) 유종/브랜드별 미니 도넛. 모든 축·툴팁 숫자는 tabular + Pretendard.
  2. **히어로 숫자 카운트업**은 oil-motion 스킬(2.5)의 다음 단계로 연결 — 여기서는 "무엇을 크게 보일지"(절약 누적·회당 절약)의 **정보 위계**만 정의.
  3. **"근거 배지" 확장.** "우회비용 빼고도 1회당 N원 이득"(스크린샷 02)을 이력에서 **"올해 총 N원 아꼈어요"** 누적 배너로 승격 — 앱 리텐션 훅.

### 5.4 모션 — 다음 단계 관점 (중복 회피)
- oil-motion이 P1(카운트업/OpenContainer/Pressable/탭전환)·P2(마커 팝·펄스·시트 스냅)·P3(랜딩/스파크라인/성공)을 이미 정의. **본 트랙이 추가로 제안하는 "그 다음":**
  1. **벡터 지도 카메라 연출.** 벡터 전환 후 `flutter_map_animations`로 최저가 마커에 부드러운 플라이+줌(래스터에선 흐릿해 무의미했던 것이 벡터에선 값어치).
  2. **차트 draw-on.** fl_chart 라인/영역의 최초 표시 시 좌→우 그리기(oil-motion 스파크라인 draw-on 레시피를 차트로 확장).
  3. **셰이더 히어로 배경(선택).** FragmentProgram으로 히어로 카드 뒤 미세한 골드 글로우(Impeller 기본이라 jank 낮음) — **절제**해서 1위 카드에만.

### 5.5 위젯 / 카 디스플레이
- **현재:** 드라이브 모드(`drive_screen.dart`, `drive_island.dart`)가 3D 벡터로 이미 존재(스크린샷 08c) — 상단에 주유소 카드(가격·"N원 아껴요"·왕복/시간) 오버레이. 완성도 높음.
- **디벨롭:**
  1. **home_widget(장기).** 홈 화면 위젯 = "지금 내 주변 최저가 N원 · +M원 절약"(네이티브 위젯 UI 별도 작성 필요 — Flutter가 위젯을 그리지 못함).
  2. **드라이브 오버레이 카피/대비 점검.** 다크 3D 배경 위 골드 배지 "+18,097원 아껴요"(스크린샷 08c)는 대비 양호. reduce-motion·큰글꼴에서 카드가 깨지지 않는지 검증.
  3. **카 디스플레이(초장기).** flutter_carplay는 안전·심사 부담 큼 → BMW/Toyota 사례는 방향성 참고만, Phase 3 이후.

### 5.6 다크 모드
- **현재:** `AppTheme.dark()` + darkScaffold/darkSurface/darkBorder/darkText 완비(`app_theme.dart:37-45`), 마커·카드가 `isDark` 분기(`station_widgets.dart`). 구조는 탄탄.
- **디벨롭:**
  1. **홈/상세 지도 다크.** 벡터 전환의 부수 효과 — OpenFreeMap dark 스타일로 지도까지 다크 일관성(현재 래스터라 지도만 라이트로 뜸).
  2. **골드 펄스 다크 튜닝.** 다크에서 best 골드 글로우 alpha 하향(oil-motion 체크리스트에도 명시) — 눈부심 방지.
  3. **savingBright(#34D399)** 를 다크 전용 절약색으로 이미 사용(`station_widgets.dart`) → 유지.

### 5.7 접근성·품질
출처: docs.flutter.dev/ui/accessibility, api.flutter.dev(MediaQueryData.disableAnimations), TextScaler 마이그레이션 문서.
- **Semantics:** 지도 마커·가격 pill·차트에 `Semantics(label: 'GS칼텍스, 리터당 1840원, 1회 18097원 절약')`처럼 **스크린리더용 요약 라벨** 부여(현재 커스텀 그래픽이라 자동 트리 빈약할 가능성).
- **큰 글꼴:** `textScaleFactor` 사용 금지 → **`TextScaler`/`MediaQuery.textScaler`** 사용(Flutter 마이그레이션·Android 14 비선형 스케일). 히어로 50px 숫자·카드가 200% 글꼴에서 넘치지 않게 `FittedBox`/줄바꿈 검증(스크린샷 02 카드 우측 영역이 특히 취약).
- **색 대비:** traffic 색은 **텍스트+아이콘 병기**(색맹 대응). 골드(#FFB020) 위 잉크 텍스트 대비는 양호하나, 회색 muted 텍스트(#6B7785)의 소형 폰트 대비 재확인.
- **reduce motion:** `MediaQuery.disableAnimations`(=`AppMotion.reduceMotion`)로 카운트업·펄스·차트 draw-on을 즉시 전환(oil-motion 규칙과 동일). 웹은 prefers-reduced-motion 지원됨.
- **햅틱:** 최저가 마커 탭·저장 성공에 `HapticFeedback.selectionClick/lightImpact`.
- **60/120fps:** Impeller 기본이라 셰이더 jank는 해소. **블러/BackdropFilter는 스크롤·지도 위에서 여전히 비쌈**(Impeller에서도 리스트 내 blur 성능 저하 사례 있음 — flutter#126353). glass 효과 남용 금지, 필요 시 여러 BackdropFilter는 **`BackdropKey` 공유**로 1회 렌더로 합침. 지도 위 반복 애니메이션은 `RepaintBoundary` 격리.

---

## 6. "최고 디자인 버전" 컨셉 — 텍스트 와이어프레임

브랜드 언어(ink/gold·헤어라인·거대 숫자·해요체)는 유지. 변경 축 = **벡터 지도 · Pretendard · 데이터 시각화 · 대비 강화**.

### 6.1 홈 (지도 + 시트)
```
┌─────────────────────────────────────────┐
│ [◉ 내 주변 주유소        ]  [ 휘발유 ⟳ ]   │  ← Pretendard, 검색 pill 유지
│                                           │
│   ░░ OpenFreeMap positron 벡터 (라이트) ░░ │  ← 래스터→벡터: 선명·라벨 회전·다크대응
│         ● 내위치(파란 점)                  │
│      ╭──────╮  ← 최저가: 골드 pill+주유아이콘 │
│      │⛽1,840│    + 흰 할로(대비)            │
│      ╰──╥───╯                             │
│   ╭────╮  ╭────╮  ← 상위3: 브랜드 도트 pill  │
│   │1,914│  │1,924│                         │
│   ╰────╯  ╰────╯   (겹치면 클러스터 "최저 1,840")│
│                        [ ⌖ ] [ ✎ ] 우측 FAB │
├────────── ▔▔ (시트 핸들, snap) ────────────┤
│ ● 도로 보통 · 지금 도로 상황이 반영됐어요       │  ← 해요체 유지
│ ┌── 경제 1위 · GS칼텍스 ───────── 1,840원/L ┐│  ← 골드 보더 카드
│ │ 이케이에너지㈜ 강산주유소        +18,097원 ││  ← tabular, 카운트업(모션 다음단계)
│ │ 4.2km·왕복10.0km   L당545원저렴·우회−2,613 ││
│ │ ▸ 우회비용 빼고도 1회당 18,097원 이득       ││
│ └──────────────────────────────────────┘│
│ [3] S-OIL  구도일주유소 두꺼비    1,841 +17,257│
│ ...                                        │
├──[🏠홈] [📊절약순위] [🕐주유이력] [⚙️설정]──┤  ← 아이콘 세트 1종 통일(Phosphor/Symbols)
└─────────────────────────────────────────┘
```
핵심 변경: **벡터 지도**, **마커 대비/브랜드 도트/클러스터**, **Pretendard**, 카운트업은 모션 다음 단계.

### 6.2 상세 (주유소)
```
┌─────────────────────────────────────────┐
│ [←]        ░ 벡터 미니맵(다크/라이트 일치) ░  │  ← 상세도 벡터로 통일(현재 래스터)
│                 ╭⛽1,840╮ (골드)            │
├───────────────────────────────────────────┤
│ [GS] 경제1위 · GS칼텍스                      │
│ 이케이에너지㈜ 강산주유소                      │  ← Pretendard w800
│ ┌ 현재 가격 ─────┐ ┌ 1회 절약 ───────────┐ │
│ │ 1,840원/L      │ │ +18,097원 (초록)     │ │  ← tabular 히어로 2분할(유지)
│ └───────────────┘ └────────────────────┘ │
│ ── 절약 근거 미니차트(NEW) ────────────────  │  ← fl_chart: 내단가 vs 지역평균 바
│  내 예상단가 ▇▇▇▇ 1,840 · 지역평균 ▇▇▇▇▇ 2,110│
│ 🏠 도로명 / 📍 지번 / 📞 전화 (헤어라인 구분) │  ← 유지
│ 부가서비스 [세차장]                          │
│ 유종별 가격  휘발유 1,840 · 경유 1,819 ...    │  ← tabular 정렬 강화
│ ┌ [♡]  [ ◈ 길안내 시작 ] ──────────────────┐│  ← 잉크 버튼 유지
└─────────────────────────────────────────┘
```
핵심 변경: **벡터 미니맵**, **절약 근거 미니차트(fl_chart)**, **유종별 tabular 정렬**.

### 6.3 이력 / 절약 대시보드 (NEW, 데이터 시각화 히어로)
```
┌─────────────────────────────────────────┐
│ 주유이력                                   │
│ ┌── 올해 총 절약 ─────────────────────────┐│  ← 리텐션 훅 배너
│ │  ₩ 214,800 아꼈어요  (골드/초록, 카운트업) ││
│ │  ▁▂▃▅▆█  월별 절약 누적 (fl_chart 막대)    ││  ← draw-on(모션 다음단계)
│ └──────────────────────────────────────┘│
│ ── 내 주유 단가 추이 (fl_chart 라인) ───────  │
│  ╱‾‾╲__╱‾╲   내단가 ── / 지역평균 ┈┈         │
│ ── 기록 ───────────────────────────────── │
│ 09.27 GS칼텍스 강산  1,840원/L · 40L · +18,097│  ← tabular
│ 09.20 S-OIL 두꺼비   1,855원/L · 38L · +12,300│
│  [ + 주유 기록 추가 ]                        │  ← 저장 성공 모먼트(모션 다음단계)
└─────────────────────────────────────────┘
```
핵심: **절약 대시보드**로 앱의 킬러 가치를 시각화 — 오피넷 공식앱이 흡수하지 못한 "개인화된 누적 절약 스토리".

### 6.4 (참고) 드라이브 모드 — 현행 유지 + 대비 점검
현재 3D 벡터 + 상단 카드(스크린샷 08c)는 완성도 높음. 큰글꼴/reduce-motion에서 오버레이 카드 레이아웃만 회귀 점검.

---

## 7. 출처 (URL + 확인일 2026-09-28)

**Flutter 기술/릴리스**
- Flutter 3.47 What's new — https://flutter.dev/blog/whats-new-in-flutter-3-47 (material_ui/cupertino_ui 1.0 독립 패키지)
- Material/Cupertino decoupling — https://flutter.dev/blog/decoupling-material-cupertino · migration: https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui
- M3 Expressive to Flutter (umbrella, not planned/paused) — https://github.com/flutter/flutter/issues/168813
- Material 3 for Flutter — https://docs.flutter.dev/ui/design/material · https://flutter.dev/blog/material-3-for-flutter
- Impeller rendering engine — https://goo.gle/3KaQlTV (Android API29+ 기본, GL 폴백) · 상태(2026 iOS·Android 기본): https://medium.com/@siddhant.shukla_3691/the-state-of-flutter-in-2026-a-deep-technical-breakdown-948f3f280c7a
- BackdropFilter(BackdropKey) — https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html · blur 성능 이슈: https://github.com/flutter/flutter/issues/126353
- disableAnimations — https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html · 웹 접근성: https://docs.flutter.dev/ui/accessibility/web-accessibility
- TextScaler 마이그레이션 — https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor · Android14 비선형: https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration
- 타이포/가변폰트 — https://docs.flutter.dev/ui/design/text/typography · 실무 접근성: https://dcm.dev/blog/2025/06/30/accessibility-flutter-practical-tips-tools-code-youll-actually-use/

**쇼케이스 사례**
- Flutter Showcase — https://flutter.dev/showcase (확인: Nubank, BMW, Toyota 2026-05, Kakao Mobility 2024-09, SoFi, Google Pay, NotebookLM, LG webOS, Universal Studios, Headspace)
- Wonderous(gskinner 오픈소스 데모) — https://flutter.gskinner.com/wonderous/
- Nubank — https://flutter.dev/showcase/nubank · BMW — https://flutter.dev/showcase/bmw
- 사례 종합(2026) — https://getwidget.dev/blog/amazing-apps-built-with-flutter-framework/ · https://verygood.ventures/blog/top-companies-using-flutter/

**지도**
- flutter_map docs — https://docs.fleaflet.dev/
- vector_map_tiles(greensopinion) — https://github.com/greensopinion/flutter-vector-map-tiles · PMTiles(josxha) — https://github.com/josxha/flutter_map_plugins/blob/main/vector_map_tiles_pmtiles/README.md
- OpenFreeMap styles(업스트림 OpenMapTiles 스타일 abandoned 명시) — https://github.com/hyperknot/openfreemap-styles · Positron — https://openmaptiles.org/styles/positron/
- Protomaps API — https://protomaps.com/api
- flutter_map_supercluster — https://github.com/rorystephenson/flutter_map_supercluster · marker_cluster — https://github.com/lpongetti/flutter_map_marker_cluster
- flutter-maplibre(josxha, 신규) — https://github.com/josxha/flutter-maplibre · maplibre-gl(구) — https://github.com/maplibre/flutter-maplibre-gl · PMTiles(MapLibre) — https://maplibre.org/flutter-maplibre-gl/advanced/pmtiles/
- mapbox_maps_flutter(과금·Standard 3D) — https://docs.mapbox.com/flutter/maps/guides/pricing/ · https://docs.mapbox.com/flutter/maps/guides/styles/set-a-style/ · https://docs.mapbox.com/map-styles/guides/standard-styles/
- flutter_naver_map(note11g) — https://github.com/note11g/flutter_naver_map · Kakao Flutter SDK — https://developers.kakao.com/docs/latest/en/flutter/getting-started · kakaomap_webview — https://github.com/devmemory/kakaomap_webview

**모션·애니메이션 패키지**
- Rive Flutter(0.15, 최소 3.32) — https://www.rive.app/docs/runtimes/flutter · rive_native — https://rive.app/docs/runtimes/flutter/rive-native · migration: https://www.rive.app/docs/runtimes/flutter/migration-guide
- material_3_expressive(비공식) — https://github.com/paadevelopments/material_3_expressive

**타이포·아이콘·차트**
- Pretendard(OFL·variable·dynamic subset) — https://github.com/orioncactus/pretendard (docs: https://docsearch.algolia.com/mcp/docs/repo/orioncactus/pretendard) · Fontsource: https://fontsource.org/fonts/pretendard/about · Adobe Fonts: https://fonts.adobe.com/fonts/pretendard
- fl_chart — https://github.com/imaNNeo/fl_chart
- material_symbols_icons(2.960, 4264개) — https://github.com/timmaffett/material_symbols_icons · phosphor_flutter — https://github.com/phosphor-icons/phosphor-flutter

**한국 프로덕트 디자인**
- 토스 인터랙션("인터랙션, 꼭 넣어야 해요?", Simplicity23, 2023) — https://toss.tech/article/interaction
- TDS Colors — https://tossmini-docs.toss.im/tds-react-native/foundation/colors/
- 당근 SEED Design — https://github.com/daangn/seed-design (모노레포 karrot-ui)

**iOS 26 Liquid Glass (공식 Flutter 지원 없음, 커뮤니티만 — 미검증 신뢰도)**
- 커뮤니티 패키지(네이티브 플랫폼뷰) — https://github.com/gunumdogdu/cupertino_native_better · 셰이더 흉내 — https://github.com/sdegenaar/liquid_glass_widgets ※ 공식 로드맵/지원 문서는 확인되지 않음(미검증).

**코드 근거(로컬, 읽기 전용)**
- `oil_checker/lib/core/theme/app_theme.dart` (AppColors, AppTheme, formatWon, Pretendard 주석)
- `oil_checker/lib/presentation/widgets/station_widgets.dart` (PriceMarker, BrandBadge, StationCard, tabular figures)
- `oil_checker/lib/presentation/screens/home_screen.dart:370-371` (래스터 OSM 타일)
- `oil_checker/lib/presentation/screens/station_detail_screen.dart:113-115` (래스터 OSM 타일)
- `oil_checker/lib/presentation/screens/drive_screen.dart:8,26,237` (MapLibre + OpenFreeMap dark 3D)
- `oil_checker/pubspec.yaml` (flutter_map 8·flutter_map_animations 0.10·animations 2.2·maplibre_gl 0.27·Pretendard 미번들)
- 스크린샷: `.omo/ulw-research/20260928-214100/screens/02·03·05·06b·07·08c`
- 선행 모션 리서치: `.omo/ulw-research/20260925-193225/SYNTHESIS.md` · `.devin/skills/oil-motion/SKILL.md`
