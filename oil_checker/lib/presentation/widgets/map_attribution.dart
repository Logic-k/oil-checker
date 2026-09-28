import 'package:flutter/material.dart';

/// OpenStreetMap 표준 타일 — 이용 정책(https://operations.osmfoundation.org/policies/tiles/)
///
/// 정책상 필수: 지도 위에 **항상 보이는** 저작권 표기(토글·UI 뒤에 숨기지 않기)와
/// 앱을 식별할 수 있는 User-Agent. 둘 중 하나라도 어기면 예고 없이 차단될 수 있다.
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// 타일 요청 User-Agent의 앱 식별자 (flutter_map `userAgentPackageName`)
///
/// 네이티브에서 `flutter_map (com.oilchecker.oil_checker)` 형태로 전송된다.
/// 웹은 브라우저가 UA를 정하므로 Referer로 식별된다.
const String kTileUserAgentPackage = 'com.oilchecker.oil_checker';

/// 지도 저작권 표기 — '© OpenStreetMap contributors'
///
/// 지도가 보이는 영역의 모서리에 둔다. 홈은 바텀시트 바로 위, 상세는 지도 히어로
/// 오른쪽 아래.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }
}
