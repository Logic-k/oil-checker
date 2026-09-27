import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_checker/core/opinet/opinet_client.dart';
import 'package:oil_checker/core/theme/app_motion.dart';
import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/data/car_spec/car_spec_loader.dart';
import 'package:oil_checker/presentation/providers.dart';
import 'package:oil_checker/presentation/widgets/app_state_views.dart';
import 'package:oil_checker/presentation/widgets/car_image.dart';
import 'package:oil_checker/presentation/widgets/motion_widgets.dart';

/// 차량 등록 온보딩 — 2단계
///
/// STEP 1: 차량 검색·선택 / STEP 2: 탱크 용량·실연비
/// 저장 로직(upsertCarProfile)은 기존과 동일하다.
class CarSetupScreen extends ConsumerStatefulWidget {
  const CarSetupScreen({super.key});

  @override
  ConsumerState<CarSetupScreen> createState() => _CarSetupScreenState();
}

class _CarSetupScreenState extends ConsumerState<CarSetupScreen> {
  final _searchController = TextEditingController();
  final _tankController = TextEditingController(text: '50');
  final _manualEfficiencyController = TextEditingController();

  Timer? _debounce;
  String _query = '';
  CarSpecEntry? _selected;

  /// 모델 데이터로 자동 채워진 탱크 용량이 있는지 (수정 가능 안내용)
  bool _tankAutoFilled = false;

  /// 선택 차종이 전기·수소차로 판별됐는지
  bool _selectedIsEv = false;
  int _step = 0;
  bool _saving = false;

  static const _tankPresets = [50.0, 67.0, 80.0];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tankController.dispose();
    _manualEfficiencyController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  String _mapFuelType(String fuelType) {
    if (fuelType.contains('경유')) return OpinetClient.productDiesel;
    if (fuelType.contains('LPG')) return OpinetClient.productLpg;
    return OpinetClient.productGasoline;
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null) return;

    final tankSize = double.tryParse(_tankController.text.trim());
    if (tankSize == null || tankSize <= 0) {
      _showError('탱크 용량을 올바르게 입력해주세요.');
      return;
    }
    final manual = double.tryParse(_manualEfficiencyController.text.trim());

