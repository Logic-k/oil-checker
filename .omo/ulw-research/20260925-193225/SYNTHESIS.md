# SYNTHESIS — Oil Checker 모션/애니메이션 전면 개선 딥리서치

- 세션: 20260925-193225 (2026-09-25)
- 쿼리: "scienceaix/deepresearch 리포 참조하여 딥리서치 방법 연구 → 코드베이스 확인 → 전반적인 애니메이션·랜딩·디자인 모션 리서치 → 실질적으로 적용 가능한 워크플로우/프롬프트 산출"
- 대상: `E:\OpenCode_OilMaker\oil_checker` — Flutter 3.41.x / Dart 3.11.x, 웹(Vercel) + Android
- 산출물: 본 문서 + `.devin/skills/oil-motion/SKILL.md` (재사용 프롬프트/실행 스펙)

---

## 1. 핵심 요약 (TL;DR)

**현재 Oil Checker는 "정적이지만 정제된" 상태다.** Toss식 미니멀 디자인 언어(잉크+골드, 헤어라인 보더, 거대 숫자 히어로)는 이미 갖췄으나, 모션은 커스텀 시머 스켈레톤 1개뿐이다. 탭 전환·리스트 진입·페이지 전환·숫자 변경·지도 카메라 이동 전부 즉시 전환(instant cut)이다.

**가장 큰 기회:** 앱의 핵심 가치가 "N원 절약"이라는 *숫자*인데, 그 숫자가 정적으로 뜬다. 절약액 카운트업 + 지도 마커 스태거 팝인 + 카드→상세 공유요소 전환 3개만으로도 체감 품질이 급변한다.

**적용 방법론:** 딥리서치 서베이(arXiv 2506.12594)의 표준 루프 — *분해 → 병렬 수집 → 갭 분석 → 인용 합성* — 을 그대로 적용했다. 재사용 가능한 실행 스펙은 `.devin/skills/oil-motion/SKILL.md`에 프롬프트 형태로 패키징했다.

**권장 스택(의존 최소):** SDK 내장 스프링(`SpringSimulation`, `SpringDescription.withDurationAndBounce`) + `animations ^2.2.0`(OpenContainer/FadeThrough — **3.0.0은 Dart 3.12 필요해서 현 SDK에 안 맞음**) + `flutter_map_animations`(카메라) + 선택적으로 `number_flow_flutter`(절약액 롤링). Lottie/Rive는 빈 상태·성공 모먼트에만.

---

## 2. 딥리서치 방법론 분석 (scienceaix/deepresearch)

해당 리포는 코드가 아니라 **큐레이션 리스트**(Awesome Deep Research Projects)다 — arXiv 2506.12594 "A Comprehensive Survey of Deep Research: Systems, Methodologies, and Applications"(80+ 시스템 분석)의 부록 자원.

### 2.1 서베이의 4축 분류법 (시스템을 평가하는 눈)

| 축 | 의미 | 이 작업에의 매핑 |
|---|---|---|
| Foundation models & reasoning | 추론 엔진 | 에이전트 자체 |
| Tool utilization & environmental interaction | 검색·브라우징·코드 읽기 도구 | web_search/webfetch + grep/read |
| Task planning & execution control | 질문 분해, 실행 제어 | §2.2의 루프 |
| Knowledge synthesis & output | 인용 기반 합성, 구조화 리포트 | 본 문서 + SKILL.md |

아키텍처 패턴 4종(monolithic / pipeline / multi-agent / hybrid) 중 **pipeline+human-in-loop hybrid**가 이 규모(단일 앱 리서치)에 적합하다.

### 2.2 실용 딥리서치 루프 (이번 세션에서 실제 적용한 것)

```
1. DECOMPOSE   리서치 질문을 하위 질문으로 분해
               → (a) 방법론 자체  (b) 코드베이스 감사  (c) Flutter 모션 기술 지도
                 (d) 벤치마크 디자인 철학(토스)  (e) 산출물 형태
2. PARALLEL    독립 질문을 병렬 수집 (web_search 다중 발사 + 파일 배치 읽기)
3. EXTRACT     각 소스에서 "적용 가능한 사실"만 추출 — 버전 제약, API명, 수치
4. GAP CHECK   놓친 것 확인 → 후속 질의 (예: animations 3.0.0의 Dart 3.12 요구 발견)
5. SYNTHESIZE  인용과 함께 계층적 리포트 + 실행 가능 산출물(스킬/프롬프트)
```

핵심은 4번이다 — "좋아 보이는 것"과 "지금 이 코드베이스에 실제로 적용되는 것"을 가르는 검증 단계(버전·SDK 제약, 기존 구조와의 충돌)가 없으면 리서치는 쇼핑 리스트가 된다.

