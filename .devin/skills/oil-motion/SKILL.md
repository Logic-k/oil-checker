---
name: oil-motion
description: Oil Checker 앱의 모션/애니메이션 디자인 시스템. 토스식 터치감 + M3 Expressive 스프링 물리 기반. 화면 전환·리스트 진입·숫자 카운트업·지도 마커·터치 피드백 등 애니메이션을 추가/수정/검수할 때 사용. "모션 적용", "애니메이션", "oil-motion" 요청 시 반드시 로드.
---

# oil-motion — Oil Checker 모션 디자인 시스템

근거 리서치: `.omo/ulw-research/20260925-193225/SYNTHESIS.md`

## 0. 절대 규칙

1. **연출은 첫 진입 1회만.** 데이터 갱신/재빌드 때마다 리스트 스태거나 카운트업이 재생되면 안 된다. "값이 바뀌는" 것과 "처음 보이는" 것을 구분한다.
2. **transform/opacity만 애니메이트.** width·height·위치 속성 변경은 레이아웃 재계산 → 프레임드랍.
3. **`AppMotion.reduceMotion(context)`가 true면 즉시 전환** (애니메이션 생략). 모든 레시피에 이 체크를 포함한다.
4. **색·레이아웃·타이포는 건드리지 않는다.** 이 스킬은 움직임만 담당한다. 디자인 언어(ink/gold, 헤어라인, 라운드)는 이미 확립됨.
5. **커밋 전 `flutter analyze` 0 이슈 + `flutter test` 통과.**

## 1. 모션 토큰 — `lib/core/theme/app_motion.dart` (없으면 먼저 생성)

```dart
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Oil Checker 모션 토큰 — M3 Expressive 스프링 물리 기반.
/// duration/curve가 아니라 스프링(mass·stiffness·damping)이 기본 언어다.
class AppMotion {
  const AppMotion._();

  /// 히어로 모먼트 — 1위 카드, 시트 스냅, 마커 팝인. 살짝 바운스.
  static final SpringDescription springExpressive =
      SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 500),
    bounce: 0.3,
  );

  /// 일반 공간 이동 — 칩 선택, 카드, 바텀시트. 바운스 없음.
  static final SpringDescription springStandard =
      SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 350),
  );

  /// 터치 피드백·배지 — 빠르고 미세한 바운스.
  static final SpringDescription springSnappy =
      SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 280),
    bounce: 0.15,
  );

  /// 진입 커브 (M3 emphasizedDecelerate) — 공간이 아닌 속성용.
  static const Curve curveEnter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// 퇴장 커브 (M3 standardAccelerate).
  static const Curve curveExit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// 표준 커브 (M3 standard).
  static const Curve curveStandard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 리스트 스태거 간격 / 최대 연출 개수 (이후는 즉시 표시).
  static const Duration staggerGap = Duration(milliseconds: 40);
  static const int staggerMax = 8;

  /// 히어로 숫자 카운트업 시간.
  static const Duration heroCountUp = Duration(milliseconds: 900);

  /// 접근성 — "애니메이션 줄이기/제거" 설정이면 true.
  /// 모든 커스텀 애니메이션의 분기점으로 사용한다.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
```

## 2. 범용 레시피 (재사용 위젯)

### 2.1 Pressable — 토스식 "눌리는" 터치 피드백

InkWell 위에 scale 스프링을 얹는다. 버튼·카드·칩 등 모든 탭 요소에 적용.

```dart
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _settle(double velocity) {
    if (AppMotion.reduceMotion(context)) return;
    _c.animateWith(SpringSimulation(
      AppMotion.springSnappy, _c.value, 0, velocity,
      snapToEnd: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _c.stop();
        _c.value = 1.0; // 눌린 상태
      },
      onTapUp: (_) => _settle(4),
      onTapCancel: () => _settle(0),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(
          scale: 1 - 0.03 * _c.value, // 최대 0.97
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
```

`StationCard`·필터 칩·`_Segmented`·지도 버튼 등 `onTap` 있는 시각 요소를 이걸로 감싼다 (InkWell의 리플은 유지해도 됨 — Pressable이 밖, InkWell이 안).

### 2.2 스태거 리스트 진입 — 첫 진입 시만

```dart
/// 첫 빌드 시 index < AppMotion.staggerMax 인 아이템만
/// fade + 12px slide-up으로 순차 등장. 이후 빌드/스크롤엔 즉시 표시.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  // ...
}
```

