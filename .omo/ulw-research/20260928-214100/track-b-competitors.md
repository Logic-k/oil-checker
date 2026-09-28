# Track B — 경쟁사·시장 리서치 (Oil Checker)

- 세션: 20260928-214100 (조사·작성일 2026-09-28)
- 담당 트랙: 모빌리티·주유 앱 경쟁 분석 + 차별화 기회
- 범위: 국내(오피넷/카카오/티맵/네이버/정유사·카드/군소 앱) + 해외(GasBuddy/Waze/Google·Apple Maps/Upside/기록앱/독일·영국·호주)
- 대상 제품 요약: Oil Checker = 오피넷 가격 + 에너지공단 공인연비(CSV 임베드) + OSRM 도로 우회거리 → **절약금액(원) 랭킹**, OSM 지도+바텀시트, 차종 실사·탱크용량 자동입력, 주유이력→실연비, 카카오맵 길안내 링크, MapLibre 3D 드라이브 모드, 다크모드. Opinet 무료 API(일 1,500건 한도).

> 표기 규칙: ✅ 완전 지원 / △ 부분·간접 지원 / ❌ 미지원. 외부 사실에는 출처 URL 부기. 확인 못 한 것은 '미검증'.

---

## 1. 요약 (Executive Summary)

**시장 배경 (2026년 한국).** 중동 정세로 국제유가가 급등하자 정부는 2026-03-13 **석유 최고가격제**를 시행(1997년 유가 자유화 이후 30여 년 만)했고, 전국 평균 휘발유·경유가 리터당 **약 2,000원**대에서 고착됐다. 이로 인해 오피넷 앱 호출이 하루 만에 약 48%(118만→175만 건) 급증하고 접속 대기열까지 발생했다. 카드사는 리터당 40~150원 주유 할인 경쟁, 정유4사 담합 기소(추정 26조 원 효과) 등 "기름값"이 전 국민 관심사가 된 국면이다. 즉, **Oil Checker의 시장 타이밍은 좋다.** (출처: 동아일보/IT동아 2026-03-25; Chosun/Sedaily 2026)

**핵심 위협 검증 (AGENTS.md §6 P3 주장 검증 결과 = 사실).** 오피넷 공식앱이 2026년 초 10년 만에 전면 개편되며 **"추천순"**(거리+가격+**차량연비**+평균주유량 4요소 종합) 정렬, 공인연비 자동제공+실연비 입력, 검색 반경 10→20km, 장소명 검색, 경로별 주유소를 도입했다. **이는 Oil Checker의 핵심 가치("연비 반영 경제적 주유소 추천")를 상당 부분 흡수한 것이 맞다.** (출처: IT동아 2026-03-25 — 1차 검증 완료)

**그러나 오피넷에는 명확한 빈틈이 남아 있다.** ① "추천"까지만 하고 **절약금액을 원 단위로 정산하지 않음** ② **실연비 자동 추적 없음**(직접 입력만) ③ **경로별 주유소 커버리지 부족**(오피넷 3곳 vs 네이버지도 7곳, IT동아 실측) ④ **정체·시간비용 미반영** ⑤ 공공 인프라 특성상 트래픽 폭증 시 대기열·지연. 여기에 Oil Checker의 승부처가 있다.

**해외 벤치마크의 3대 교훈.** ① **게임화·리워드**(GasBuddy Rewards, Upside 캐시백)로 재방문·제보를 유도 ② **가격 예측/최적 주유 시점**(독일 mehr-tanken/ADAC — "정오 직전이 최저") ③ **여행/경로 비용 계산기**(GasBuddy Trip Cost). 반면 GasBuddy는 **가격 부정확·결제카드 트러블**(Trustpilot 1.3, 집단소송)로 신뢰가 무너진 상태 — Oil Checker는 "**공공데이터 기반 신뢰**"를 역포지셔닝 무기로 쓸 수 있다.

**결론 한 줄.** 오피넷이 "추천"을 흡수했으므로 Oil Checker는 **"추천을 넘어 원(₩) 단위로 정산하고, 내 실연비로 학습하며, 절약을 리워드로 돌려주는 앱"** 으로 재정의해야 한다.

---

## 2. 기능 매트릭스

행: 앱 / 열: (A)가격표시 (B)경로·우회 고려 (C)차량 연비 반영 (D)실결제가·할인 (E)가격예측·알림 (F)주유기록·실연비 (G)제보·커뮤니티 (H)결제 연동 (I)위젯·카플레이/안드로이드오토 (J)EV·충전

