// lib/core/theme/app_colors.dart
// Calc-Calories — Color Palette

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand (Electric Cyan accents) ─────────────
  static const Color primary = Color(0xFF00BCD4);       // Electric Cyan
  static const Color primaryDark = Color(0xFF0097A7);
  static const Color primaryLight = Color(0xFF80DEEA);
  static const Color primarySurface = Color(0xFF006064); 

  // ── Background (Deep velvety navy/slate) ────────────
  static const Color background = Color(0xFF090C15);     // Deep Dark Slate
  static const Color surface = Color(0xFF121824);        // Card background
  static const Color surfaceVariant = Color(0xFF1B2232); // Elevated surface
  static const Color border = Color(0xFF222B3F);

  // ── Accent ────────────────────────────────────────────
  static const Color accent = Color(0xFF00BCD4);         // Electric Cyan accent
  static const Color accentLight = Color(0xFF4DD0E1);

  // ── Macros Colors ─────────────────────────────────────
  static const Color calories = Color(0xFF00BCD4);       // Electric Cyan
  static const Color protein = Color(0xFF2196F3);        // Blue
  static const Color carbs = Color(0xFFFFC107);          // Soft Gold
  static const Color fats = Color(0xFFFF5722);           // Muted Orange/Crimson

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);    // Crisp White
  static const Color textSecondary = Color(0xFF8E929C);  // Muted Grey
  static const Color textMuted = Color(0xFF5D616B);

  // ── Status ────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF00BCD4);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BCD4), Color(0xFF0097A7)], // Flowing cyan gradient
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF090C15), Color(0xFF121824)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF121824), Color(0xFF1B2232)],
  );
}
