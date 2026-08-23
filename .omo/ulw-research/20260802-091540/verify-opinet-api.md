# Verify: Opinet API 키 및 엔드포인트 검증

날짜: 2026-08-02
방법: 오케스트레이터 직접 실행 검증 (Invoke-RestMethod / webfetch)

## 결과 요약

### 1. 제공된 키 `F251228319` — **유효하지 않음 (10자리, 오피넷 키는 20자리)**
- `lowTop10.do?out=json&prodcd=B027&cnt=3&certkey=F251228319` → `{"RESULT":{"OIL":[]}}` (빈 배열)
- **키 없이 호출해도 동일한 빈 배열 반환** → 빈 배열은 무효 키의 신호로 해석됨
- `aroundAll.do` (반경내 주유소) → 동일하게 빈 배열
- `avgSidoPrice.do` (시도별 평균) → 동일하게 빈 배열
- 결론: 사용자가 제시한 키는 잘렸거나 잘못 기재됨. 실제 오피넷 회원가입 후 발급받는 20자리 키 필요.
  - ⚠️ 사용자에게 키 재확인 필요 (보고해야 할 항목)

### 2. Opinet API 공식 문서 확인 (www.opinet.co.kr/user/custapi/)
- 개발가이드: https://www.opinet.co.kr/user/custapi/custApiGruide.do
- 오픈API 정보: https://www.opinet.co.kr/user/custapi/openApiInfo.do
- 인증키 발급: https://www.opinet.co.kr/user/custapi/openApiNew.do
- 무료 API: 주유소 전국/시도별/시군구별 평균가격(현재), 최근 5일간 전국 평균유가, 전국/지역별 최저가 주유소(Top 10)
- 유료 API: 상호로 주유소 검색, 주유소 상세정보(ID), 주유소 검색(지도내/전국/지역), 반경내 주유소(Top 10), 가격검색(지역별), 시도/시군구코드 검색, 변경정보 검색
- **오픈API (무료):** 주유소 상세정보(ID), 반경내 주유소 검색(aroundAll), 지역코드 조회, 최저가 TOP20, 전국 평균가격

### 3. 반경내 주유소 API 상세 (aroundAll.do) — 핵심 엔드포인트
```
URL: https://www.opinet.co.kr/api/aroundAll.do
파라미터: certkey(필수), out(xml/json 필수), x(필수, KATEC X좌표), y(필수, KATEC Y좌표),
          radius(필수, 최대 5000m), prodcd(필수, B027 휘발유/D047 경유/B034 고급/C004 실내등유/K015 자동차부탄),
          sort(필수, 1 가격순/2 거리순)
반환: UNI_ID, POLL_DIV_CD(상표), OS_NM(상호), PRICE(가격), DISTANCE(거리m), GIS_X_COOR, GIS_Y_COOR
예시: https://www.opinet.co.kr/api/aroundAll.do?out=xml&x=314681.8&y=544837&radius=5000&sort=1&prodcd=B027&certkey=[인증키]
```

### 4. 최저가 TOP10 API (lowTop10.do)
```
URL: https://www.opinet.co.kr/api/lowTop10.do
파라미터: certkey, out, prodcd, area(선택, 시도코드 2자리/시군코드 4자리), cnt(1~20)
반환: UNI_ID, PRICE, POLL_DIV_CD, OS_NM, VAN_ADR(지번), NEW_ADR(도로명), GIS_X_COOR, GIS_Y_COOR
```

### 5. 핵심 설계 시사점
- **KATEC 좌표계 사용** (위경도 아님!) — 앱에서 위경도↔KATEC 변환 필요
  - KATEC = Korean Total Coordinate System, UTM 유사 (한국 한정)
- radius 최대 5km — 5km 반경 1회 호출로 주변 주유소 일괄 획득 가능 (배치 설계에 유리)
- 무료 키는 평균가격/최저가/Top10 계열 + aroundAll(반경내) + 상세정보(ID)
- 검증되지 않은 키로는 빈 배열 → 앱 개발 시 키 유효성 사전 검증 로직 필요