| 앱 | A | B | C | D | E | F | G | H | I | J |
|---|---|---|---|---|---|---|---|---|---|---|
| **Oil Checker (현재)** | ✅ | ✅(우회거리·왕복) | ✅(공인연비+실연비) | ❌ | ❌ | ✅(이력→실연비) | ❌ | ❌ | ❌ | ❌ |
| 오피넷(공식,v개편) | ✅ | △(경로별,개수부족) | ✅(추천순4요소) | ❌ | ❌ | △(실연비 직접입력) | △(이상가격 신고) | ❌ | 미검증 | △(충전소가격) |
| 카카오맵/카카오내비 | ✅ | △(경로상 표시) | △(내차량 연료비) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅(내비/오토) | ✅ |
| TMAP | ✅(착한주유소) | △(경로주변) | △(주유비 계산) | ❌ | ❌ | ❌ | △ | 미검증 | ✅(오토/카플레이) | ✅ |
| 네이버 지도 | ✅ | ✅(경로상 다수) | △(통행료/연료비) | △(NaverPay+GS 100원/L) | ❌ | ❌ | ❌ | △(NaverPay) | ✅ | ✅ |
| 정유사앱(엔크린/에너지+/현대/S-OIL) | △(자사만) | ❌ | ❌ | ✅(포인트·앱결제) | △(프로모) | ❌ | ❌ | ✅(앱결제) | 미검증 | △ |
| 주유 할인카드/간편결제 | ❌ | ❌ | ❌ | ✅(40~150원/L) | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| 오일맵/주유9/주유핏(군소) | ✅(최저가TOP) | ❌ | ❌ | ❌ | ❌ | △(즐겨찾기) | △(불법신고 등) | ❌ | ❌ | △ |
| **GasBuddy** | ✅(제보기반) | ✅(Trip Cost) | △(Trip Cost용) | ✅(Pay+ 카드) | △(가격알림) | △ | ✅(핵심) | ✅(자체카드) | ✅ | △ |
| Waze | ✅(제보+OPIS) | ✅(경로상 정렬) | ❌ | ❌ | ❌ | ❌ | ✅(핵심) | ❌ | ✅(오토/카플레이) | ✅ |
| Google Maps | ✅(가격표시) | ✅(연비최적 eco route) | ✅(엔진타입별) | ❌ | ❌ | ❌ | △ | ❌ | ✅ | ✅ |
| Apple Maps | ✅(유종필터) | ✅(EV경로) | △ | ❌ | ❌ | ❌ | ❌ | △(Charging Wallet) | ✅(카플레이) | ✅ |
| Upside | △ | ❌ | ❌ | ✅(캐시백) | ❌ | ❌ | ❌ | ✅(영수증/카드) | 미검증 | △ |
| Fuelio/Drivvo/Spritmonitor | △(일부 제보) | ❌ | ✅(연비·비용 통계) | △(수동입력) | ❌ | ✅(핵심·강력) | △(Spritmonitor 커뮤니티) | ❌ | 미검증 | ✅(전기차 지원) |
| 독일 mehr-tanken/clever-tanken | ✅(공식오픈데이터) | △ | ❌ | ❌ | ✅(예측·최적시점) | ❌ | ❌ | ❌ | 미검증 | ❌ |
| 영국 Fuel Finder(오픈데이터) | ✅(30분내 갱신 의무) | — | — | — | — | — | — | — | — | — |
| 호주 PetrolSpy/FuelWatch | ✅(투명성제도) | △ | ❌ | ❌ | △(가격사이클) | ❌ | △ | ❌ | 미검증 | △ |

근거는 §3 앱별 상세 및 §7 출처 참조. "미검증"은 이번 조사에서 1차 출처로 확정하지 못한 항목.

---

## 3. 앱별 상세

### 3.1 국내

