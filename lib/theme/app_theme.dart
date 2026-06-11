import 'package:flutter/material.dart';

/// باليتة الألوان - Minimal SaaS Design
class AppColors {
  /// الخلفية الأساسية: رمادي فاتح جداً
  static const scaffoldBg = Color(0xFFF5F6FA);

  /// الكروت: أبيض ناصع
  static const card = Colors.white;

  /// أزرق داكن للعناوين الرئيسية
  static const navy = Color(0xFF1A2B4C);

  /// أخضر: المكاسب والحجوزات المؤكدة
  static const green = Color(0xFF2E9E6B);

  /// أحمر هادئ: المديونيات
  static const softRed = Color(0xFFE2574C);

  /// برتقالي/أصفر: المرتجعات
  static const orange = Color(0xFFF2A33C);

  /// نصوص ثانوية
  static const textMuted = Color(0xFF8A94A6);

  /// نصوص أساسية (رمادي غامق بدل الأسود)
  static const textDark = Color(0xFF2F3B4C);
}

/// ظل ناعم جداً موحد لكل الكروت
const kSoftShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.scaffoldBg,
          foregroundColor: AppColors.navy,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