### 2.3 오픈소스 워크플로우 구현체 참고 (리포 목록 중)

반복 루프 구조를 코드로 보려면: `dzhng/deep-research`(계획→검색→재귀 심화), `langchain-ai/open_deep_research`(LangGraph 파이프라인), `assafelovic/gpt-researcher`(planner→researcher→writer 역할 분리)가 표준이다.

---

## 3. 코드베이스 모션 감사 (검증된 사실)

`lib/presentation` 전수 조사(4,579 LOC, 화면 6 + 위젯 2).

### 3.1 이미 있는 것

| 위치 | 모션 | 평가 |
|---|---|---|
| `widgets/app_state_views.dart:29-97` | 커스텀 시머(ShaderMask + GradientTransform 슬라이드, 1.4s 반복) | ✅ 잘 만듦 — 유지 |
| `home_screen.dart:398` | `DraggableScrollableSheet` (min .22 / init .5 / max .92) | ⚠️ snap 미설정 — 손 떼면 중간에 멈춤 |
| `station_detail_screen.dart:148` | Transform.translate 본문 오버랩(-22) | 시각 구조만, 모션 아님 |

### 3.2 없는 것 (즉시 전환되는 지점 전체)

| 지점 | 현재 | 기회 |
|---|---|---|
| 앱 런치 | `runApp` → 즉시 HomeShell + 스켈레톤 | 네이티브 스플래시 → 브랜드 랜딩 → 홈 페이드 |
| 탭 전환 | `IndexedStack` 교체 (main.dart:59) | PageTransitionSwitcher + FadeThrough |
| 카드 → 상세 | `MaterialPageRoute` 기본 슬라이드 | OpenContainer(공유요소) — 카드가 상세로 "확장" |
| 절약액 숫자 | 정적 텍스트 50px (ranking_screen.dart:329) | 0→N 카운트업 / 롤링 디짓 — 앱의 킬러 모먼트 |
| 지도 마커 | 한 프레임에 전부 표시 | 스태거 스케일-팝 + best 마커 골드 펄스 |
| 지도 카메라 | `initialCenter` 고정, 이동 시 점프 | flutter_map_animations의 AnimatedMapController |
| 위치 지정 핀 | 즉시 표시 | 위에서 낙하 + 착지 바운스 |
| 리스트 진입 | ListView 정적 | 첫 진입 시 staggered fade-up (첫 6~8개만) |
| 터치 피드백 | InkWell 회색 리플만 | 토스식 press scale 0.97 스프링 |
| 필터 칩 선택 | 색 즉시 변경 | 슬라이딩 선택 pill (AnimatedSwitcher/박스 이동) |
| 스파크라인 | 정적 경로 | draw-on (dash offset) 애니메이션 |
| 주유 기록 저장 | 스낵바만 | 체크마크 draw-on + 미니 컨페티(해피 모먼트) |
| 빈 상태 | 정적 아이콘 | subtle float 루프 또는 Lottie 1회 |

### 3.3 디자인 언어 진단