**오피넷 공식앱 (한국석유공사) — 최대 직접 경쟁자, 개편 완료.**
- 개편 핵심(2026년 초, IT동아 실측 검증): **추천순 정렬 = 거리·가격·차량연비·평균주유량 4요소 종합**. 설정에서 차종 입력 시 에너지공단 **공인연비 자동제공**, **실연비 직접 입력 가능**. 메인 진입 즉시 주변 최저가+전국/지역 평균+전일 대비 등락 표시. 검색 반경 **10→20km**. **장소명 검색**(목적지 주변 최저가). 일러스트 기반 UI 개선.
- 데이터: 전국 가격은 VAN(카드결제망) 자동보고 : 사업주 직접보고 ≈ 8.5:1.5. 연 2.3억 명(2025) 이용.
- **약점(=Oil Checker 기회):** (1) 추천은 하되 **절약금액 원 단위 정산 없음**, (2) **경로별 주유소 개수 부족**(성북구→예술의전당: 오피넷 3 vs 네이버 7 / 마포→예술의전당: 1 vs 3), (3) 유가위기 시 **접속 지연·대기열**(공공 인프라 한계), (4) 실연비 **자동 추적 부재**.
- 출처: https://www.donga.com/news/It/article/all/20260325/133606508/1 (IT동아, 2026-03-25) — 4요소·연비자동·20km·경로별 개수·대기열 모두 이 기사에서 확인.

**카카오맵/카카오내비.** 지도상 주유소 가격 표시, 내비 경로 주변 안내, 내차량(차종·연료·하이패스) 설정 시 연료비·통행료 안내. 안드로이드오토·EV 지원. 카카오맵 API 4종 신규 오픈(2026)으로 심사 없이 경로/지도 이미지 활용 가능. **연비 기반 경제성 랭킹은 없음.**
- 출처: https://devtalk.kakao.com/t/api-4/150764 ; https://help.naver.com/service/5637/contents/8265 (연료비 안내 개념, 네이버 기준)

**TMAP (SK).** 국내 1위 내비. 2026-04 **"착한주유소(Good Gas Station) 캠페인"** 연계 — 산업부·소비자단체 주관, 저렴·정상가 주유소를 표시해 안내(개별 주유소까지만 길안내). 운전점수·보험할인 등 부가서비스 강함. 카플레이/오토 지원. Tmap Mobility는 2025 연간 첫 흑자(데이터·AI 전략).
- **약점:** 연비 기반 절약 정산 없음. 착한주유소는 "라벨" 수준.
- 출처: https://biz.chosun.com/en/en-it/2026/04/29/WCRRWAUL4RDKPKCLRVTXFNEQLI/ ; http://biz.chosun.com/en/en-it/2026/02/25/7JRXCUOU55G2LPXNL3H46LF3AI/

**네이버 지도.** 경로상 주유소 다수 표시(오피넷 대비 커버리지 우위 — IT동아 비교), 내차량 설정 시 통행료/연료비 계산, 경유지 최대 5개. **NaverPay + GS칼텍스 제휴로 리터당 100원 적립**(네이버플러스 멤버십, 월 5,000원 한도, 2026-04 시작 — 정유사 최초 페이 제휴).
- 출처: https://help.naver.com/service/5637/contents/19073 (주유비 계산) ; https://en.sedaily.com/society/2026/04/24/gs-caltex-becomes-first-korean-refiner-to-partner-with

**정유사 앱 (SK엔크린 / GS칼텍스 에너지플러스 / S-OIL / HD현대오일뱅크).** 자사 주유소 한정 포인트 적립·앱결제·멤버십 할인이 핵심. 크로스브랜드 가격비교/경제성 추천은 구조적으로 불가(자사 락인 모델). 정유4사는 2026년 담합 혐의로 기소(검찰 추정 직접담합 14.2조, 파급효과 포함 26조) — 소비자 신뢰 이슈.
- 출처: https://en.sedaily.com/culture/2026/07/06/prosecutors-indict-four-refiners-over-alleged-26-trillion

**주유 할인카드·간편결제.** FSC 요청으로 카드 9사가 리터당 **40~150원** 주유 할인 경쟁(2026). KB국민카드 최대 **150원/L**(주유전용카드, 월 1만원 한도), NH농협 **50원/L**(3만원 이상 결제, 월 5천원 한도), 신한 Deep Oil/RPM+ 3% 환급 연장. **Oil Checker가 "카드 할인 후 실결제가"를 반영하면 정유사·오피넷·군소앱 어디도 못 하는 차별점.**
- 출처: https://www.chosun.com/english/market-money-en/2026/04/02/RFRCFRAZQRDVDHEJCET6CR3DAA/ (KB 150원/L) ; https://en.sedaily.com/finance/2026/06/12/nh-nonghyup-card-expands-fuel-subsidies-amid-high-inflation (NH 50원/L) ; https://www.chosun.com/english/market-money-en/2026/06/01/LSISQHL7JFAJFKHTGURKDUOOCU/ (카드사 할인 연장 40~150원)

