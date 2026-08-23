# Expansion Log — Oil Checker 구현현황 정리 + 개선방향 리서치

세션: 20260815-221929
쿼리: 지금까지 만든 Oil Checker 앱(Flutter)의 현황 정리 + 리서치 기반 개선 방향
문맥: 이전 세션 20260802-091540은 "설계/PLAN" 연구였음. 이번은 **구현 완료된 앱** 기준. 앱: Opinet 유가 + 차량 연비 + 우회거리 기반 경제성 랭킹. 웹(Vercel) + Android. lib/ 23파일, test/ 11파일, 66 tests 통과.

## Wave 1 (2026-08-15 22:19) — 포화 웨이브 (8 워커 병렬 + 검증)

| Worker | Axis | bg_id | ses_id | 상태 |
|---|---|---|---|---|
| explore | 구현 인벤토리 vs PLAN | bg_e894affe | ses_ffa6bb37dffelpuEdV60NFntez | 대기 |
| explore | 코드 품질 & 기술부채 | bg_c68dfa7f | — | 대기 |
| explore | 테스트 커버리지 갭 | bg_0ce2045a | — | 대기 |
| librarian | OSRM 서버 정책 & 라우팅 대안 | bg_cc8174db | — | 대기 |
| librarian | Opinet 2026 현황 & 키 보안 | bg_c11404d5 | — | 대기 |
| librarian | Riverpod3+Drift 모범사례 2026 | bg_774ddd17 | — | 대기 |
| librarian | Flutter 웹/Android 최적화 | bg_a731c627 | — | 대기 |
| librarian | 경쟁앱/기능 트렌드 | bg_6b7f3df2 | — | 대기 |

Leads 열림: 0 / 닫힘: 0

### 검증 (orchestrator 직접, verify-build-state.md)
- analyze 3 info (tool print만) ✅ / test 66 pass ✅ / pub outdated 33개 → 상당수 major bump (geolocator 14, proj4dart 3, sqlite3_flutter_libs 0.6+eol)
- git repo 아님 → 버전관리 부재 (리드)

## Wave 1 결과 — 워커 8개 전부 취소, 직접 실행 전환

| Worker | Axis | 상태 | 처리 |
|---|---|---|---|
| explore | 구현 인벤토리 vs PLAN | 대기(취소) | orchestrator 직접: codegraph 인벤토리 |
| explore | 코드 품질 & 기술부채 | 대기(취소) | orchestrator 직접: legacy.dart, dynamic dispatch |
| explore | 테스트 커버리지 갭 | 대기(취소) | orchestrator 직접: test 파일 분포 확인 |
| librarian | OSRM 정책 & 대안 | 대기(취소) | orchestrator 직접: 데모 서버 정책 + Kakao/Naver/TMAP 쿼터 |
| librarian | Opinet 2026 & 키 보안 | 대기(취소) | orchestrator 직접: certkey/code 불일치 확인 |
| librarian | Riverpod3+Drift | 대기(취소) | orchestrator 직접: sqlite3 3.x 마이그레이션 경로 |
| librarian | Flutter 최적화 | 대기(취소) | orchestrator 직접: CanvasKit/wasm/번들 |
| librarian | 경쟁앱/기능 트렌드 | 대기(취소) | orchestrator 직접: 오피넷 v4.0.1 리뉴얼 (핵심) |

원인: 환경 동시성 슬롯 = 1 → 병렬 워커 대기열에서 stall (첫 워커 296s+ 무응답). 이전 세션과 동일 패턴. 이후 백그라운드 재스폰 금지, 직접 실행 유지.

## Wave 2 — 직접 실행 리서치 결과 요약 (2026-08-15, 완료)

- **OSRM**: map.project-osrm.org/about.html — "1 request per second max, no heavy usage"; GitHub issue #7162 (2025-05) 과부하/차단 이력; 데모 서버는 운영 SLA 없음 → 프로덕션 부적합 확정.
- **라우팅 대안 쿼터**: Kakao 자동차 길찾기 10,000/일, 다중경유지 5,000/일, 다중출발지 1,000/일, 지도 SDK 300,000/일 (developers.kakao.com/docs/ko/getting-started/quota). Naver Directions 5 60,000/월 (goal 최대 10, 최저비용 경로 1건만 반환), Directions 15 3,000/월. TMAP 자동차경로안내 1,000/일, 경로매트릭스 20/일, 데이터 저장 24h 제한. → **행렬 1콜 대체는 자체 OSRM이 유일**, Naver N콜/후보축소 조합 가능.
- **sqlite3 EOL**: sqlite3_flutter_libs 0.6.0+eol = 수명종료, 빈 패키지. drift 2.32.0+는 sqlite3 3.x 내장 (native는 hooks로 자동 번들). wger-project PR #1155: EOL 버전이 Android에서 libsqlite3.so 미번들 → DriftRemoteException 크래시 실사례. 마이그레이션: `sqlite3_flutter_libs` 제거 + `drift ^2.34` + `drift_flutter` `driftDatabase()`.
- **Riverpod 3**: StateProvider/StateNotifierProvider/ChangeNotifierProvider → `flutter_riverpod/legacy.dart` 이동 (3.0 마이그레이션 가이드). 앱이 정확히 이 반패턴 사용 중 (providers.dart:6).
- **Opinet 인증**: 공식 문서 요청 파라미터는 `certkey` (avgAllPrice/detailById/aroundAll). 앱은 `code` 사용 (클라이언트 주석: "무료 API는 code, certkey 아님" — 2026-08-02 실측). → 실행 검증은 됐지만 공식 문서와 불일치, 재확인 필요 리드. 일일 한도 1,500건(코드) vs 사용자 문서 15,000건 — 불일치.
- **경쟁 (핵심)**: 오피넷 공식앱 v4.0.1 (2026-02) 전면 리뉴얼 — "추천순" 도입: **거리+가격+차량연비+평균주유량 4요소 종합**, 공인연비 자동제공+실연비 직접입력, 검색반경 20km, 장소명 검색, 경로별 주유소(개수 부족 단점: 동일경로 오피넷 3곳 vs 네이버 7곳). → **Oil Checker 핵심 차별화 희석** — 실연비 기반 절약금액·우회거리·시간비용·정체 반영·주유이력 활용 등으로 재차별화 필요.
- **Flutter 최적화**: 공식 가이드 — CanvasKit ~1.5MB, dart2wasm 실험적, deferred imports, 폰트/에셋 정리. 웹 38.6MB/43파일, APK 57.2MB.

## Wave 2 완료 → SYNTHESIS.md 작성 → 최종 보고
