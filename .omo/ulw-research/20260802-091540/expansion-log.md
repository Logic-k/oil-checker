# Expansion Log — Oil Checker 앱 설계 연구

세션: 20260802-091540
쿼리: Opinet 유가 + 차량 연비 + 우회 경제성을 결합한 "가장 경제적인 주유소 추천" 앱 설계 + 15,000건 API 한도 최적화

## Wave 1 (2026-08-02 09:15) — 포화 웨이브

| Worker | Axis | bg_id | ses_id | 상태 |
|---|---|---|---|---|
| librarian | Opinet API 구조 | bg_0af72ca9 | ses_0402bcdd8ffeRX1f1hNt7POYDr | 대기 |
| librarian | API 호출 한도 최적화 | bg_3dba6e8c | ses_0402bb8c3ffefsa9EstmKdW16y | 대기 |
| librarian | Flutter 아키텍처 | bg_13afcfff | ses_0402ba68cffeElvDHzFzxeVM3Y | 대기 |
| librarian | 우회 경제성 수학모델 | bg_7411bd84 | ses_0402b8e1fffe46zCYgQhDVkFnL | 대기 |
| librarian | 차종별 연비 데이터 | bg_c8039d55 | ses_0402b7905ffeD1Qa3l74ZxzZ2C | 대기 |
| librarian | 한국 지도 SDK 티어 | bg_c3e97145 | — | 대기 |
| librarian | 교통정체 API | bg_d3634bac | — | 대기 |
| librarian | 유사 앱/OSS | bg_fa7d0971 | — | 대기 |
| librarian | Flutter vs 대안 | bg_a7c71b81 | — | 대기 |
| librarian | Opinet 사이트 브라우징 | bg_2d0ef3b9 | — | 대기 |

Leads 열림: 0 / 닫힘: 0

## Wave 1 결과 (2026-08-02 09:30)
Wave 1 librarian 10개 워커 전원이 5분 이상 stall → 취소 (bg_0af72ca9, bg_3dba6e8c, bg_13afcfff, bg_7411bd84, bg_c8039d55, bg_c3e97145, bg_d3634bac, bg_fa7d0971, bg_a7c71b81, bg_2d0ef3b9). 수렴 대신 Orchestrator 직접 실행으로 전환.

## Wave 2 (2026-08-02 09:30~10:10) — 직접 실행 리서치
웹 검색 8회 + 실제 API 검증 4회 + 공식 문서 브라우징 3회 완료. 열린 축 전부 커버.

### 핵심 발견
1. **API 키 유효** ✅: `F251228319` 실측 검증 완료. 핵심 함정은 인증 파라미터 — 무료 유가정보 API는 **`code`**, 오픈API의 `certkey`와 다름. `certkey`는 HTTP 200+빈 배열 반환
2. **API 한도**: 무료 API 일일 호출 1,500건/일 (2025.05 가이드 PDF) — 사용자 문서의 "15,000건"과 상충
3. **엔드포인트**: aroundAll(반경내), lowTop10(최저가 TOP20), avgAllPrice(전국평균), avgSidoPrice(시도평균), avgSigunPrice(시군구평균), detailById(상세), avgRecentPrice 등 — 실측 동작 확인
4. **KATEC 좌표계**: Opinet은 KATEC(EPSG:5174) 사용, WGS84 변환 필요
5. **가격 갱신 주기**: 현재 판매가격 1·2·9·12·16·19시, 일일평균 24시, 주간평균 금요일 10시 → 갱신 스케줄 설계의 근거
6. **연비 데이터**: 한국에너지공단 자동차 표시연비 (data.go.kr 15139827/15083023, 2,800+ 모델)
7. **지도 SDK**: Naver 지도 API 무료 이용량 중단 이슈(2025.3.24 공지) → Kakao 지도(일 30만건 무료)가 더 적합
8. **가격 편차 실데이터**: 같은 동네 리터당 100~200원 차, 알뜰주유소 평균 50~100원 저렴 → 경제성 계산의 가치 입증
9. **우회 경제성 공식**: 절약액(가격차×주유량) vs 우회비용(우회거리×소모연비×유가) 비교

Leads 열림: 9 / 닫힘: 9 → **수렴**

## 산출물
- `SYNTHESIS.md` — 리서치 종합
- `Oil Checker PLAN.md` — 구체적 앱 설계 (최종 산출물)