**군소 주유가격 앱 (실제 존재 확인).** App Store/Play에 다수 존재.
- **오일맵 - 최저가 주유소 지도**(개발자 JAEMIN LEE): 오피넷 공공데이터 기반, 지역별 최저가 TOP10, 유종별(휘발유/경유/고급) 비교, 브랜드 표시, 즐겨찾기. **경로·연비·정산 없음, 개인 개발 수준(리뷰 미미), UI 간결.** 
- **주유9 - Compare Gas/LPG Price**(softworx): 전국 주유/LPG 가격 + 불법행위 정보 지도/리스트.
- 그 외 App Store 연관 노출: **주유핏, 실주유가, GasAround** 등.
- 시사점: **"오피넷 데이터 재포장" 류 군소앱이 이미 다수 = 단순 최저가 표시로는 차별화 불가.** Oil Checker의 경제성 엔진·실연비·3D UX가 진입장벽.
- 출처: https://apps.apple.com/us/app/오일맵-최저가-주유소-지도/id6760611787 ; https://play.google.com/store/apps/details?id=com.softworx.gs

### 3.2 해외

**GasBuddy (북미, 25주년).** 제보 기반 15만+ 주유소, 경로상 주유소 검색, **Trip Cost 계산기**, **Pay with GasBuddy+ 카드**(최대 33¢/gal 절감), **GasBuddy Rewards**(영수증 스캔·게임·딜로 포인트→갤런당 할인, 2025-07 리워드 상환 개시), 데일리/위클리 챌린지 게임화.
- **불만 테마(중요):** Trustpilot **1.3점**, PissedConsumer **2.3/5(65% 부정)** — "가격이 부정확·오래됨→헛걸음", 결제카드 declined·주유기 한도 문제, 고객지원 부실, 집단소송(Eubanks v. GasBuddy). **크라우드소싱의 근본 약점.**
- 시사점: 게임화·리워드·Trip Cost는 벤치마크, 데이터 신뢰는 반면교사.
- 출처: https://www.gasbuddy.com/go/pay-with-gasbuddy-plus ; https://www.gasbuddy.com/go/25-years ; https://www.trustpilot.com/review/gasbuddy.com ; https://gasbuddy.pissedconsumer.com/review.html

**Waze.** 커뮤니티 제보 가격 + 2026 **OPIS 피드**(Google Maps와 동일 소스)로 정확도 강화. 검색창 Gas 아이콘→주변 주유소 저가순 자동정렬, 경로상 최저가. 오토/카플레이. **연비·정산 없음.**
- 출처: https://www.bgr.com/2221942/how-get-best-fuel-saving-with-waze/ ; https://www.waze.com/discuss/t/announcement-new-us-gas-prices-feed-rolling-out/404520

**Google Maps.** 가격 표시 + **eco-friendly(연비최적) 라우팅**(엔진타입별 연료·에너지 절감 경로, 기본값). Routes API로 개발자도 이용.
- 시사점: "경로 자체의 연비 최적화"는 Oil Checker의 "주유소 선택 최적화"와 상보적 — 결합 시 강력.
- 출처: https://support.google.com/maps/answer/11470237 ; https://developers.google.com/maps/documentation/routes/eco-routes

**Apple Maps.** 유종 필터, **EV 경로(고도·충전소 실시간 가용성)**, 2025-08 **Charging Wallet**(앱 내 충전 시작). 가격 정산은 약함.
- 출처: https://www.electrive.com/2025/08/14/apple-maps-introduces-ev-charging-function/ ; https://support.apple.com/guide/iphone/set-up-electric-vehicle-routing-iphc5e3a4b4b/ios

**Upside (구 GetUpside).** 주유·식료품·외식 **캐시백**. 수익모델: 가맹점이 "증분 거래(incremental)"에 대해서만 수수료 지불→일부를 사용자에 현금 환급하는 **프로핏셰어**. 20,000+ 파트너.
- 시사점: Oil Checker가 향후 수익화할 때 "제휴 주유소 캐시백/증분" 모델 참고.
- 출처: https://www.upside.com/blog/how-does-upside-work-a-step-by-step-guide ; https://backtofrontshow.com/how-does-upside-make-money/

