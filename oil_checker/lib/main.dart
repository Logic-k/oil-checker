import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/ui_prefs.dart';
import 'package:oil_checker/presentation/screens/car_setup_screen.dart';
import 'package:oil_checker/presentation/screens/history_screen.dart';
import 'package:oil_checker/presentation/screens/home_screen.dart';
import 'package:oil_checker/presentation/screens/ranking_screen.dart';
import 'package:oil_checker/presentation/screens/settings_screen.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';

void main() {
  runApp(const ProviderScope(child: OilCheckerApp()));
}

class OilCheckerApp extends ConsumerWidget {
  const OilCheckerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Oil Checker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const HomeShell(),
    );
  }
}

/// 하단 탭 셸 — 홈(지도+리스트) / 절약순위 / 주유이력 / 설정
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeCarProfileProvider);
    final hasProfile = profileAsync.value != null;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const AppSkeleton(),
        error: (e, _) => AppEmptyView(
          icon: Icons.error_outline,
          title: '데이터베이스를 열 수 없어요',
          message: '$e',
        ),
        data: (profile) => profile == null
            ? const CarSetupScreen()
            : IndexedStack(
                index: _index,
                children: const [
                  HomeScreen(),
                  RankingScreen(),
                  HistoryScreen(),
                  SettingsScreen(),
                ],
              ),
      ),
      bottomNavigationBar: hasProfile
          ? AppNavBar(
              index: _index,
              onChanged: (i) => setState(() => _index = i),
            )
          : null,
    );
  }
}

/// 하단 내비게이션 — 라벨을 짧게(경제적 주유소 → 절약순위) 다듬은 커스텀 바
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <({IconData icon, IconData active, String label})>[
    (icon: Icons.home_outlined, active: Icons.home, label: '홈'),
    (
      icon: Icons.bar_chart_outlined,
      active: Icons.bar_chart,
      label: '절약순위'
    ),
    (icon: Icons.schedule_outlined, active: Icons.schedule, label: '주유이력'),
    (icon: Icons.settings_outlined, active: Icons.settings, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.best : AppColors.ink;
    final idleColor = isDark ? AppColors.darkMutedSoft : AppColors.mutedSoft;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == index ? _items[i].active : _items[i].icon,
                          size: 23,
                          color: i == index ? activeColor : idleColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == index
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: i == index ? activeColor : idleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
