# Track A — Oil Checker 코드·UX 감사

- 기준 커밋: `main 5eabeac` (2026-09-28)
- 대상: `oil_checker/lib` (화면 7 + 위젯 8, 약 9,500 LOC)
- 근거: 소스 `파일:줄` + 오늘 Android 16 에뮬레이터 캡처(`screens/*.png`, 서울시청 GPS·휘발유)
- 검증 상태(외부): `flutter analyze lib 0 issues`, `flutter test 80/80`, web·apk 빌드 성공(기제공 사실). 본 감사는 정적 분석 + 화면 대조로 수행. 실행/빌드/네트워크는 하지 않음.

---

## 1. 요약 (핵심 10줄)

1. **엔진은 PLAN §4 공식과 정확히 일치**한다(절약액·우회비용·점수). 문제는 공식이 아니라 **입력값(기준가)의 신뢰성**이다.
2. **기준가 = "가장 가까운 주유소" 가격**(`economy_engine`/`providers`). 오늘 그 값이 2,385원(이상치)이라 모든 카드가 +16,000~18,000원으로 **과대 표시**됐다. (H2 확인)
3. **홈 리스트 정렬·순위 표시 불일치**: 리스트는 가격 오름차순, 배지는 경제성 순위(1·3·5·12·7·2…)라 한 화면에서 순서가 뒤섞여 보인다. (H1 확인)
4. **'도로 왕복 Nkm'는 1위 카드에만** 노출(`home_screen`의 `detourKm: isBest ? … : null`). 실제 계산은 상위 10곳 OSRM·나머지 직선거리라 카드 간 정밀도가 다르다. (H3 부분확인)
5. **혼잡 칩은 실교통이 아니라 시간대 휴리스틱**인데 "지금 도로 상황이 반영됐어요" 카피는 실시간을 암시한다. (H4 확인)
6. **상세 화면 3대 하자**: 실내등유(자동차 무관) 노출(H6), 전화 탭 불가(H7), 하트(즐겨찾기) 버튼이 순수 장식으로 동작 없음(H8) — 셋 다 확인.
7. **접근성이 사실상 부재**: `lib` 전체에 `Semantics`/`semanticLabel` **0건**. 뒤로가기/GPS 버튼·지도에 라벨 없음. (H15 확인)
8. **디자인 토큰은 정리됐으나 하드코딩이 잔존**: `fontSize:` 리터럴 110회, TextTheme 미사용 → **textScaler(큰 글꼴) 대응 취약**.
9. **설정이 영구 저장 안 됨**: 다크모드·월 주유횟수·표기방식이 메모리 상태(`ui_prefs.dart`)라 앱 재시작 시 초기화된다(문서엔 없던 신규 발견).
10. **PLAN MVP 미구현 다수**: 알뜰/상표 필터, 전국·시도 평균가 비교, 목적지 설정 UI, 즐겨찾기/알림 — API 클라이언트에 메서드는 있으나 화면 미연결.

---

## 2. 기능별 평가표