**Fuelio / Drivvo / Spritmonitor (주유·차계부).** 주행거리·연비·비용 통계, 차량 유지비 관리, Spritmonitor는 동일 차종 사용자와 연비 비교 커뮤니티·전기차 지원. **가격비교/경로는 약하지만 "기록·분석 UX"는 최고 수준.**
- 시사점: Oil Checker의 주유이력→실연비를 **"차계부 + 절약 대시보드"**로 키우면 이 카테고리까지 흡수 가능.
- 출처: https://www.drivvo.com/en/personal-use/ ; https://apps.apple.com/us/app/spritmonitor-fuel-log-mpg/id616137163 ; https://play.google.com/store/apps/details?id=com.kajda.fuelio

**독일 mehr-tanken / clever-tanken / ADAC Drive (가격 예측·최적 주유 시점).** 정부 Markttransparenzstelle 공식 파트너로 실시간 가격+**예측+등락 기반 추천**. 2026-04 규정 변경(가격 인상은 하루 1회, 정오)으로 **"정오 직전이 최저"** 패턴 확립 → 50L 주유 시 최저점 이용하면 평균 7.3~9.2유로 절약(ADAC).
- 시사점: **"언제 넣을까"(시점 최적화)는 Oil Checker 미구현 영역** — Opinet 일별 데이터로 부분 구현 가능.
- 출처: https://finance.yahoo.com/sectors/energy/articles/germany-sees-record-swings-fuel-075527199.html ; https://play.google.com/store/apps/details?id=de.msg (mehr-tanken)

**영국 Fuel Finder (오픈데이터 의무제, 2025~).** Motor Fuel Price (Open Data) Regulations 2025 — 주유소가 가격 변동을 **30분 이내 의무 신고**. 약 90% 가입. CMA 2023 시장조사 후 도입.
- 시사점: 실시간·의무 데이터 흐름이 소비자 앱 생태계를 키운 사례. 한국 오피넷도 VAN 자동보고로 유사 인프라 보유 = Oil Checker의 데이터 신선도 근거.
- 출처: https://www.gov.uk/government/collections/road-fuel-price-data-scheme ; https://www.gov.uk/government/news/fuel-finder-for-drivers-factsheet

**호주 PetrolSpy / FuelWatch / MotorMouth (가격 사이클·투명성).** 주·준주별 투명성 제도(빅토리아 제외)로 30분내 신고. ACCC가 5대 도시 **가격 사이클** 정보 제공(휘발유는 사이클, 디젤/LPG는 아님). RACQ 등 자동차협회 앱.
- 시사점: **"지금 가격이 사이클상 고점/저점인가"** 안내 = 예측형 UX의 또 다른 형태.
- 출처: https://www.accc.gov.au/consumers/petrol-and-fuel/petrol-price-cycles-in-the-5-largest-cities ; https://www.accc.gov.au/media-release/there-are-tools-available-to-save-money-on-fuel

### 3.3 참고 — Flutter 최고 수준 디자인/모션 벤치마크 (디자인 트랙 연계)
- **Flutter 프로덕션 대표작:** Google Pay, Alibaba, BMW 앱, Toyota 2026 인포테인먼트, Nubank, eBay Motors, **Reflectly**(감성 UI/애니메이션 유명), talabat 등. 공식 showcase 참조.
- **Material 3 Expressive (Google I/O 2025):** 물리 기반(스프링) 모션, 유기적 셰이프, 감정·접근성 강조. Flutter M3E 구현 패키지/스킬 다수 등장.
- **모션 도구:** **Rive**(상태머신·데이터바인딩·GPU 벡터, 상태 반응형 마스코트/인터랙션에 최적, 60~120fps), **Lottie**(디자이너 제작 JSON, fire-and-forget 애니메이션에 적합). VGV 가이드: 상태 구동은 Rive, 단순 재생은 Lottie.
- 출처: https://flutter.dev/showcase ; https://medium.com/antigua-mobile/material-3-expressive-rethinking-emotion-accessibility-modern-ux-9f4c888d87c9 ; https://verygood.ventures/blog/rive-flutter-genui-integration/ ; https://dev.to/uianimation/building-high-performance-interactive-mascots-in-flutter-with-rive-production-guide-for-2026-17c6

---

## 4. 사용자 불만 테마 (경쟁 앱 리뷰·기사 기반)

