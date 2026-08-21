// lib/core/theme/app_theme.dart
// Aura — Google Material 3 Standard App ThemeData Configuration

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.card,
        primary: AppColors.primaryAccent,
        secondary: AppColors.primaryAccent,
        error: AppColors.error,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryAccent,
        selectionColor: Color(0x3310B981),
        selectionHandleColor: AppColors.primaryAccent,
      ),
      extensions: const [
        AuraThemeExtension.dark,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return base.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: const Color(0xFFF6F8F5),
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFFFFFFF),
        primary: AppColors.primary,
        secondary: AppColors.primary,
        error: Color(0xFFEF4444),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x33235A42),
        selectionHandleColor: AppColors.primary,
      ),
      extensions: const [
        AuraThemeExtension.light,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1C2B1E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1C2B1E),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: const Color(0xFF1C2B1E),
        displayColor: const Color(0xFF1C2B1E),
      ),
    );
  }
}


