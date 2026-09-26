import 'package:flutter/material.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';

/// 드라이브 모드 상단 플로팅 표시 — iOS Dynamic Island 스타일.
///
/// 평소엔 상단 중앙의 검은 알약(필)으로 최소 정보만 보여주고,
/// 탭하면 카드로 펼쳐져 상세를 보여준다. 버승버승 앱의 다이나믹
/// 아일랜드 표시에서 착안.
class DriveIsland extends StatelessWidget {
  const DriveIsland({
    super.key,
    required this.data,
    required this.expanded,
    required this.onToggle,
    this.speedKmh,
  });

  final DriveIslandData data;
  final bool expanded;
  final VoidCallback onToggle;

  /// 현재 속도 (km/h) — 접힌 알약 우측에 표시. 없으면 숨김.
  final double? speedKmh;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    final maxWidth = MediaQuery.sizeOf(context).width - 32;

    // 부모가 Align(topCenter)로 배치 — 여기서 다시 Center를 쓰면
    // 확장 공간을 채우며 수직 중앙으로 이동해 버린다.
    return Pressable(
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedSize(
          duration:
              reduce ? Duration.zero : const Duration(milliseconds: 320),
          curve: AppMotion.curveEnter,
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 320),
            curve: AppMotion.curveEnter,
            constraints: BoxConstraints(
              minWidth: expanded ? maxWidth : 0,
              maxWidth: maxWidth,
            ),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(expanded ? 24 : 999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedSwitcher(
              duration:
                  reduce ? Duration.zero : const Duration(milliseconds: 180),
              child: expanded
                  ? _IslandExpanded(
                      key: const ValueKey('expanded'), data: data)
                  : _IslandCollapsed(
                      key: const ValueKey('collapsed'),
                      data: data,
                      speedKmh: speedKmh,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 아일랜드에 표시할 데이터 — 화면이 provider 상태를 이 형태로 변환해 넘긴다.
class DriveIslandData {
  const DriveIslandData({
    required this.title,
    this.subtitle,
    this.priceText,
    this.savingsText,
    this.detailText,
    this.status = DriveIslandStatus.ready,
  });

  /// 주유소 이름 또는 상태 문구
  final String title;

  /// 상표·거리 등 부가 정보 (예: 'GS칼텍스 · 850m')
  final String? subtitle;

  /// '1,620원/L' 형태 가격
  final String? priceText;

  /// '+3,200원' 형태 절약액 (절약일 때만)
  final String? savingsText;

  /// 확장 시 하단 보조 지표 (예: '왕복 2.4km · 9분')
  final String? detailText;

  final DriveIslandStatus status;

  bool get isReady => status == DriveIslandStatus.ready;
}

enum DriveIslandStatus { loading, error, empty, ready }

class _IslandCollapsed extends StatelessWidget {
  const _IslandCollapsed({
    super.key,
    required this.data,
    this.speedKmh,
  });

  final DriveIslandData data;
  final double? speedKmh;

  @override
  Widget build(BuildContext context) {
    final speed = speedKmh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (data.status) {
              DriveIslandStatus.error => Icons.cloud_off_outlined,
              DriveIslandStatus.empty => Icons.local_gas_station_outlined,
              _ => Icons.local_gas_station,
            },
            size: 15,
            color: data.status == DriveIslandStatus.error
                ? Colors.white38
                : AppColors.best,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (data.savingsText != null) ...[
            const SizedBox(width: 8),
            Text(
              data.savingsText!,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.best,
              ),
            ),
          ],
          if (speed != null && speed > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${speed.round()}km/h',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IslandExpanded extends StatelessWidget {
  const _IslandExpanded({super.key, required this.data});

  final DriveIslandData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_gas_station,
                  size: 15, color: AppColors.best),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_up,
                  size: 18, color: Colors.white38),
            ],
          ),
          if (data.subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              data.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
          if (data.isReady) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (data.priceText != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: data.priceText!
                              .replaceAll('원/L', ''),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: '원/L',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (data.savingsText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          AppColors.best.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${data.savingsText} 아껴요',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.best,
                      ),
                    ),
                  ),
              ],
            ),
            if (data.detailText != null) ...[
              const SizedBox(height: 12),
              Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1),
              const SizedBox(height: 12),
              Text(
                data.detailText!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
