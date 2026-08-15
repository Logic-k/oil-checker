import 'package:drift/wasm.dart';

/// drift 웹 워커 진입점
///
/// `dart compile js web/drift_worker.dart -o web/drift_worker.dart.js`로
/// 컴파일한 뒤 `web/`에 배치한다. 웹에서 IndexedDB 기반 SQLite를 동작시킨다.
/// (drift 공식 문서: https://drift.simonbinder.eu/platforms/web)
void main() {
  WasmDatabase.workerMainForOpen();
}
