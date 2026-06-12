import 'package:flutter/material.dart';

/// نظام التصميم - Material Design 3 مع دعم الوضع الداكن وRTL
class AppColors {
  // ── Primary Palette ──────────────────────────────────────
  static const primary = Color(0xFF1A2B4C);      // Navy Blue
  static const primaryLight = Color(0xFF2D4A7A);
  static const primaryContainer = Color(0xFFD6E3FF);
  static const onPrimary = Colors.white;

  // ── Status Colors ─────────────────────────────────────────
  static const success = Color(0xFF2E9E6B);       // Confirmed / Income
  static const successContainer = Color(0xFFD4F5E5);
  static const warning = Color(0xFFF2A33C);       // Pending / Refund
  static const warningContainer = Color(0xFFFFF0D6);
  static const error = Color(0xFFE2574C);         // Debt / Cancelled
  static const errorContainer = Color(0xFFFFE8E6);
  static const info = Color(0xFF4A86E8);          // Info
  static const infoContainer = Color(0xFFE3EDFF);

  // ── Priority Colors ───────────────────────────────────────
  static const urgent = Color(0xFFDC2626);
  static const overdue = Color(0xFF7C2D12);
  static const normal = Color(0xFF16A34A);

  // ── Surface ───────────────────────────────────────────────
  static const scaffoldLight = Color(0xFFF5F6FA);
  static const cardLight = Colors.white;
  static const scaffoldDark = Color(0xFF0F1117);
  static const cardDark = Color(0xFF1C1F2E);
  static const surfaceDark = Color(0xFF242838);

  // ── Text ──────────────────────────────────────────────────
  static const textDark = Color(0xFF1A1F36);
  static const textMuted = Color(0xFF8A94A6);
  static const textLight = Colors.white;
}

class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      surface: AppColors.cardLight,
      surfaceContainerHighest: AppColors.scaffoldLight,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.06),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.scaffoldLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle:
            const TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardLight,
        selectedColor: AppColors.primary,
        side: BorderSide(color: Colors.grey.shade200),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade100,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryLight,
      surface: AppColors.cardDark,
      surfaceContainerHighest: AppColors.scaffoldDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// ظلال الكروت الموحدة
const kCardShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];

const kCardShadowDark = [
  BoxShadow(
    color: Color(0x40000000),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];
