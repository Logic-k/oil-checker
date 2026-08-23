# SYNTHESIS — Oil Checker 앱 설계 연구 종합

세션: 20260802-091540
상태: 수렴 완료 (Wave 1 librarian 10개 취소 → Orchestrator 직접 실행으로 전환)

---

## 1. Opinet API (유가 정보) — 실측 검증 완료 ✅

### 1.1 API 키 유효 (✅ 사용자 제공 `F251228319`)
- 2026-08-02 실측 검증: `avgAllPrice.do`, `lowTop10.do`, `aroundAll.do`, `avgSidoPrice.do`, `detailById.do` 모두 **정상 응답** 확인.
- **핵심**: 무료 유가정보 API의 인증 파라미터는 **`code`** 이며, 오픈API(openApiInfo.do)의 `certkey`와 다름.
  - `certkey`로 호출 시 → HTTP 200 + **빈 `OIL` 배열** (오답의 함정)
  - `code=F251228319`로 호출 시 → 정상 데이터 반환
- 파라미터 `sido`/`sigun`/`area`는 **2자리 코드** (예: `sido=01` 서울). `areaCode.do`로 코드표 조회 가능.

### 1.2 호출 한도 (공식 가이드 기준)
- 무료 API: **일일 1,500건** (2025.05 무료API 이용가이드 PDF: "Call 제한 수 1,500(call/일)")
- 사용자 문서의 "15,000건"과 상충 → PLAN 예산은 일일 1,500건 기준 설계, 여유분 이상 절약.

### 1.3 핵심 엔드포인트 (실측 확인)
| 엔드포인트 | 용도 | 주요 파라미터 |
|---|---|---|
| `aroundAll.do` | 반경내 주유소 (기본 기능) | `x,y`(KATEC), `radius`(≤5000), `prodcd`, `sort`(1=가격,2=거리), `code` |
| `lowTop10.do` | 전국/지역별 최저가 TOP20 | `area`(선택, 2자리 시도/4자리 시군), `cnt`(1~20), `prodcd`, `code` |
| `avgAllPrice.do` | 전국 평균가 | `code` |
| `avgSidoPrice.do` | 시도별 평균가 | `sido`(2자리), `prodcd`, `code` |
| `avgSigunPrice.do` | 시군구별 평균가 | `sido`(2자리), `sigun`(선택), `prodcd`, `code` |
| `detailById.do` | 주유소 상세 (브랜드/가격/부대시설) | `id`(UNI_ID), `code` |

- 가이드에 존재하는 추가 엔드포인트: `avgRecentPrice.do`, `pollAvgRecentPrice.do`, `areaAvgRecentPrice.do`, `avgLastWeek.do`, `searchByName.do`, `taxfree*`, `ureaPrice.do`, `areaCode.do`, `dateAvgRecentPrice.do` 등
- `prodcd`: B027 보통휘발유 / B034 고급휘발유 / D047 경유 / C004 실내등유 / K015 자동차부탄
- 응답 주요 필드 (실측):
  - 목록: `UNI_ID`, `PRICE`, `POLL_DIV_CD`(상표), `OS_NM`, `VAN_ADR`, `NEW_ADR`, `GIS_X_COOR`, `GIS_Y_COOR`(KATEC), `DISTANCE`(aroundAll, m)
  - 상세: + `TEL`, `SIGUNCD`, `LPG_YN`, `MAINT_YN`, `CAR_WASH_YN`, `KPETRO_YN`, `CVS_YN`, `GOOD_YN`, `OIL_PRICE[]`
  - 평균가: `TRADE_DT`, `PRODCD`, `PRODNM`, `PRICE`, `DIFF`
- 상표코드: SKE(SK에너지), GSC(GS칼텍스), HDO(현대오일뱅크), SOL(S-OIL), RTE·RTX·RTO(알뜰), NHO(농협), ETC(자가상표), E1G, SKG

### 1.4 좌표계 — KATEC (⚠️ 설계 함정)
- Opinet API는 **WGS84(위경도)가 아닌 KATEC 좌표계** 사용. `GIS_X_COOR`, `GIS_Y_COOR`가 KATEC 미터 좌표.
- 변환: proj4js `+proj=tmerc +lat_0=38N +lon_0=128E +ellps=bessel +x_0=400000 +y_0=600000 +k=0.9999 +units=m +towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43` (EPSG:5174)
- 모바일 GPS는 WGS84 → **호출 전 WGS84→KATEC 변환 필수**. Flutter는 `proj4dart` 또는 자체 상수로 구현.

### 1.5 가격 갱신 주기 (캐시 TTL 설계 근거)
- 카드 단말기 단가 수집분 반영 시각: **1시, 2시, 9시, 12시, 16시, 19시**
- 직접보고(주유소 자발)는 즉시 반영.
- → 앱 캐시 TTL은 19시 갱신분을 기준으로 "익일 1시까지" 유효하게 설계. 전국평균/지역평균은 하루 1회 호출로 충분.

---

## 2. 가격 편차 실데이터 (경제성 기능의 근거)