    setState(() => _saving = true);
    try {
      await ref.read(appDatabaseProvider).upsertCarProfile(
            id: null,
            modelName: selected.modelName,
            brand: selected.manufacturer,
            fuelType: _mapFuelType(selected.fuelType),
            tankSizeL: tankSize,
            avgFuelEfficiency: selected.combinedKmPerL,
            manualFuelEfficiency: manual,
            isActive: true,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // 성공 해피 모먼트 — 체크가 그려지는 오버레이를 잠깐 보여준다
      await _showSuccessOverlay();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError('차량 등록 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 등록 완료 오버레이 — 체크 애니메이션 + 짧은 홀드 후 자동 닫힘
  Future<void> _showSuccessOverlay() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '등록 완료',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) => const _SuccessOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: AppMotion.curveStandard,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              // STEP 전환 — 오른쪽에서 슬라이드+페이드
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: AppMotion.curveEnter,
                switchOutCurve: AppMotion.curveExit,
                transitionBuilder: (child, animation) {
                  final isIncoming = child.key == ValueKey('step$_step');
                  final slide = Tween<Offset>(
                    begin: Offset(isIncoming ? 0.08 : -0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('step$_step'),
                  child: _step == 0 ? _buildStep1() : _buildStep2(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------- STEP 1 ----------

  Widget _buildStep1() {
    final loaderAsync = ref.watch(carSpecLoaderProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      children: [
        // 첫 진입 랜딩 — 브랜드 아이콘이 스프링으로 떠오른다
        PopIn(
          child: Image.asset(
            'assets/brand/icon-512.png',
            width: 56,
            height: 56,
          ),
        ),
        const SizedBox(height: 18),
        StaggerIn(
          index: 0,
          child: const _StepHeader(
            step: 'STEP 1 / 2',
            title: '어떤 차를\n타고 계신가요?',
            subtitle: '공단 연비 데이터로 절약 금액을 계산해요.',
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '예: 쏘렌토, 그랜저, K5',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        _buildSearchResult(loaderAsync),
      ],
    );
  }

  Widget _buildSearchResult(AsyncValue<CarSpecLoader> loaderAsync) {
    if (_query.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: AppEmptyView(
          icon: Icons.directions_car_outlined,
          title: '모델명을 입력해 검색하세요',
        ),
      );
    }

    return loaderAsync.when(
      loading: () => const AppSkeleton.list(rowCount: 4),
      error: (e, _) => AppEmptyView(
        icon: Icons.error_outline,
        title: '연비 데이터를 불러오지 못했어요',
        message: '$e',
      ),
      data: (loader) {
        final seen = <String>{};
        final unique = <CarSpecEntry>[];
        for (final e in loader.search(_query)) {
          if (seen.add('${e.modelName}|${e.fuelType}')) unique.add(e);
        }
        if (unique.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: AppEmptyView(
              icon: Icons.search_off,
              title: '검색 결과가 없습니다',
              message: '모델명 일부만 입력해보세요.',
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '검색 결과 ${unique.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedSoft,
                ),
              ),
            ),
            for (final (i, entry) in unique.take(20).indexed) ...[
              StaggerIn(
                index: i,
                child: _CarResultTile(
                  entry: entry,
                  selected: _selected?.modelName == entry.modelName &&
                      _selected?.fuelType == entry.fuelType,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selected = entry;
                      final cap =
                          loader.tankCapacityL(entry.modelName);
                      _selectedIsEv = cap == 0;
                      _tankAutoFilled = cap != null && cap > 0;
                      if (_tankAutoFilled) {
                        _tankController.text =
                            cap!.toStringAsFixed(0);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  // ---------- STEP 2 ----------

  Widget _buildStep2() {
    final selected = _selected!;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      children: [
        const _StepHeader(step: 'STEP 2 / 2', title: '조금만 더\n정확하게'),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              CarImage(
                vehicleType: selected.vehicleType,
                modelName: selected.modelName,
                height: 96,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.best,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car,
                        size: 20, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.modelName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${selected.manufacturer} · ${selected.fuelType}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '표시연비',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    selected.combinedKmPerL.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'km/L',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _FieldLabel('탱크 용량'),
        const SizedBox(height: 9),
        TextField(
          controller: _tankController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(suffixText: 'L'),
        ),
        if (_selectedIsEv) ...[
          const SizedBox(height: 8),
          Text(
            '전기·수소 차량은 주유 대상이 아니에요 — '
            '그래도 기록용으로 진행할 수 있어요.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ] else if (_tankAutoFilled) ...[
          const SizedBox(height: 8),
          Text(
            '차종 제원에서 자동으로 채웠어요 — 다르면 직접 수정해 주세요.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 9),
        Row(
          children: [
            for (final preset in _tankPresets) ...[
              Pressable(
                child: GestureDetector(
                  onTap: () => setState(
                    () => _tankController.text = preset.toStringAsFixed(0),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: AppMotion.curveStandard,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _tankController.text == preset.toStringAsFixed(0)
                          ? scheme.onSurface
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      '${preset.toStringAsFixed(0)}L',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            _tankController.text == preset.toStringAsFixed(0)
                                ? scheme.surface
                                : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('실연비'),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '선택',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _manualEfficiencyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: '비워두면 표시연비를 써요',
            suffixText: 'km/L',
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '주유 기록을 2회 이상 남기면 실연비를 자동으로 계산해요.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------- 하단 버튼 ----------

  Widget _buildBottomBar() {
    final canProceed = _selected != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (_step == 1) ...[
            SizedBox(
              width: 56,
              height: 54,
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton(
              onPressed: !canProceed || _saving
                  ? null
                  : (_step == 0 ? () => setState(() => _step = 1) : _save),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_step == 0 ? '다음' : '시작하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title, this.subtitle});

  final String step;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.mutedSoft,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            height: 1.22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

class _CarResultTile extends StatelessWidget {
  const _CarResultTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final CarSpecEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Pressable(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.best.withValues(alpha: 0.08)
                    : AppColors.bestSoft)
                : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.best
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.manufacturer.isEmpty
                      ? '차량'
                      : entry.manufacturer.substring(
                          0,
                          entry.manufacturer.length > 2
                              ? 2
                              : entry.manufacturer.length,
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color:
                        selected ? AppColors.ink : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.modelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.manufacturer} · ${entry.fuelType} · '
                      '복합 ${entry.combinedKmPerL.toStringAsFixed(1)} km/L',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                // 선택 체크 — 팝인으로 확정감을 준다
                PopIn(child: Icon(Icons.check, size: 20, color: scheme.onSurface)),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// 등록 완료 오버레이 — 체크 애니메이션이 끝나면 잠깐 유지 후 자동으로 닫힌다
class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay();

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay> {
  bool _closing = false;

  void _onCheckDone() {
    if (_closing) return;
    _closing = true;
    // 체크가 완성되면 0.6s 홀드 후 닫기
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SuccessCheck(onDone: _onCheckDone),
          const SizedBox(height: 18),
          const Text(
            '차량이 등록되었습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