구현 요약: `initState`에서 `Future.delayed(AppMotion.staggerGap * index)` 후 forward. `TweenAnimationBuilder`로도 가능:

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: Duration(milliseconds: 350) +
      AppMotion.staggerGap * index.clamp(0, AppMotion.staggerMax),
  curve: AppMotion.curveEnter,
  builder: (context, t, child) => Opacity(
    opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
    child: Transform.translate(
      offset: Offset(0, 12 * (1 - t)),
      child: child,
    ),
  ),
  child: stationCard,
)
```

⚠️ 딜레이를 duration에 넣는 트릭이라 깔끔하진 않으나 의존성 제로. 진짜 딜레이가 필요하면 `AnimatedOpacity`+`Timer` 대신 위젯을 `Future.delayed`로 감싼 StatefulWrapper 사용. **ListView.builder의 lazy 아이템에는 적용하지 말 것** — 스크롤할 때마다 튀는 것처럼 보인다. 적용 대상은 "전체가 한 번에 그려지는" 첫 화면 리스트(시트 초기 목록, 랭킹 첫 페이지).

### 2.3 화면 전환 (전역) — `main.dart` 테마에 1줄

```dart
// pubspec: animations: ^2.2.0  (3.0.0은 Dart 3.12 요구 — 현 SDK 3.11과 충돌)
import 'package:animations/animations.dart';

ThemeData(
  // ...
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
    TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
  }),
)
```

하단 탭 전환(`HomeShell`의 IndexedStack)은 `PageTransitionSwitcher`로 교체:

```dart
PageTransitionSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation, secondaryAnimation) =>
      FadeThroughTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  ),
  child: KeyedSubtree(
    key: ValueKey(_index),
    child: [_HomeScreen(), _RankingScreen(), ...][_index],
  ),
)
```

⚠️ IndexedStack→교체 시 탭별 스크롤/지도 상태가 리셋된다. 지도 상태 보존이 필요하면 탭 전환은 FadeThrough 대신 `AnimatedSwitcher` 짧은 페이드(200ms)로 타협하거나, 홈 탭만 `AutomaticKeepAliveClientMixin` 유지.

### 2.4 카드 → 상세 공유요소 전환 (OpenContainer)

```dart
OpenContainer(
  closedElevation: 0,
  openElevation: 0,
  closedColor: Colors.transparent,
  openColor: Theme.of(context).colorScheme.surface,
  closedShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  transitionDuration: const Duration(milliseconds: 450),
  closedBuilder: (context, open) => StationCard(..., onTap: open),
  openBuilder: (context, _) => StationDetailScreen(station: ..., position: ...),
)
```

`MaterialPageRoute` push를 이걸로 대체. 카드가 그대로 확장해 상세가 된다 — 리스트↔상세의 공간 연속성.

### 2.5 절약액 카운트업 — 히어로 숫자 (킬러 모먼트)

`_BestCard`의 `formatWon(amount)` 텍스트를 카운트업으로. 첫 표시 시 0→amount, 값 변경 시 이전값→새값.

간단판 (의존성 제로, TweenAnimationBuilder):

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: amount),
  duration: AppMotion.heroCountUp,
  curve: AppMotion.curveEnter,
  builder: (context, v, _) => Text(
    formatWon(v),
    style: /* 기존 50px w900 gold 스타일 그대로 */,
  ),
)
```

정밀판: `number_flow_flutter`의 `NumberFlow`(롤링 디짓 + 스프링 + 로케일). 자릿수 변경 시 리플로우까지 처리됨. 절약액이 자주 바뀌는(필터/기준 변경) 화면이면 이쪽이 낫다.

### 2.6 지도 — 카메라 플라이 + 마커 팝인 + best 펄스

```yaml
flutter_map_animations: ^0.9.0   # flutter_map ^8 호환 버전 확인 후 고정
```

- `AnimatedMapController`로 교체 → 위치 변경/마커 탭 시 `animatedMapMove(dest, zoom)` — 점프 대신 500ms fastOutSlowIn 플라이.
- 마커 등장: `AnimatedMarker` 또는 마커 위젯을 `TweenAnimationBuilder`(scale 0→1, springExpressive, index*60ms 스태거 — 가까운 순으로 정렬된 stations 순서 그대로).
- **best 마커 펄스**: PriceMarker 뒤에 `AnimatedBuilder` 기반 링 — scale 1→1.8 + opacity 0.5→0, 1.6s, 첫 표시 후 2~3회만 반복하고 정지(무한 루프 금지 — 배터리/주의 분산). `RepaintBoundary`로 감싸 타일 레이어 리페인트 격리.
- 위치 지정 핀: 탭 시 핀이 위 60px에서 낙하 → 착지 시 scaleY 0.85 스쿼시 → 스프링 복귀(springSnappy). 낙하 중 작은 그림자(scale/opacity 역상관)를 깔면 물리감↑.

### 2.7 바텀시트 스냅