| 기능 | 장점 | 단점·문제점 | 근거 |
|---|---|---|---|
| 온보딩(차량 설정) | 차종 검색→탱크·연비 자동입력, 실사/실루엣 이미지 폴백 | 789 LOC 단일 파일, 접근성 라벨 없음 | `car_setup_screen.dart` |
| 홈(지도+시트+리스트) | 드래그 시트·스냅·스태거 모션 완성도 높음 | 정렬/순위 불일치(H1), 마커 강조 약함(H9), 시트 확장 시 상단바 잔존(H12) | `home_screen.dart:? / 02·03·05 캡처` |
| 절약순위 | 히어로 카운트업·근거 3분할 지표 우수, 거리 필터/정렬 토글 | 기준가 이상치 그대로 노출(H2), 접근성 라벨 없음 | `ranking_screen.dart` |
| 상세 | 지도 히어로·부가서비스·유종별 가격 구성 양호 | 실내등유 노출(H6), 전화 비탭(H7), 하트 무동작(H8) | `station_detail_screen.dart` |
| 길안내 | 카카오맵 링크 + 인앱 드라이브 모드 2택 | 옵션 시트가 M3 기본 ListTile+크림 틴트로 이질적(H16) | `station_detail_screen.dart:432~`, `07 캡처` |
| 드라이브 모드 | 3D 건물·브랜드색 블록·다이나믹 아일랜드 야심적 | 초기 10~20s 빈 화면·경로선 없음·영문/한글 병기(H14) | `drive_screen.dart`, `08a-c 캡처` |
| 주유이력 | 실연비·스파크라인·표시연비 대비 % 우수 | odometer를 `formatWon`으로 콤마표기(단위 혼동 소지) | `history_screen.dart` |
| 설정 | 카드 그룹·세그먼트·스테퍼 깔끔 | **설정 비영구(재시작 초기화)** | `settings_screen.dart`, `ui_prefs.dart` |
| 스플래시/로딩/빈/에러 | 인앱 게이지 인트로·스켈레톤·플로팅 빈뷰 일관 | 시스템 스플래시 흰 배경 원형 아이콘(H10), 스켈레톤 상태바 겹침(H11) | `splash_intro.dart`, `app_state_views.dart`, `01a·01b 캡처` |

---

## 3. 가설 검증 H1–H16

### H1 — 정렬 기준 vs 순위 표시 불일치 → **확인**
- 홈 리스트는 `stationsAroundProvider`가 Opinet `sort:1`(가격순)으로 받은 순서 그대로 렌더한다. `providers.dart`의 `getStationsAround(... sort: 1)`.
- 카드 배지는 경제성 순위로 계산: `station_widgets.dart`의 `StationCard.rank`가 `ranking.ranked.indexWhere(...)+1`.
- `home_screen.dart` `_cardFor`에서 `rank`를 경제성 인덱스로 넣지만 리스트 순서는 가격순 → 배지가 1·3·5·12·7·2… 로 튄다(`02_home_initial.png`, `04_home_sheet_scrolled.png`에서 확인).
- **사용자 영향**: "왜 3위가 1위 아래에 있지?" 신뢰 저하.
- **수정 제안(S)**: 홈 리스트도 경제성 순으로 정렬하거나(랭킹과 동일 소스), 배지를 순위 대신 "저렴/거리" 태그로 바꿔 정렬 기준을 명시.

### H2 — 기준가 이상치로 절약액 과대 → **확인**
- 기준가 로직: `providers.dart` `economyRankingProvider` — `baseline = stations.reduce((a,b)=>a.distanceM<=b.distanceM?a:b)` (가장 가까운 주유소).
- 절약액: `economy_engine.dart` `calculateEconomy` — `(baselinePrice - candidatePrice) * fillUpLiters`. 주유량 = `profile.tankSizeL`(탱크 전체).
- 오늘 가장 가까운 곳이 2,385원(지도 상단 pill, `02`·`05` 캡처)이고 후보가 1,840원 → L당 545원 차 × 대형 탱크 ≈ +18,097원. PLAN §4.2도 기준가를 "현재·가까운 주유소 가격"으로 정의하므로 **공식대로 동작하나 이상치에 취약**.
- **사용자 영향**: "가득 넣으면 1.8만원 이득"이 사실상 "이상치 대비" 값이라 과장. 실제 절약과 괴리.
- **수정 제안(M)**: 기준가를 (a) 반경 내 중앙값/평균가 또는 (b) 시도 평균가(`avgSidoPrice.do`, 이미 클라이언트 존재)로 바꾸고, 주유량을 탱크 전체가 아닌 "1회 주유량(기본 50L, PLAN §4.2)"으로 낮춰 과대표시 완화. 카피도 "가장 가까운 곳 대비"임을 명시.