이미 "calm premium" 축에 있다: 오프화이트 스캐폴드(#F7F9FA), 잉크(#12181F), 골드 액센트(#FFB020), 헤어라인 보더, -0.2~-2.2 레터스페이싱의 굵은 타이포. **바꿀 대상은 색/레이아웃이 아니라 "움직임의 물리"다.** AI슬롭(보라 그래디언트·글래스모피즘 남용·3열 카드)은 이미 없음 — 건드리지 말 것.

---

## 4. 리서치 결과 — Flutter 모션 기술 지도

### 4.1 패러다임 전환: duration/curve → spring physics

- **M3 Expressive**(2025~)가 모션 체계를 스프링 물리로 교체했다. 스프링 = stiffness(빠르기) + damping(바운스 감쇠) + initial velocity. 스킴은 `expressive`(히어로/핵심)와 `standard`(일반) 두 종류. 공식 Flutter 지원은 아직 "Unavailable"이나 SDK의 `SpringSimulation`/`SpringDescription`으로 동일하게 구현 가능.
- **`SpringDescription.withDurationAndBounce(duration, bounce)`** — SwiftUI `spring(duration:bounce:)`와 동일한 API. "500ms, bounce 0.25"처럼 디자이너 언어로 스프링 정의 가능. 직접 mass/stiffness 계산 불필요.
- **커브가 여전히 쓰이는 곳:** 색/투명도 등 "공간이 아닌" 속성(effects). M3 토큰: emphasizedDecelerate `Cubic(0.05,0.7,0.1,1.0)`(진입), standardAccelerate `Cubic(0.3,0,0.8,0.15)`(퇴장), standard `Cubic(0.2,0,0,1.0)`.

### 4.2 패키지 평가 (이 프로젝트 기준)

| 패키지 | 용도 | 판정 |
|---|---|---|
| `animations ^2.2.0` | OpenContainer(카드→상세), FadeThrough(탭), SharedAxis(온보딩) | ✅ 채택 — **3.0.0은 Dart 3.12 필요 → 2.2.0 고정** |
| `flutter_map_animations` | AnimatedMapController(카메라 플라이), AnimatedMarker | ✅ 채택 — 홈 지도에 직접 해당 |
| `motor` | 통합 모션 API(CupertinoMotion/MaterialSpringMotion/다차원 스프링) | ✅ 차기 표준 — springster 후속. 토큰 체계 쓰려면 채택 |
| `number_flow_flutter` | 롤링 디짓(오도미터), 스프링+모션블러, 로케일 포맷 | ✅ 절약액에 최적 — 단 애니메이션 검증 후 자체 구현도 쉬움 |
| `flutter_animate` | 선언형 이펙트 체이닝 `.animate().fadeIn().slideY()` | ⚠️ 편하지만 최근 커밋 1년 전. 필수 아님 — 동일 효과 TweenAnimationBuilder로 가능 |
| `lottie` | 빈 상태/성공 애니메이션(JSON, 일 63K 다운로드) | 🔸 선택 — 에셋 제작 필요. 토스도 PNG시퀀스+Lottie로 3D 흉내 |
| `rive` | 스테이트 머신 인터랙티브 그래픽 | 🔸 과함 — 게이지/캐릭터 같은 연속 인터랙티브가 생기면 |
| `flutter_native_splash` | 네이티브 런치 화면(브랜드 컬러+로고) | ✅ 랜딩 개선의 1단계 — preserve/remove로 첫 프레임 제어 |
| `flutter_staggered_animations` | AnimationLimiter 스태거 리스트 | ⚠️ 있으면 편하지만 30줄짜리 자체 구현으로 충분 |

### 4.3 토스 인터랙션 원칙 (한국 프로덕트 벤치마크, toss.tech/article/interaction)

1. **터치 이펙트부터** — 가장 빈번한 인터랙션이 체감을 바꾼다. 회색 리플 → "눌리는" 스케일 피드백.
2. **모션의 눈속임** — 실제 리스트를 애니메이트하는 대신 위에 레이어를 띄워 한 화면처럼 보이게. 공수↓ 효과↑.
3. **모션 컴포넌트화** — 진입/퇴장/강조를 미리 만든 컴포넌트로 → 누구든 같은 품질.
4. **해피 모먼트** — 절약·달성 같은 긍정 순간에만 컨페티 등 극적 모션. 항상 쓰면 가치가 떨어진다.
5. **로딩을 컨텐츠로** — 대기 시간에 보는 애니메이션이 이탈을 줄인다(스켈레톤+시머 이미 적용 중, 검증된 방향).

### 4.4 성능·접근성 가드레일 (Flutter 특화)

- **transform/opacity만 애니메이트.** width/height/top/left는 레이아웃 재계산 유발.
- 지도 위 애니메이션 요소는 `RepaintBoundary`로 격리(마커 펄스가 타일 레이어 리페인트를 유발하지 않도록).
- 스태거는 **첫 6~8개만** — 이후는 즉시 표시(콘텐츠 도달 지연 방지).
- `MediaQuery.of(context).disableAnimations` 또는 `SemanticsBinding` 체크 → 축소 모션 설정 시 애니메이션 생략/즉시 전환. (웹은 Flutter PR #180041로 prefers-reduced-motion 지원 추가됨.)
- 무한 반복 애니메이션(펄스 등)은 화면 이탈 시 `Ticker` 중지 — `dispose` 누락 주의.
- 스크롤 중 진입 애니메이션은 끄거나, 뷰포트 진입 1회만.

---

## 5. Oil Checker 모션 디자인 시스템 (제안)

상세 실행 스펙·코드 레시피·체크리스트는 `.devin/skills/oil-motion/SKILL.md`. 여기는 구조만.

### 5.1 모션 토큰 (단일 소스: `lib/core/theme/app_motion.dart` 신규)

| 토큰 | 값 | 용도 |
|---|---|---|
| `springExpressive` | withDurationAndBounce(500ms, 0.3) | 히어로 카드, 시트 스냅, 마커 팝 |
| `springStandard` | withDurationAndBounce(350ms, 0.0) | 칩, 버튼 press, 카드 |
| `springSnappy` | withDurationAndBounce(280ms, 0.15) | 터치 피드백, 배지 |
| `curveEnter` | Cubic(0.05,0.7,0.1,1.0) | 화면/요소 진입 |
| `curveExit` | Cubic(0.3,0,0.8,0.15) | 퇴장 |
| `staggerGap` | 40ms, 최대 8개 | 리스트 스태거 |
| `heroCountUp` | 900ms emphasizedDecelerate | 절약액 카운트업 |

### 5.2 화면별 우선순위 (체감/공수 비율 순)

| 순 | 대상 | 효과 | 공수 |
|---|---|---|---|
| P1 | 절약액 카운트업 (히어로 카드) | 앱 정체성 모먼트 | 반일 |
| P1 | 카드→상세 OpenContainer | 연속성·프리미엄 | 반일 |
| P1 | 탭 FadeThrough 전환 | 앱 전체 기본기 | 1시간 |
| P1 | 버튼/카드 press-scale 스프링 | 토스식 터치감 | 반일 |
| P2 | 지도 마커 스태거 팝인 + best 펄스 | 홈 첫인상 | 1일 |
| P2 | 바텀시트 snap + 카메라 플라이 | 물리감 | 반일 |
| P2 | 위치 핀 낙하·스쿼시 | 디라이트 | 2시간 |
| P2 | 온보딩(차량등록) SharedAxis | 단계 연결감 | 반일 |
| P3 | 랜딩: 네이티브 스플래시→로고 스프링→홈 | 브랜드 | 1일 |
| P3 | 스파크라인 draw-on / 저장 성공 모션 / 빈상태 Lottie | 디테일 | 각 반일 |

### 5.3 적용 워크플로우 (이 리포지토리용 반복 가능 절차)

```
PHASE 0  토큰     lib/core/theme/app_motion.dart 생성 — 스프링/커브/스태거 상수
                  + reduceMotion 헬퍼 (MediaQuery disableAnimations 래핑)
PHASE 1  기본기   PageTransitionsTheme(FadeThrough) 전역 적용
                  + Pressable 위젯(scale 0.97 springSnappy)으로 InkWell 감싸기
                  + 탭 IndexedStack → PageTransitionSwitcher
PHASE 2  히어로   _BestCard 절약액 카운트업 + OpenContainer 카드→상세
PHASE 3  지도     AnimatedMapController 도입 + 마커 팝인 + best 펄스 + 핀 낙하
PHASE 4  디라이트  온보딩 SharedAxis + 스파크라인 draw-on + 성공 체크/컨페티
각 PHASE 완료 시: flutter analyze 0 / flutter test 통과 / reduce-motion 점검
```

### 5.4 재사용 프롬프트

`.devin/skills/oil-motion/SKILL.md`에 전체 스펙을 스킬로 패키징했다. 다음 세션에서 "oil-motion 스킬대로 P1 적용해줘"로 바로 실행 가능. 프롬프트 본문은 해당 파일 §모션 레시피.

---

## 6. 리스크·주의

- `animations` 버전: **^2.2.0 고정** (3.0.0은 Dart ≥3.12 / Flutter ≥3.44 필요 — 현재 3.11.x와 충돌).
- `flutter_animate`는 maintenance 모드(마지막 커밋 ~1년). 핵심 경로 의존 금지, 쓴다면 이펙트 장식용만.
- 웹 빌드 주의: `ShaderMask`/blur 남용 시 HTML/CanvasKit 렌더러 모두에서 프레임드랍. 펄스는 transform+opacity로.
- OSM 타일 레이어 위의 잦은 리페인트(마커 반복 애니메이션)는 RepaintBoundary 필수.
- 스태거/카운트업 같은 "연출"은 **첫 진입 1회만** — 데이터 갱신 때마다 재생하면 오히려 신뢰를 깎는다.
- AGENTS.md §5 제약과 무관(UI 전용 변경) — Opinet 호출·좌표계·캐시 경로는 건드리지 않는다.

## 7. 출처

- scienceaix/deepresearch (awesome-list) + arXiv 2506.12594 Deep Research 서베이
- m3.material.io — Motion physics system (springs: stiffness/damping/velocity, expressive·standard 스킴), easing/duration 토큰 표
- api.flutter.dev — SpringDescription.withDurationAndBounce(SwiftUI 동일), SpringSimulation, RepaintBoundary, MediaQuery.disableAnimations
- docs.flutter.dev — staggered animations(Interval), Hero(공유요소), PageRouteBuilder, physics simulation 쿡북
- pub.dev — motor(springster 후속 통합 모션), number_flow_flutter, flutter_map_animations, animations(버전 이력), flutter_native_splash, lottie, rive, flutter_animate(커밋 주기)
- toss.tech/article/interaction — 토스 인터랙션 팀: 터치 이펙트 우선·눈속임 레이어·모션 컴포넌트화·해피 모먼트
- 코드 근거: oil_checker/lib/presentation 전수 (main.dart, screens/*, widgets/*)
