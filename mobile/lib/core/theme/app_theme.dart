// lib/core/theme/app_theme.dart
// Aura — Centralized App ThemeData Configuration

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppColors.card,
        primary: AppColors.primaryAccent,
        secondary: AppColors.cyan,
        error: AppColors.error,
      ),
      extensions: const [
        AuraThemeExtension.light,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  /// Default theme set to lightTheme as per design spec
  static ThemeData get darkTheme => lightTheme;
}