### H3 — 도로 왕복은 1위만, 나머지 직선거리 추정 → **부분확인**
- 표시: `home_screen.dart` `_cardFor` → `detourKm: isBest ? entry?.result.detourKm : null`. 즉 '도로 왕복 Nkm' 문구는 1위 카드에만.
- 계산: `providers.dart` 상위 `kOsrmCandidateCount=10`곳만 OSRM `table`로 실제 도로, 나머지는 직선거리 예비점수 유지. 우회비용 자체는 모든 카드에 표시(`detourCost`).
- 따라서 "1위만 도로 계산"이 아니라 "상위 10곳 도로 + 나머지 직선"이며, **표시만 1위로 한정**. 카드별 정밀도가 다른데 UI엔 구분 없음.
- **사용자 영향**: 11위 이하는 직선거리 기반인데 동일하게 "예상 N분"으로 보여 정확도 오인.
- **수정 제안(S)**: 도로 계산된 카드에만 '도로' 배지, 그 외엔 '직선 추정' 표기. 또는 왕복 km를 상위 10곳 모두 노출.

### H4 — 혼잡 칩이 실교통이 아니라 시간대 휴리스틱 → **확인**
- `core/traffic/congestion.dart` `CongestionModel.levelAt`: 주말 smooth / 07-09·18-20 heavy / 09-18 moderate / 그 외 smooth. **순수 시각·요일 기반**, 실교통 API 없음.
- 카피: `home_screen.dart` `_StationSheet`의 "지금 도로 상황이 반영됐어요" + `CongestionChip`("도로 보통"). "지금…반영"은 실시간을 암시.
- **사용자 영향**: 정체가 없어도 평일 낮이면 항상 "보통(1.2×)"으로 우회시간이 부풀려짐 → 경제성 점수 왜곡.
- **수정 제안(S)**: 카피를 "시간대 평균 혼잡을 반영했어요"로 정정. (근본 개선(L): TomTom/카카오 실교통 연동.)

### H5 — 상세 푸터 갱신 안내 불일치 → **부분확인**
- 문구: `station_detail_screen.dart` "가격은 오피넷 기준 1~2시간마다 갱신돼요."
- 실제 Opinet 갱신은 1/2/9/12/16/19시(불규칙, PLAN §3.3), 앱 캐시 TTL 6h(`providers.dart` `cacheTtl: Duration(hours:6)`). "1~2시간마다"는 부정확(오전엔 7시간 공백 등).
- **사용자 영향**: 갱신 빈도 과대 기대.
- **수정 제안(S)**: "가격은 오피넷 갱신 시각(1·2·9·12·16·19시)에 맞춰 최대 6시간마다 갱신돼요."

### H6 — 상세 유종별 가격에 실내등유 노출 → **확인**
- `station_detail_screen.dart` `_productLabel`에 `'C004' => '실내등유'` 매핑이 있고, `detail.prices.entries`를 **필터 없이 전부** 렌더(`for (final entry in detail.prices.entries...)`).
- 캡처 `06b_detail_top.png`: 휘발유 1,840 / **실내등유 1,890** / 경유 1,819 노출.
- **사용자 영향**: 승용차와 무관한 등유가 섞여 혼란.
- **수정 제안(S)**: 표시 유종을 자동차 관련(B027·B034·D047·K015)으로 화이트리스트 필터.

### H7 — 전화 탭 불가·주소 복사 없음 → **확인**
- 전화는 `_InfoRow`(아이콘+라벨+`Text`)로만 렌더, 제스처 없음(`station_detail_screen.dart`). `launchUrl`은 파일 내 1곳(카카오맵)뿐이고 `tel:` 스킴 없음(grep 확인).
- 주소도 복사/지도 이동 액션 없음.
- **사용자 영향**: 번호를 눌러도 전화 안 걸림 → 수동 입력 필요.
- **수정 제안(S)**: 전화 행을 `InkWell`+`launchUrl(Uri.parse('tel:$tel'))`로, 주소 행에 복사 버튼 추가.

