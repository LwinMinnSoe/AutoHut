import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── AutoHut Brand Colors (from logo) ──────────────────────────────────────
class AppColors {
  // Primary Blue (logo main color)
  static const Color primary       = Color(0xFF2B5BA8);
  static const Color primaryDark   = Color(0xFF1E3F7A);
  static const Color primaryLight  = Color(0xFF4A7EC7);
  static const Color primarySurface= Color(0xFFEEF3FC);

  // Accent Orange (logo accent stripe)
  static const Color accent        = Color(0xFFE8823A);
  static const Color accentLight   = Color(0xFFFFF0E6);

  // Backgrounds
  static const Color background    = Color(0xFFF0F4FA);
  static const Color card          = Color(0xFFFFFFFF);
  static const Color white         = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF1A2B4A);
  static const Color textSecondary = Color(0xFF4E6080);
  static const Color textHint      = Color(0xFF8A9BB5);

  // Border / Divider
  static const Color border        = Color(0xFFD5E0F0);
  static const Color divider       = Color(0xFFEBF0FA);

  // Status
  static const Color success       = Color(0xFF27AE60);
  static const Color successLight  = Color(0xFFE8F8EF);
  static const Color danger        = Color(0xFFE74C3C);
  static const Color dangerLight   = Color(0xFFFDECEA);
  static const Color warning       = Color(0xFFF39C12);
  static const Color warningLight  = Color(0xFFFEF3E2);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySurface,
      selectedColor: AppColors.primary,
      disabledColor: AppColors.border,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: AppColors.textPrimary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    ),
  );
}

// ── App Text Styles ────────────────────────────────────────────────────────
class AppText {
  static const TextStyle h1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3);
  static const TextStyle h2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle h3 = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const TextStyle bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle small = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle smallBold = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
  static const TextStyle caption = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.5);
  static const TextStyle label = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 1.0);
}