1. **가격 부정확·시차** — GasBuddy 최다 불만(헛걸음). 크라우드소싱의 구조적 한계. → Oil Checker는 공공(VAN 자동보고) 데이터라 상대적 신뢰 우위이나, **"업데이트 시각 명시"**로 신뢰를 시각화해야 함. (Trustpilot/PissedConsumer)
2. **결제카드 트러블** — GasBuddy Pay+ declined·주유기 한도·환불 지연·고객지원 부실(집단소송). → 결제 연동은 신중히, 초기엔 "카드 할인 계산기"로 가볍게 진입.
3. **공공앱 트래픽 지연** — 오피넷 유가위기 시 대기열. → Oil Checker는 캐시(TTL 6h)·오프라인 폴백으로 **"위기 때 더 잘 되는 앱"** 포지션 가능. (IT동아)
4. **경로별 주유소 커버리지 부족** — 오피넷 3곳 vs 네이버 7곳. → Opinet aroundAll을 경로 샘플 좌표에 다중 호출/그리드 캐시로 커버리지 확보. (IT동아)
5. **정유사앱 락인·자사한정** — 크로스브랜드 비교 불가. → 중립 비교가 Oil Checker의 존재 이유.
6. **"추천만 하고 왜인지 설명 안 함"** — 오피넷 추천순은 근거·금액 불투명. → **"왜 이 주유소가 이득인지 원 단위로"** 정산 화면이 차별점.

---

## 5. Oil Checker 차별화 기회 Top 10

형식: 사용자 문제 / 경쟁 현황 / 제안 기능·UX / Opinet 무료 API 가능성 / 난이도(S·M·L) / 기대효과

**1. "원(₩) 단위 절약 정산 카드"**
- 문제: "싼데 먼 주유소, 진짜 이득?"(가장 흔한 고민). 경쟁: 오피넷=추천만, 아무도 금액 미정산. 제안: "여기 들르면 왕복 우회비용 −○원, 순절약 +₩1,420" 영수증형 카드 + 근거(가격차·우회거리·연비) 펼침. API: aroundAll+detailById로 충분(가능). 난이도: S(엔진 이미 존재, UI만). 효과: **핵심 차별화·바이럴 캡처(스샷 공유)**.

**2. 실연비 자동 학습 + 절약 누적 대시보드**
- 문제: 공인연비≠내 실연비, 절약 체감 없음. 경쟁: 오피넷=수동입력, Fuelio/Spritmonitor=기록 특화(가격비교 약함). 제안: 주유이력→실연비 자동 계산→경제성 엔진에 피드백, "이번 달 ₩○ 절약" 월간 리포트. API: 불필요(내부 DB). 난이도: M. 효과: 리텐션·차계부 카테고리 흡수.

**3. 카드 할인 반영 "실결제가"**
- 문제: 표시가≠실제 낸 돈(카드 40~150원/L, 페이 100원/L). 경쟁: 전무. 제안: 내 카드 프로필(예: KB 150원/L, NH 50원/L, NaverPay+GS 100원/L)→브랜드별 실결제가로 재랭킹. API: 가격은 Opinet, 할인은 정적 룰테이블(가능). 난이도: M. 효과: **어떤 경쟁도 못 하는 유니크 가치**.

**4. 목적지 우회 추천("가는 길에 넣기")**
- 문제: 주변만 보면 경로상 더 싼 곳 놓침. 경쟁: 오피넷 경로별=커버리지 부족(3 vs 7), 네이버=비교/정산 없음. 제안: 목적지 입력→경로 샘플점들에 aroundAll→우회 최소·절약 최대 정렬. API: aroundAll 다중호출(그리드/경로 샘플, 캐시로 예산 관리). 난이도: M~L. 효과: 오피넷 약점 정조준.

**5. 가격 예측·"지금 넣을까 미룰까" (시점 최적화)**
- 문제: 오늘 넣을지 내일 넣을지. 경쟁: 독일 mehr-tanken/ADAC·호주 ACCC 사이클=시점최적화 성숙, 국내 전무. 제안: Opinet avgAllPrice/avgSidoPrice 일별 추세→"이번 주 하락세, 3일 뒤 유리" 신호(예측 아닌 추세 기반). API: avgAllPrice/avgSidoPrice(가능, 3건/일 예산). 난이도: M. 효과: 국내 최초급 기능.

**6. 절약 리워드·게임화(비결제형)**
- 문제: 재방문 동기 부족. 경쟁: GasBuddy Rewards/챌린지, Upside 캐시백(단 결제/데이터 리스크). 제안: 결제 없이 "누적 절약 배지·연속 절약 스트릭·최저가 발견 뱃지". API: 불필요. 난이도: S~M. 효과: 리텐션(결제 리스크 회피).