### H8 — 하트(즐겨찾기) 버튼 무동작 → **확인**
- `station_detail_screen.dart` 하단 액션바: `Container(... child: Icon(Icons.favorite_border))` — `InkWell`/`onTap` 없음. DB에 즐겨찾기 테이블 없음.
- **사용자 영향**: 탭해도 반응 없는 "죽은 버튼".
- **수정 제안(M)**: 즐겨찾기 테이블 추가 + 토글 저장, 또는 미구현이면 버튼 제거.

### H9 — 지도 마커·강조·뷰포트·클러스터 문제 → **부분확인/확인**
- 강조: 코드상 1위는 `PriceMarker(isBest:true)`(골드) + `_BestMarkerFrame` 펄스가 있으나(`home_screen.dart`), 캡처 `05`에서 보이는 pill(2385/2488/1924/1914/2295)은 **모두 흰색** — 1위(4.2km)가 초기 뷰포트(zoom14) 밖이라 골드 마커가 화면에 없음 → 결과적으로 강조 부재로 보임(H9 초기뷰포트·강조 확인).
- 클러스터링: `MarkerLayer`에 클러스터 없음 → 밀집 시 겹침(확인).
- 내 위치 점: 파란 점 렌더는 되나 시트 `initialChildSize:0.5`가 하단 절반을 덮어 도심에선 가려질 수 있음(부분확인).
- **수정 제안(M)**: 데이터 로드 후 1위 포함 `fitBounds`로 카메라 조정, 마커 클러스터(`flutter_map` supercluster) 도입, 시트 초기 크기 축소(0.4) 또는 지도 패딩.

### H10 — 시스템 스플래시 흰/원형 + 인앱 SplashIntro 조건 → **확인**
- `pubspec.yaml` `flutter_native_splash`에 `color:#12181F`, `image` 지정은 있으나 **`android_12:` 섹션 없음** → Android 12+는 시스템이 흰(또는 테마) 배경 + 원형 마스크 아이콘을 강제(캡처 `01a`가 흰 배경 원형 게이지). 
- 인앱 `SplashIntro`: `main.dart` `HomeShell.build`에서 `if (!_introDone && !reduceMotion)` 조건 → reduceMotion이면 아예 생략, 아니면 앱 실행당 1회 오버레이(`01a/01b`).
- **수정 제안(S)**: `flutter_native_splash`에 `android_12: { color, image, icon_background_color }` 추가해 시스템 스플래시를 ink 배경으로 통일.

### H11 — 로딩 스켈레톤 첫 pill 상태바 겹침 → **확인**
- `app_state_views.dart` `AppSkeleton.build`는 `Padding(widget.padding=EDGE(16,16,16,16))`만 두고 **`SafeArea` 없음**. `main.dart` `HomeShell`이 `Scaffold(body:...)`로 감싸지만 홈은 전체화면 지도라 상단 인셋 보정 부재.
- 캡처 `01b_splash_t2.1s.png`: 첫 헤더 블록이 상태바 시계 영역과 겹침.
- **수정 제안(S)**: `AppSkeleton`을 `SafeArea`로 감싸거나 `padding.top`에 `MediaQuery.padding.top` 가산.

### H12 — 시트 최대 확장 시 상단 검색바 잔존 → **확인(부분)**
- `home_screen.dart`: `_TopBar`/`_LocationButtons`는 `Stack`에 항상 얹혀 있고, `_StationSheet`는 `maxChildSize:0.92`. 시트를 최대(92%)로 올려도 상단 8% 구간에 검색바·유종 버튼이 **그대로 남아** 시트 위로 삐져나온 것처럼 보임(캡처 `03_home_sheet_expanded.png` 상단에 검은 유종 버튼 잔상).
- **수정 제안(S)**: 시트 확장 비율에 따라 `_TopBar`/`_LocationButtons` opacity를 페이드아웃(DraggableScrollableController listen).