`DraggableScrollableSheet(snap: true, snapSizes: const [0.22, 0.5])` 추가만으로 중간 위치에 멈추지 않고 자석처럼 붙는다. 시트 내 콘텐츠 진입은 `stationsAsync`가 loading→data로 바뀌는 순간에만 `AnimatedSwitcher`(250ms fade)로 스켈레톤→리스트 전환.

### 2.8 랜딩(첫 실행) 시퀀스

```yaml
flutter_native_splash: ^2.4.0
```

1. 네이티브 스플래시: 배경 `AppColors.ink` + 중앙 로고(골드 드롭/마크) — `dart run flutter_native_splash:create`.
2. `main()`: `FlutterNativeSplash.preserve(widgetsBinding: ...)` → DB/프로필 로딩 준비되면 `FlutterNativeSplash.remove()`.
3. 첫 Flutter 프레임 = 스플래시와 동일한 ink 배경 + 로고 → 로고가 springExpressive로 scale-up·페이드아웃되며 홈 지도가 curveEnter로 페이드인 → 마커 스태거 팝(§2.6).
4. `CarSetupScreen`(첫 사용자)로 가는 경우도 동일: 스플래시 배경 → 온보딩 첫 화면이 fade-in.

### 2.9 디라이트 (남는 공수 순으로)

- **온보딩 스텝 전환**: `_step` 전환을 `AnimatedSwitcher`+`SharedAxisTransition(horizontal)` — 진행 바와 연결된 방향성.
- **스파크라인 draw-on**: CustomPainter 경로를 `PathMetric`으로 잘라 `Tween(0→1)` 길이만큼만 그리기. 주유이력 요약 카드 최초 표시 시 1회, 700ms.
- **저장 성공**: 주유 기록 저장 시 스낵바 대신/함께 — 체크마크 `CustomPaint` draw-on + `HapticFeedback.lightImpact()`. "월 N원 아꼈어요" 누적이 새 기록을 넘으면 미니 컨페티(`confetti` 패키지 또는 20개짜리 커스텀 파티클 — 토스 해피모먼트 원칙: 정말 기쁜 순간에만).
- **빈 상태**: `AppEmptyView` 아이콘에 2.5s 주기 float(±4px, easeInOut). Lottie 에셋이 있으면 1회 재생으로 교체 가능 — 에셋 없으면 float로 충분.
- **새로고침 아이콘**: 탭 시 360° 회전 1회(springStandard).

## 3. 성능 가드레일

- 지도 위 반복 애니메이션(펄스)은 반드시 `RepaintBoundary` 내부.
- `blur`/`ShaderMask`는 스크롤 컨테이너·지도 위에 금지 (기존 스켈레톤 시머는 정적 영역이라 OK).
- `AnimationController`는 모두 `dispose`. 무한 반복은 `vsync` 보장 + 위젯 unmount 시 자동 정지 확인.
- 웹(CanvasKit)에서 60fps 확인 — 그림자 많은 카드 수십 장 + 스태거 동시 재생 시 `Profile` 모드로 체크.
- 스태거 대상은 화면에 보이는 첫 N개뿐. `staggerMax`(8) 초과분은 즉시 표시.

## 4. 적용 순서 (체감/공수 비율 순)

| Phase | 내용 | 완료 기준 |
|---|---|---|
| 0 | `app_motion.dart` 토큰 + reduceMotion 헬퍼 | analyze 0 |
| 1 | Pressable 적용 + PageTransitionsTheme + 탭 전환 | 전 화면 터치감/전환 |
| 2 | 절약액 카운트업 + OpenContainer 카드→상세 | 히어로 모먼트 |
| 3 | 지도: 카메라 플라이 + 마커 팝/펄스/핀 낙하 | 홈 첫인상 |
| 4 | 시트 스냅 + 온보딩 SharedAxis + 스파크라인 + 성공 모션 | 디테일 |

각 Phase는 독립 커밋 가능. Phase 0~2만 해도 체감의 80%.

## 5. Pre-flight 체크리스트 (모션 추가 시 매번)

- [ ] `reduceMotion` 분기가 있거나 프레임워크가 자동 처리하는가?
- [ ] 애니메이트하는 속성이 transform/opacity인가?
- [ ] 반복 애니메이션이 종료 조건을 갖는가? (무한 루프는 시머·float 등 의도된 것만)
- [ ] 컨트롤러 `dispose` 됐는가?
- [ ] 첫 진입 연출이 재빌드/데이터 갱신에 재발화하지 않는가?
- [ ] 스태거가 8개 상한을 지키는가?
- [ ] 지도/스크롤 위에 blur·ShaderMask를 새로 쓰지 않았는가?
- [ ] `flutter analyze` 0, `flutter test` 통과?
- [ ] 라이트/다크 양쪽에서 확인? (골드 펄스는 다크에서 alpha 조정)
