# Verify — Build/Test/Dependency state (2026-08-15)

Orchestrator direct verification, Phase 3. Environment: Windows, Flutter 3.41.5 stable (2026-03-17), Dart 3.11.3, cwd `E:\OpenCode_OilMaker\oil_checker`.

## flutter analyze
- Result: **3 issues, all `info` level**, all in `tool/katec_probe.dart` (avoid_print) — README claim "0 issues (tool/katec_probe.dart print 제외)" confirmed. lib/ is clean.

## flutter test
- Result: **All 66 tests passed** (`00:04 +66: All tests passed!`). README claims 64 → actual now 66.
- Coverage of economy engine confirmed in output: EconomyEngine.calculateEconomy (절약액, 우회비용, 시간비용, 경제성점수, isSavings, 주유량 0L), computeDetourKm (목적지 왕복 2배), applyCongestion (1.5배), 랭킹 정렬, ranking_screen 정체 배너, OsrmClient.table 예외.

## flutter pub outdated — dependency upgrade paths (direct deps)
| package | current | resolvable | latest | notes |
|---|---|---|---|---|
| csv | 6.0.0 | 8.0.0 | 8.0.0 | major bump |
| drift | 2.31.0 | 2.34.3 | 2.34.3 | minor |
| drift_flutter | 0.2.8 | 0.3.1 | 0.3.1 | minor |
| flutter_riverpod | 3.3.2 | 3.3.2 | 3.4.2 | minor (resolvable은 3.3.2로 제한) |
| geolocator | 13.0.4 | 14.0.3 | 14.0.3 | major bump |
| latlong2 | 0.9.1 | 0.10.1 | 0.10.1 | minor |
| proj4dart | 2.1.0 | 3.0.0 | 3.0.0 | major bump |
| sqlite3_flutter_libs | 0.5.42 | 0.6.0+eol | 0.6.0+eol | **+eol tag — 수명종료 표시 주목** |
| build_runner | 2.15.1 | 2.15.1 | 2.16.0 | dev |
| drift_dev | 2.31.0 | 2.34.0 | 2.34.5 | dev |
| sqlite3 (transitive) | 2.9.4 | 3.5.1 | 3.5.1 | major |

Total: 33 packages have newer versions incompatible with current constraints.
Observation: `pubspec.yaml` declares drift `^2.28.0`, riverpod `^3.0.0` — constraint ranges would allow newer (2.34.x / 3.4.x) but lockfile/transitive pins hold them back (likely drift_flutter 0.2.8 pin). Major bumps (geolocator 14, proj4dart 3, sqlite3_flutter_libs 0.6+eol) need deliberate migration + regression testing.

## Build artifacts (2026-08-15 snapshot)
- `build/web`: **38.6 MB, 43 files** — web release build. Large for a Flutter web app (CanvasKit wasm + fonts). Optimization lead for L4.
- `app-release.apk`: **57.2 MB** (debug: 172.3 MB). Above 50MB threshold — Play size pressure; AAB/split-per-abi would help.
- `assets/data/car_fuel_economy.csv`: **367.7 KB, 4,204 lines** — embedded asset (~2,800 models). Minor; gzip/lazy-load possible.

## git
- Neither `E:\OpenCode_OilMaker` nor `oil_checker\` is a git repo → **no version control**. Significant improvement lead.