### H13 — 상호명 (주)/㈜ 접두로 잘림 → **확인**
- 이름 표시는 `station.name`(`OpinetStation.name = OS_NM`) 원문을 `maxLines:1 + ellipsis`(`station_widgets.dart`, `ranking_screen`, `drive_island`).
- 캡처: "이케이에너지㈜ 강산주유소", "(주)가재울뉴타운주유소", "(주)미래아스팔트 신우…" 등 접두어가 폭을 잡아먹어 뒷부분이 …로 잘림.
- **수정 제안(S)**: 표시명 정규화 헬퍼(`(주)`, `㈜`, `주식회사` 제거/축약)를 `core/format`에 추가해 목록·상세·아일랜드 공통 적용.

### H14 — 드라이브 모드 초기 빈 화면·병기 라벨·경로 부재 → **확인**
- 초기 빈 화면: `drive_screen.dart` `_buildMap`은 MapLibre + OpenFreeMap `liberty` 벡터 타일을 원격 로드하고, `_onStyleLoaded`에서 건물·주유소 레이어를 구성. 스타일/타일 로딩 동안 배경은 `Scaffold(backgroundColor: AppColors.ink)` → 초기 검정, 이후 타일 크림색. **로딩 인디케이터 없음**(캡처 `08a`(2s) 크림 빈 화면, `08b`(8s) 아일랜드만, `08c`(20s) 건물 등장). 확인.
- 병기 라벨: `styleUrl = openfreemap/liberty`는 name+name:en 병기 → 캡처 `08c` "Seoul/서울특별시", "DOWNTOWN SEOUL/서울 도심".
- 경로선/목적지: 주유소는 `fill-extrusion` 블록으로만 표시, **경로 라인 레이어 없음**. 카메라는 `_flyTo(내 위치)`로 GPS 팔로우 → 목적지 주유소가 초기 화면 밖. 확인.
- **사용자 영향**: 진입 직후 "먹통" 인상, 목적지가 어디인지 시각적 안내 부재.
- **수정 제안(M)**: 스타일 로드 전 스켈레톤/로딩 오버레이, 진입 시 내위치+목적지 `fitBounds`, OSRM `route` geometry로 경로 라인 레이어 추가.

### H15 — 접근성 라벨 부재 → **확인**
- `lib` 전체 `Semantics`/`semanticLabel` **0건**(grep 결과 no matches).
- 상세 뒤로가기 `_CircleButton`(`station_detail_screen.dart`)·홈 GPS/새로고침(`_SpinRefresh`)에 `Tooltip`은 일부 있으나 스크린리더용 `semanticLabel`/`IconButton.tooltip`은 아이콘만 있는 커스텀 `InkWell`엔 없음. 지도는 단일 위젯 트리라 uiautomator에 "1,914/1,918…" 가격 텍스트가 개별 노드로 노출(H15 지도 노드 관찰과 일치).
- **수정 제안(M)**: 모든 아이콘 버튼에 `Semantics(label:)`/`tooltip`, 지도 마커에 접근성 라벨, 하단탭에 `Semantics(selected:)`.

### H16 — 길안내 옵션 시트가 M3 기본 스타일 → **확인**
- `station_detail_screen.dart` `_showRouteOptions`: `showModalBottomSheet(showDragHandle:true, builder: ... ListTile(...))`. 앱 테마의 `bottomSheetTheme` 미지정 → M3 기본 `surfaceTint`(seed=골드) 적용되어 **크림색 surface**(캡처 `07`).
- 앱 다른 시트(`history` 추가 시트)는 커스텀 라운드+surface라 언어 불일치.
- **수정 제안(S)**: 앱 공통 시트 컴포넌트로 교체하거나 `ThemeData.bottomSheetTheme`에 `surfaceTintColor: transparent, backgroundColor: scheme.surface, shape` 지정.

---

## 4. 경제성 엔진·데이터 신뢰성