**7. "위기에 강한 앱" — 오프라인·초경량 위젯**
- 문제: 유가위기 시 오피넷 대기열. 경쟁: 공공앱 트래픽 취약. 제안: 홈 위젯(주변 최저가·내 절약), 캐시 우선 즉시표시, "업데이트 시각" 명시. API: aroundAll(캐시 활용). 난이도: M(위젯). 효과: 신뢰·차별 포지션.

**8. 알림(가격 급락·최고가격제 위반 의심)**
- 문제: 언제 싸지는지 모름. 경쟁: 오피넷 알림 미검증, GasBuddy 가격알림 존재. 제안: 관심 지역/즐겨찾기 주유소 임계가 도달·전일 대비 급변 알림. API: aroundAll/detailById 주기 조회(예산 내). 난이도: M. 효과: 재방문 트리거.

**9. EV 겸용 로드맵(선택)**
- 문제: 하이브리드/EV 전환기. 경쟁: 카카오/네이버/Apple=충전 강함. 제안: 오피넷 충전소 가격(가능 시)·전기차 연비(kWh) 모드로 경제성 엔진 확장. API: Opinet 충전 데이터 확인 필요(부분). 난이도: L. 효과: 시장 확장(우선순위 낮음).

**10. 신뢰 시각화 + 데이터 출처 배지**
- 문제: 크라우드 앱 불신(GasBuddy 학습효과). 경쟁: GasBuddy 신뢰붕괴. 제안: "한국석유공사 Opinet 공식데이터 · ○분 전 갱신" 배지, 갱신 시각·출처 상시 노출. API: 불필요(메타). 난이도: S. 효과: 저비용 신뢰 우위.

**우선 실행 추천(ROI 순):** 1(절약정산 카드) → 3(카드 실결제가) → 2(실연비 대시보드) → 10(신뢰배지) → 4(목적지 우회). 1·10은 난이도 S로 즉시 착수 가능.

---

## 6. 포지셔닝 제안 (한 줄 가치제안 3안)

- **A안(정산 강조):** "추천은 오피넷도 한다. **얼마 아끼는지 원(₩)으로 계산해주는 건 Oil Checker뿐.**"
- **B안(내 차 학습):** "**내 실연비와 내 카드 할인**까지 계산한, 나만을 위한 최저가."
- **C안(신뢰+위기):** "**공공데이터로 정확하게, 기름값 오를수록 더 쓰는 앱.**"

권장: 오피넷 흡수 국면을 정면 대응하는 **A안**을 메인 카피로, B·C를 스토어 스크린샷 서브 카피로.

---

## 7. 출처 (URL + 확인일 2026-09-28)

국내 — 오피넷/시장:
- IT동아 "10년 만에 개편 오피넷…" (4요소 추천·연비자동·20km·경로별 개수·대기열 검증): https://www.donga.com/news/It/article/all/20260325/133606508/1
- 정유4사 담합 기소: https://en.sedaily.com/culture/2026/07/06/prosecutors-indict-four-refiners-over-alleged-26-trillion
- 카드 주유할인 40~150원 연장: https://www.chosun.com/english/market-money-en/2026/06/01/LSISQHL7JFAJFKHTGURKDUOOCU/
- KB 150원/L: https://www.chosun.com/english/market-money-en/2026/04/02/RFRCFRAZQRDVDHEJCET6CR3DAA/
- NH 50원/L: https://en.sedaily.com/finance/2026/06/12/nh-nonghyup-card-expands-fuel-subsidies-amid-high-inflation
- FSC 카드할인 확대 요청/유가 맥락: https://biz.chosun.com/en/en-finance/2026/03/29/Q6WYFXFYMNHOPIC72Q6RPDZ5VA/
- 착한주유소·TMAP: https://biz.chosun.com/en/en-it/2026/04/29/WCRRWAUL4RDKPKCLRVTXFNEQLI/
- TMAP Mobility 흑자: http://biz.chosun.com/en/en-it/2026/02/25/7JRXCUOU55G2LPXNL3H46LF3AI/
- NaverPay+GS칼텍스 100원/L: https://en.sedaily.com/society/2026/04/24/gs-caltex-becomes-first-korean-refiner-to-partner-with
- 카카오맵 신규 API: https://devtalk.kakao.com/t/api-4/150764
- 네이버 주유비 계산: https://help.naver.com/service/5637/contents/19073
- 착한주유소 라벨 논란(공급마진 42원): https://www.chosun.com/english/industry-en/2026/07/31/67QOW3N3PNEBTIVWU6BEYSSFSI/

