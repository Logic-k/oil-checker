import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/ui_prefs.dart';
import 'package:oil_checker/presentation/screens/car_setup_screen.dart';
import 'package:oil_checker/presentation/screens/history_screen.dart';
import 'package:oil_checker/presentation/screens/home_screen.dart';
import 'package:oil_checker/presentation/screens/ranking_screen.dart';
import 'package:oil_checker/presentation/screens/settings_screen.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/splash_intro.dart';

void main() {
  // 네이티브 스플래시를 Flutter 첫 프레임까지 유지 → 로딩 점프컷 방지
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
///
/// 탭 전환은 PageView.animateToPage(좌우 슬라이드) — IndexedStack과 달리
/// 전환 애니메이션이 있고, _KeepAliveTab으로 각 탭의 지도/스크롤 상태를 유지한다.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _pageController = PageController();
  int _index = 0;
  bool _splashRemoved = false;

  /// 첫 실행 연료 게이지 인트로 — 앱 실행당 1회 (이 State는 앱 수명과 같음)
  bool _introDone = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 400),
      curve: AppMotion.curveEnter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeCarProfileProvider);
    final hasProfile = profileAsync.value != null;

    // 스플래시는 프로필 로딩이 끝나는 순간까지 유지한다
    if (!_splashRemoved && !profileAsync.isLoading) {
      _splashRemoved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 테스트/미지원 플랫폼에서는 채널이 없을 수 있어 조용히 무시
        try {
          FlutterNativeSplash.remove();
        } catch (_) {}
      });
    }

    final reduceMotion = AppMotion.reduceMotion(context);

    return Stack(
      children: [
        Scaffold(
          body: _FadeInOnce(
            child: profileAsync.when(
              loading: () => const AppSkeleton(),
              error: (e, _) => AppEmptyView(
                icon: Icons.error_outline,
                title: '데이터베이스를 열 수 없어요',
                message: '$e',
              ),
              data: (profile) => profile == null
                  ? const CarSetupScreen()
                  : PageView(
                      controller: _pageController,
                      // 하단 탭 앱 — 스와이프는 막고 탭 시 슬라이드 전환만
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _KeepAliveTab(child: HomeScreen()),
                        _KeepAliveTab(child: RankingScreen()),
                        _KeepAliveTab(child: HistoryScreen()),
                        _KeepAliveTab(child: SettingsScreen()),
                      ],
                    ),
            ),
          ),
          bottomNavigationBar: hasProfile
              ? AppNavBar(index: _index, onChanged: _onTab)
              : null,
        ),
        // 첫 프레임 위에 덮는 인트로 — 네이비 스플래시에서 자연스럽게 이어짐
        if (!_introDone && !reduceMotion)
          Positioned.fill(
            child: SplashIntro(onDone: () => setState(() => _introDone = true)),
          ),
      ],
    );
  }
}

/// 첫 프레임 1회 페이드인 — 스플래시(ink 배경)에서 콘텐츠로의 연결
class _FadeInOnce extends StatelessWidget {
  const _FadeInOnce({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: AppMotion.curveEnter,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: child,
    );
  }
}

/// PageView 자식의 상태(지도 카메라·스크롤 위치)를 탭 전환 후에도 유지
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 하단 내비게이션 — 라벨을 짧게(경제적 주유소 → 절약순위) 다듬은 커스텀 바
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <({IconData icon, IconData active, String label})>[
    (icon: Icons.home_outlined, active: Icons.home, label: '홈'),
    (icon: Icons.bar_chart_outlined, active: Icons.bar_chart, label: '절약순위'),
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
                        _NavIcon(
                          icon: i == index ? _items[i].active : _items[i].icon,
                          active: i == index,
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

/// 탭 아이콘 — 활성화될 때 스프링으로 통통 튀는 팝
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!active || AppMotion.reduceMotion(context)) {
      return Icon(icon, size: 23, color: color);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(icon),
      tween: Tween(begin: 0.75, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Icon(icon, size: 23, color: color),
    );
  }
}