- **공식 일치**: `economy_engine.dart`의 절약액/연료비용/시간비용/점수/우회거리 규칙은 PLAN §4.1과 정확히 일치. 왕복(목적지 미설정)·편도(설정) 분기도 §4.1대로.
- **PLAN 대비 강화**: 우회거리를 직선×1.3(§4.2 MVP)에서 **OSRM 실도로**로, 시간비용·혼잡 가중치를 추가(§2.2 후순위를 선반영). 긍정적.
- **신뢰성 리스크 3가지**:
  1. **기준가 이상치**(H2): 가장 가까운 1곳에 전적으로 의존. 그 곳이 고가/특수(2,385원)면 전체 절약액이 부풀려짐.
  2. **주유량 = 탱크 전체**(`fillUpLiters: profile.tankSizeL`): PLAN §4.2는 "기본 50L 또는 탱크". 탱크 전체는 "가득 주유" 가정이라 절약액을 최대화 → 과장 인상.
  3. **시간비용 상수** `kTimeValueWonPerMin=80`(`providers.dart`): 사용자 설정 불가, 임의 값이 점수를 흔든다.
- **사용자 오해 지점**: 카드의 "+18,097원"과 히어로 "18,097원 아껴요"(캡처 `08b`)는 "이상치 대비·탱크 전체" 조건이 숨겨져 있어, 실제 체감 절약과 괴리.
- **폴백 견고성(긍정)**: OSRM 실패 시 `_fallbackRanking`(직선거리)으로 앱은 계속 동작. `OsrmClient`는 1req/s 스로틀 + 30분 메모리 캐시로 데모 서버 정책 준수.

---

## 5. 디자인 시스템 감사

- **토큰(양호)**: `app_theme.dart` `AppColors`가 의미 기반(best/saving/traffic/brand)으로 정리됨. radius(`radiusCard 16`/`radiusLarge 22`), 브랜드 컬러/약자 매핑 일관. `formatWon`·`FontFeature.tabularFigures()`로 숫자 정렬 처리(마커·카드·이력).
- **하드코딩 잔존(문제)**:
  - `fontSize:` 리터럴 **110회**(grep) — car_setup 20, history 17, ranking 15, detail 13, station_widgets 13… **TextTheme(`textTheme.titleLarge` 등) 미사용**. 타이포 스케일이 없다.
  - `Color(0x…)`·`Colors.white/black` 등 직접 색상이 화면 곳곳(예: `home_screen`의 `Color(0xFF2563EB)` 내 위치 점, drive의 hex 리터럴).
- **컴포넌트 재사용**: `StationCard`·`PriceMarker`·`BrandBadge`·`CongestionChip`·`AppEmptyView`·`AppSkeleton`·모션 위젯(`Pressable/PopIn/StaggerIn/PulseRing/SpinAction`) 재사용성 좋음.
- **다크 모드**: `AppTheme`가 light/dark 모두 정의, 화면 대부분 `scheme` 기반이라 커버리지 넓음. 단 **설정 토글이 비영구**(§7)라 재시작 시 system으로 복귀.
- **폰트**: `fontFamily: 'Pretendard'` 주석 처리(`app_theme.dart`) → 시스템 폰트 사용. 브랜드 타이포 미적용.
- **모션(양호)**: `app_motion.dart` 스프링 토큰 + `reduceMotion` 분기가 위젯 전반에 일관 적용(스켈레톤·팝인·펄스·카운트업 모두 disableAnimations 존중). 모션 리서치(20260925 SYNTHESIS) 스펙이 실제 구현됨.

---

## 6. 접근성 감사

- **스크린리더**: `Semantics`/`semanticLabel` **0건**. 아이콘 전용 커스텀 버튼(뒤로가기·GPS·새로고침·하트·드라이브 컨트롤)이 라벨 없음. (H15)
- **터치 타깃**: 홈 `_LocationButtons` 44×44, 상세 `_CircleButton` 42×42, 드라이브 `_roundButton` 46×46 → **48dp 미만 다수**. 하단탭 아이콘 히트영역은 `Expanded`라 충분.
- **textScaler**: 고정 `fontSize` + `maxLines:1 + ellipsis`가 카드·아일랜드·이력에 광범위 → **큰 글꼴에서 절약액/상호명/부제 잘림·오버플로 위험**(특히 `station_widgets` 가격+절약액 우측 컬럼).
- **명도 대비(WCAG, app_theme 값 기준 계산)**:
  - 골드 `best #FFB020` on 흰 `#FFFFFF`: 대비 ≈ **1.7:1** → 텍스트로 부적합(1위 배지 텍스트는 `ink`라 OK지만, 골드 글자를 흰 위에 쓰는 곳(splash 'OIL CHECKER' 등)은 저대비).
  - 초록 `saving #0E9F6E` on 흰: ≈ **3.0:1** → 큰 텍스트만 통과, 본문(13px 절약액)엔 미달. 다크 배경엔 `savingBright #34D399` 사용해 개선됨.
  - 보조텍스트 `muted #6B7785` on 흰: ≈ **4.2:1** → AA(본문 4.5) **근소 미달**.
  - 연녹 배경(`saving.withOpacity(0.1)`) 위 `savingDeep #0A7A55`: 양호(≈5:1 추정).
