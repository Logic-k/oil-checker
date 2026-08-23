# Ultrawork Notepad - Oil Checker Flutter MVP
Started: 2026-08-02

## Plan (exhaustive, atomic)
- [x] Flutter 프로젝트 생성 (oil_checker/)
- [x] KATEC 좌표 변환 모듈 (TDD GREEN)
- [x] Opinet API 클라이언트 (code 파라미터, KATEC 변환)
- [x] Drift DB (주유소 캐시, 차량 프로필, 주유이력)
- [x] 연비 CSV 임베드 + 차량 프로필 (CarSpecLoader)
- [x] 경제성 계산 엔진
- [x] OpinetRepository TTL 캐시 (오프라인 우선)
- [ ] UI: 홈(지도+리스트), 경제적 주유소 랭킹, 주유이력, 설정
- [ ] Chrome 실행 검증 + APK 빌드

## Scenarios (the contract)
- S1 Happy: 유효 좌표로 aroundAll 호출 → 주유소 목록 표시 (HTTP 200 + OIL 배열)
- S2 Edge: 잘못된 좌표/빈 응답 → 에러 UI + 캐시 폴백
- S3 경제성: 가격차 계산 → 절약금액 랭킹 정렬 검증
- S4 차량: 차종 선택 → 연비 자동 입력
- S5 캐시: TTL 내 재호출 없음 (Drift에서 로드)

## Now
코어/데이터/도메인 레이어 완료 (37 tests GREEN).
프레젠테이션 레이어 (Riverpod Provider + 화면) 진행 중.

## Todo
(plan agent bg_de0c6068 21m+ running — 결과 수신 시 웨이브 조정)

## Findings
- Opinet 무료 API 파라미터는 code (certkey 아님) - 실측 검증
- 일일 1,500건 한도, 가격 갱신 1/2/9/12/16/19시
- 키 F251228319 유효, KATEC 좌표계
- proj4dart 2.1.0: lat_0/lon_0은 '38N' 단위접미사 불가 → 데시멀 각도 필수. Projection.WGS84 static 제공. ProjectionTuple(fromProj,toProj).forward() 사용.
- drift 2.31.0: 테이블명과 충돌 시 데이터클래스에 Data 접미사 (StationCacheData). isNull/isNotNull이 matcher와 충돌 → hide 필요.
- dio 5.11.0: 테스트용 커스텀 HttpClientAdapter + ResponseBody.fromString + content-type 헤더 필수 (JSON transformer).

## Learnings
- TDD RED: 테스트가 먼저 실패해야 함 (katec_test.dart가 모듈 부재로 실패 확인)
- proj4dart는 Point(x: lon, y: lat) 순서로 위경도 수용
- Repository 캐시 검증: fetch 횟수 카운트 adapter로 S5 확인
- drift_flutter 0.2.8 + drift 2.31.0 조합 (drift_flutter가 drift 하한 2.31 강제)