국내 — 군소 앱:
- 오일맵: https://apps.apple.com/us/app/오일맵-최저가-주유소-지도/id6760611787
- 주유9: https://play.google.com/store/apps/details?id=com.softworx.gs

해외 — 앱:
- GasBuddy Pay+: https://www.gasbuddy.com/go/pay-with-gasbuddy-plus
- GasBuddy Rewards/25주년: https://www.gasbuddy.com/go/25-years
- GasBuddy 불만(Trustpilot): https://www.trustpilot.com/review/gasbuddy.com
- GasBuddy 불만(PissedConsumer 2.3/5): https://gasbuddy.pissedconsumer.com/review.html
- GasBuddy 집단소송: https://www.classaction.org/media/eubanks-v-gasbuddy-llc.pdf
- Waze 가격기능: https://www.bgr.com/2221942/how-get-best-fuel-saving-with-waze/
- Waze OPIS 피드: https://www.waze.com/discuss/t/announcement-new-us-gas-prices-feed-rolling-out/404520
- Google Maps eco route: https://support.google.com/maps/answer/11470237 ; https://developers.google.com/maps/documentation/routes/eco-routes
- Apple Maps EV/Charging Wallet: https://www.electrive.com/2025/08/14/apple-maps-introduces-ev-charging-function/ ; https://support.apple.com/guide/iphone/set-up-electric-vehicle-routing-iphc5e3a4b4b/ios
- Upside 작동/수익모델: https://www.upside.com/blog/how-does-upside-work-a-step-by-step-guide ; https://backtofrontshow.com/how-does-upside-make-money/
- Fuelio: https://play.google.com/store/apps/details?id=com.kajda.fuelio ; Drivvo: https://www.drivvo.com/en/personal-use/ ; Spritmonitor: https://apps.apple.com/us/app/spritmonitor-fuel-log-mpg/id616137163

해외 — 제도·예측:
- 독일 규정변경·최적시점: https://finance.yahoo.com/sectors/energy/articles/germany-sees-record-swings-fuel-075527199.html ; mehr-tanken: https://play.google.com/store/apps/details?id=de.msg
- 독일 3대 연료앱: https://www.thelocal.de/20241008/three-apps-to-help-drivers-in-germany-find-the-cheapest-fuel
- 영국 Fuel Finder(2025 규정): https://www.gov.uk/government/collections/road-fuel-price-data-scheme ; https://www.gov.uk/government/news/fuel-finder-for-drivers-factsheet
- 호주 ACCC 가격사이클: https://www.accc.gov.au/consumers/petrol-and-fuel/petrol-price-cycles-in-the-5-largest-cities ; https://www.accc.gov.au/media-release/there-are-tools-available-to-save-money-on-fuel

Flutter 디자인/모션:
- Flutter Showcase: https://flutter.dev/showcase
- Material 3 Expressive: https://medium.com/antigua-mobile/material-3-expressive-rethinking-emotion-accessibility-modern-ux-9f4c888d87c9
- Rive vs Lottie(VGV): https://verygood.ventures/blog/rive-flutter-genui-integration/
- Rive 프로덕션 가이드: https://dev.to/uianimation/building-high-performance-interactive-mascots-in-flutter-with-rive-production-guide-for-2026-17c6

---

## 부록 — AGENTS.md §6 P3 주장 검증 결과

**주장:** "오피넷 공식앱 v4.0.1(2026-02)이 연비 반영 종합 추천을 흡수."
**검증:** ✅ **사실**(버전 번호 자체는 이번 조사에서 별도 확인 못 함 = 미검증, 그러나 기능 흡수는 확정). IT동아(2026-03-25)가 개편 오피넷의 "추천순 = 거리+가격+**차량연비**+평균주유량 4요소 종합, 공인연비 자동제공+실연비 입력"을 명시. 단, **① 절약금액 원 단위 정산 없음 ② 실연비 자동추적 없음 ③ 경로별 주유소 커버리지 부족 ④ 정체/시간비용 미반영 ⑤ 트래픽 대기열**의 5개 빈틈이 실측·기사로 확인됨 → Oil Checker의 차별화 여지는 유효.