- 같은 동네 주유소 간 **리터당 100~200원 차이** 실측 (2026-03 기준, MTN/groundche).
- 알뜰주유소는 일반 브랜드 대비 **평균 50~100원/L 저렴** (석유공사 공동구매 효과). 일부 150원 이상.
- 가득 주유(50L) 시 주유소 선택에 따라 **1회 5,000~10,000원 절약** 가능.
- → "가장 경제적인 주유소 자동 판단" 기능의 시장 가치 충분.

---

## 3. 차종별 연비 데이터

### 3.1 데이터 소스
- **한국에너지공단_자동차 표시연비 목록 조회 서비스** (data.go.kr /15139827/openapi.do) — 연비 조회 API
- **한국에너지공단_자동차 표시연비 정보** (data.go.kr /15083023/fileData.do) — **CSV 파일데이터, 로그인 불필요, 2,800+ 모델** (모델명/제조사/차종/복합연비/도심연비/고속도로연비/등급/1회충전 주행거리)
- 파일데이터는 주기적으로 갱신 → 앱에 번들(임베드)하고 버전 업데이트로 갱신하는 방식이 무료 API 1,500건 한도를 아끼는 최선.

### 3.2 활용 전략
- 차종 선택 UI에서 모델명 검색 → 복합연비 자동 입력 (사용자가 연비를 모를 때 기본값)
- 사용자가 직접 입력한 "최근 실연비"가 있으면 그 값을 우선 사용 (정확도 우선)
- OBD/자동 기록은 후순위 (현 단계는 수동 입력 + 평균 연비 자동 입력)

---

## 4. 지도 SDK (2026년 기준 선택)

### 4.1 Naver 지도 — ⚠️ 이슈
- 2025.3.24 공지: **AI NAVER API 내 지도 API 상품은 신규 이용 신청 차단 및 무료 이용량 제공 중단 예정** → 신규 앱에 Naver 지도 채택은 위험.
- 기존 `flutter_naver_map` 사용자도 인증 정책 변경 이슈 발생 중.

### 4.2 Kakao 지도 — 권장
- **일 300,000건 무료** (지도 SDK, 좌표계 변환 포함) → Opinet 1,500건 한도와 비교해 여유 충분.
- `kakao_map_flutter` 또는 `kakao_map_plugin` (webview 기반, 검증 필요).
- Flutter 네이티브 지도 대안: `flutter_map`(OSM) — 국내 주유소 상세 지도로는 Kakao가 UX 우위.

### 4.3 판단
- **지도는 Kakao 지도 SDK**, 유가는 Opinet, 위치는 `geolocator`(WGS84) 조합이 최적.

---

## 5. 교통정체 (후순위 과제)

- T-map API `https://apis.openapi.sk.com/tmap/traffic` (appKey 필요) — congestion 0~4 (0 정보없음, 1 원활, 2 서행, 3 지체, 4 정체), speed 포함.
- 국토교통부 교통소통정보 (data.go.kr /15040463) — 무료, 행정구역별/링크별 소통정보.
- **MVP에서는 제외**, v1.1 후순위로 명시.

---

## 6. 우회 경제성 수학 모델 (핵심 로직)

```
절약액(L) = (주유소A가격 - 주유소B가격) × 주유량(L)
우회비용(원) = 우회거리(km) × 연비소모(L/km) × 유가(원/L)
           = 우회거리(km) ÷ 연비(km/L) × 유가(원/L)
경제성 판단: 절약액 > 우회비용 + α(시간가치) → 우회 권장
```

- 우회거리 = 내 위치 → 우회주유소 → 목적지 (편도 기준 왕복 아님, 주유 후 목적지로 진행하는 상황 가정).
- 주유량: 사용자 입력(보통 가득 50L or 월 사용량 기준) 또는 자동차 연료탱크 용량.
- 시간가치 α: km당 정체 페널티는 후순위 (MVP는 정체 무시).
- **핵심 UX**: 비교 결과를 "주유하면 3,000원 절약됩니다" 형태로 단순 표시.

---

## 7. Flutter 아키텍처 방향

- 상태관리: Riverpod 3.x (컴파일 타임 안전, 가벼움) — 블루프린트 출처: dev.to "Offline-first Flutter implementation blueprint"
- 로컬 DB: Drift (SQLite, 타입세이프, 마이그레이션) — 주유소 캐시/주유이력/차량 프로필 저장
- 오프라인 우선 패턴: Repository 패턴 + 로컬 캐시 우선 → 백그라운드에서 API 갱신
- 네트워크: `dio` + Opinet XML 파서 (`xml` 패키지)

---

## 8. 경쟁/참고 서비스

- 오피넷 공식 앱 (com.lge.opinet): 내주변/지역별/고속도로/경로별/관심주유소/챗봇 — **"경제성 계산" 기능은 없음 → 차별화 포인트**
- OSS 참고: `eigger/hass-opinet` (홈어시스턴트 통합, 갱신 시각 활용), `KimJintak/opinet-mcp` (TypeScript MCP 서버)
