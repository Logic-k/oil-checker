import 'package:flutter/material.dart';
import 'package:oil_checker/core/traffic/congestion.dart';

/// 앱 전역 색상 토큰
///
/// 기존 화면들이 직접 쓰던 `Colors.green.shade800`, `Colors.amber` 등의
/// 하드코딩을 여기로 모았다. 의미(경제 1위 / 절약 / 혼잡)로 이름을 붙여
/// 라이트·다크 양쪽에서 일관되게 쓴다.
class AppColors {
  const AppColors._();

  // --- 기본 ---
  static const Color ink = Color(0xFF12181F);
  static const Color inkSoft = Color(0xFF1B2229);
  static const Color best = Color(0xFFFFB020);
  static const Color bestSoft = Color(0xFFFFFBF1);
  static const Color saving = Color(0xFF0E9F6E);
  static const Color savingDeep = Color(0xFF0A7A55);
  static const Color savingBright = Color(0xFF34D399);

  // --- 중립 (라이트) ---
  static const Color muted = Color(0xFF6B7785);
  static const Color mutedSoft = Color(0xFFA3ADB8);
  static const Color mutedFaint = Color(0xFFC3CAD2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4F6F8);
  static const Color scaffold = Color(0xFFF7F9FA);
  static const Color border = Color(0xFFE9EDF1);
  static const Color divider = Color(0xFFF0F3F5);

  // --- 중립 (다크) ---
  static const Color darkScaffold = Color(0xFF0B1016);
  static const Color darkSurface = Color(0xFF12181F);
  static const Color darkSurfaceAlt = Color(0xFF161C24);
  static const Color darkBorder = Color(0xFF262E38);
  static const Color darkText = Color(0xFFE8ECF0);
  static const Color darkMuted = Color(0xFF6B7785);
  static const Color darkMutedSoft = Color(0xFF5C6672);

  // --- 혼잡도 ---
  static const Color trafficSmooth = Color(0xFF0E9F6E);
  static const Color trafficModerate = Color(0xFFF5A524);
  static const Color trafficHeavy = Color(0xFFE5484D);

  /// 도로 혼잡 단계 색
  static Color traffic(CongestionLevel level) => switch (level) {
        CongestionLevel.smooth => trafficSmooth,
        CongestionLevel.moderate => trafficModerate,
        CongestionLevel.heavy => trafficHeavy,
      };

  /// 정유사 코드별 대표색 (지도 마커 좌측 스트라이프)
  static Color brand(String code) => switch (code) {
        'HDO' => const Color(0xFFE5484D),
        'GSC' => const Color(0xFF2563EB),
        'SKE' => const Color(0xFFF5A524),
        'SOL' => const Color(0xFF0E9F6E),
        'RTE' || 'RTX' || 'NHO' => const Color(0xFF7C6BF5),
        _ => const Color(0xFF8A94A0),
      };

  /// 정유사 코드 → 전체 이름
  static String brandLabel(String code) => switch (code) {
        'HDO' => 'HD현대오일뱅크',
        'GSC' => 'GS칼텍스',
        'SKE' => 'SK에너지',
        'SOL' => 'S-OIL',
        'RTE' => '자영알뜰',
        'RTX' => '고속도로알뜰',
        'NHO' => '농협알뜰',
        'ETC' => '자가상표',
        _ => '주유소',
      };

  /// 정유사 코드 → 2~3자 약자 (아바타/마커용)
  static String brandShort(String code) => switch (code) {
        'HDO' => 'HD',
        'GSC' => 'GS',
        'SKE' => 'SK',
        'SOL' => 'S',
        'RTE' || 'RTX' || 'NHO' => '알뜰',
        _ => '기타',
      };
}

/// 앱 테마 — 라이트 / 다크
class AppTheme {
  const AppTheme._();

  static const double radiusCard = 16;
  static const double radiusLarge = 22;

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.best,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.best : AppColors.ink,
      onPrimary: isDark ? AppColors.ink : Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkText : AppColors.ink,
      surfaceContainerHighest:
          isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
      onSurfaceVariant: isDark ? AppColors.darkMuted : AppColors.muted,
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.border,
    );

    final textColor = isDark ? AppColors.darkText : AppColors.ink;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.scaffold,
      // 프로젝트에 Pretendard를 번들했다면 아래 주석을 해제하세요.
      // fontFamily: 'Pretendard',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.best : AppColors.ink,
          foregroundColor: isDark ? AppColors.ink : Colors.white,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textColor, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
        selectedColor: isDark ? AppColors.best : AppColors.ink,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// 숫자를 3자리 콤마로 (12345 → 12,345)
String formatWon(num value) {
  final n = value.round().abs();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${value < 0 ? '-' : ''}$buf';
}
