import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/screens/car_setup_screen.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/presentation/ui_prefs.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';

/// 설정 화면 (하단 탭 4번)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allCarProfilesProvider);
    final active = ref.watch(activeCarProfileProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final monthly = ref.watch(monthlyFillCountProvider);
    final emphasis = ref.watch(savingsEmphasisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (active != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _ActiveCarCard(
                modelName: active.modelName,
                subtitle: '${_fuelLabel(active.fuelType)} · '
                    '${(active.latestRecordedKmPerL ?? active.manualFuelEfficiency ?? active.avgFuelEfficiency).toStringAsFixed(1)} km/L · '
                    '${active.tankSizeL.toStringAsFixed(0)}L',
              ),
            ),

          const AppSectionLabel('차량 프로필'),
          _Group(
            children: [
              ...profilesAsync.when(
                loading: () => [
                  const _RowTile(title: '불러오는 중…'),
                ],
                error: (e, _) => [_RowTile(title: '프로필 로드 실패: $e')],
                data: (profiles) => [
                  for (final p in profiles.where((p) => !p.isActive))
                    _RowTile(
                      title: p.modelName,
                      subtitle: '${_fuelLabel(p.fuelType)} · '
                          '${p.avgFuelEfficiency.toStringAsFixed(1)} km/L',
                      leading: _Avatar(text: p.brand),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: AppColors.mutedFaint),
                      onTap: () => ref
                          .read(appDatabaseProvider)
                          .setActiveCarProfile(p.id),
                    ),
                ],
              ),
              _RowTile(
                title: '차량 추가',
                leading: const _Avatar(icon: Icons.add),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CarSetupScreen(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const AppSectionLabel('계산 기준'),
          _Group(
            children: [
              _RowTile(
                title: '절약액 표기',
                subtitle: '절약순위 1위 카드에 적용돼요',
                trailing: _Segmented(
                  options: const ['월 환산', '1회당'],
                  selected: emphasis == SavingsEmphasis.monthly ? 0 : 1,
                  onChanged: (i) => ref
                      .read(savingsEmphasisProvider.notifier)
                      .set(i == 0
                          ? SavingsEmphasis.monthly
                          : SavingsEmphasis.perFill),
                ),
              ),
              _RowTile(
                title: '월 주유 횟수',
                subtitle: '절약액 월 환산에 쓰여요',
                trailing: _Stepper(
                  value: monthly,
                  onChanged: (v) =>
                      ref.read(monthlyFillCountProvider.notifier).set(v),
                ),
              ),
              if (active != null)
                _RowTile(
                  title: '연비 기준',
                  subtitle: active.latestRecordedKmPerL != null
                      ? '주행 기록 실연비를 사용 중'
                      : (active.manualFuelEfficiency != null
                          ? '직접 입력한 실연비를 사용 중'
                          : '표시연비를 사용 중'),
                  trailing: Text(
                    '${(active.latestRecordedKmPerL ?? active.manualFuelEfficiency ?? active.avgFuelEfficiency).toStringAsFixed(1)} km/L',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              if (active != null)
                _RowTile(
                  title: '연료 종류',
                  trailing: Text(
                    _fuelLabel(active.fuelType),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          const AppSectionLabel('앱'),
          _Group(
            children: [
              _RowTile(
                title: '다크 모드',
                subtitle: '야간 주행에 눈이 편해요',
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.best
                        : null,
                  ),
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.ink
                        : null,
                  ),
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .set(v ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              _RowTile(
                title: 'Opinet API 키',
                subtitle: '웹은 서버측 프록시가 주입, 네이티브는 빌드 시 dart-define',
                trailing: Text(
                  opinetApiKeyMasked(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const _RowTile(
                title: '앱 버전',
                trailing: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fuelLabel(String productCode) => switch (productCode) {
        OpinetClient.productDiesel => '경유',
        OpinetClient.productLpg => 'LPG',
        _ => '휘발유',
      };
}

/// 활성 차량 하이라이트 카드
class _ActiveCarCard extends StatelessWidget {
  const _ActiveCarCard({required this.modelName, required this.subtitle});

  final String modelName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.best,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.ink),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '활성',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드로 묶인 설정 그룹
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
    // 탭 가능한 행만 눌림 스케일 피드백
    return onTap == null ? tile : Pressable(child: tile);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.text, this.icon});

  final String? text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: icon != null
          ? Icon(icon, size: 18, color: scheme.onSurface)
          : Text(
              (text ?? '').isEmpty
                  ? '차'
                  : text!.substring(0, text!.length > 2 ? 2 : text!.length),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

/// 2지선다 세그먼트
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: AppMotion.curveStandard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i == selected
                      ? (isDark ? AppColors.best : AppColors.ink)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: i == selected
                        ? (isDark ? AppColors.ink : Colors.white)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// - / + 숫자 스테퍼
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove, value > 1 ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 42,
            child: Text(
              '$value회',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _button(Icons.add, value < 10 ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback? onTap) {
    return Pressable(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 17,
            color: onTap == null ? AppColors.mutedFaint : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