- **reduce motion(양호)**: `AppMotion.reduceMotion`이 모든 커스텀 애니메이션 분기점으로 사용됨.
- **수정 제안**: 아이콘 버튼 일괄 `Semantics`/`tooltip`, 터치 타깃 48dp, 골드/초록 텍스트는 `ink`/`savingDeep`로 교체 또는 굵게+크게, `muted` 한 단계 어둡게.

---

## 7. 성능·유지보수

- **거대 파일**: `drive_screen.dart`(약 926 LOC, 지도 상태·카메라·히트테스트·색칠 애니 혼재), `providers.dart`(603, 엔진 로직이 provider에 인라인), `car_setup_screen.dart`(789). 테스트·재사용 어려움.
- **엔진 위치**: 랭킹 계산 본체가 `economyRankingProvider`(provider) 안에 있어 순수 함수 테스트가 어렵다. `economy_engine.dart`는 순수라 테스트 가능하나 조합 로직은 provider에 묶임.
- **리빌드 범위**: 홈이 `stationsAround`+`economyRanking`+`gpsPosition`(10m마다) 모두 watch → GPS 스트림 갱신 시 지도 파란점 갱신 목적이나 상위 위젯 리빌드 유발 가능. `_StationMap`은 `didUpdateWidget`로 diff 처리해 완화.
- **지도 마커/RepaintBoundary(양호)**: 펄스 링을 `RepaintBoundary`로 격리(`home_screen`). 단 마커 수 상한/클러스터 없음(H9).
- **에러 삼킴**: `catch (_)` 4곳 — `providers.dart`(에셋 로드 폴백, 허용 가능) 2, `main.dart`(스플래시 remove) 1, **`drive_screen.dart:350` 스타일 셋업 전체를 삼킴**(3D/주유소 레이어 실패가 조용히 무시됨 → 디버깅 곤란).
- **테스트 공백(추정)**: 80/80 통과이나, UI 화면(home/ranking/detail/drive)·접근성·정렬 일관성(H1)·기준가(H2)에 대한 위젯/골든 테스트는 없어 보임(파일 구조상). 엔진 순수함수 위주로 추정.

---

## 8. 개선 백로그

### P0 (신뢰성·정확성 — 사용자가 잘못된 값을 본다)
| # | 문제 | 제안 | 파일 | 공수 |
|---|---|---|---|---|
| P0-1 | 기준가 이상치로 절약액 과대(H2) | 기준가=반경 중앙값 또는 시도평균가, 주유량=1회 50L 기본 | `providers.dart`, `economy_engine.dart` | M |
| P0-2 | 홈 정렬·순위 배지 불일치(H1) | 홈 리스트를 경제성순 정렬 또는 배지 의미 변경 | `home_screen.dart` | S |
| P0-3 | 혼잡 칩 카피가 실시간 오인(H4) | "시간대 평균 혼잡 반영"으로 문구 정정 | `home_screen.dart` | S |
| P0-4 | 갱신 안내 부정확(H5) | 실제 갱신시각·6h TTL 반영 문구 | `station_detail_screen.dart` | S |
| P0-5 | 하트 버튼 무동작(H8) | 즐겨찾기 저장 구현 또는 버튼 제거 | `station_detail_screen.dart`, `app_database.dart` | M |

### P1 (핵심 UX·접근성)
| # | 문제 | 제안 | 파일 | 공수 |
|---|---|---|---|---|
| P1-1 | 접근성 라벨 0건(H15) | 아이콘 버튼·지도·탭에 Semantics/tooltip | 전 화면 | M |
| P1-2 | 실내등유 노출(H6) | 자동차 유종 화이트리스트 필터 | `station_detail_screen.dart` | S |
| P1-3 | 전화 비탭·주소 복사 없음(H7) | tel: launchUrl + 주소 복사 | `station_detail_screen.dart` | S |
| P1-4 | 드라이브 초기 빈 화면·경로 부재(H14) | 로딩 오버레이 + fitBounds + 경로 라인 | `drive_screen.dart` | M |
| P1-5 | 설정 비영구(신규) | SharedPreferences로 theme/월횟수/표기 저장 | `ui_prefs.dart` | S |
| P1-6 | 지도 강조·클러스터·뷰포트(H9) | fitBounds(1위 포함)+클러스터+시트 초기 0.4 | `home_screen.dart` | M |
| P1-7 | textScaler 취약(고정 fontSize 110회) | TextTheme 스케일 도입, 잘림 지점 Flexible 처리 | `app_theme.dart` + 전 화면 | L |

### P2 (완성도·기술부채·미구현 MVP)
| # | 문제 | 제안 | 파일 | 공수 |
|---|---|---|---|---|
| P2-1 | 상호명 잘림(H13) | (주)/㈜ 정규화 헬퍼 공통화 | `core/format/` | S |
| P2-2 | 시스템 스플래시 흰/원형(H10) | pubspec `android_12` 섹션 추가 | `pubspec.yaml` | S |
| P2-3 | 스켈레톤 상태바 겹침(H11) | AppSkeleton SafeArea | `app_state_views.dart` | S |
| P2-4 | 시트 확장 시 상단바 잔존(H12) | 확장률 따라 상단바 페이드 | `home_screen.dart` | S |
| P2-5 | 길안내 시트 이질(H16) | 공통 시트/`bottomSheetTheme` | `station_detail_screen.dart`, `app_theme.dart` | S |
| P2-6 | 도로/직선 카드 정밀도 구분 없음(H3) | 도로 계산 카드에 배지 구분 | `home_screen.dart`, `station_widgets.dart` | S |
| P2-7 | MVP 미구현: 알뜰/상표 필터, 시도·전국 평균가 비교 | `lowTop10`/`avgSidoPrice` 화면 연결(클라이언트 이미 존재) | `ranking_screen.dart`, `providers.dart` | M |
| P2-8 | 드라이브 스타일 오류 삼킴 | `catch(_)`에 로깅/폴백 상태 | `drive_screen.dart:350` | S |
| P2-9 | drive_screen/providers/car_setup 거대 파일 | 엔진 로직을 domain으로 추출, 위젯 분리 | 해당 파일 | L |

---

### 부록 — 근거 캡처 대조표
- H1: `02_home_initial.png`, `04_home_sheet_scrolled.png` (배지 1·3·5·12·7·2 / 가격 1840→1849 오름차순)
- H2: `02`, `05` (지도 상단 2,385 pill = 기준가), 카드 +18,097
- H6: `06b_detail_top.png` (실내등유 1,890)
- H8: `06b` (하트 버튼)
- H9: `05_home_map_collapsed.png` (흰 pill 다수, 1위 뷰포트 밖)
- H10: `01a_splash_t0.9s.png` (흰 배경 원형)
- H11: `01b_splash_t2.1s.png` (상태바 겹침)
- H12: `03_home_sheet_expanded.png` (상단 유종 버튼 잔상)
- H14: `08a_drive_t2s.png`/`08b_drive_t8s.png`/`08c_drive_t20s.png` (빈 화면→건물, 병기 라벨)
- H16: `07_route_options_sheet.png` (크림색 M3 시트)
