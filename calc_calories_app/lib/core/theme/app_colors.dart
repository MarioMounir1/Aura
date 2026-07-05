// lib/core/theme/app_colors.dart
// Calc-Calories — Color Palette

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand ─────────────────────────────────────
  static const Color primary = Color(0xFF00C896);       // Vibrant green
  static const Color primaryDark = Color(0xFF00A87E);
  static const Color primaryLight = Color(0xFF33D4AA);
  static const Color primarySurface = Color(0xFF002920); // Dark green tint

  // ── Accent ────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6B35);         // Energetic orange
  static const Color accentLight = Color(0xFFFF8C5A);

  // ── Background ────────────────────────────────────────
  static const Color background = Color(0xFF0D1117);     // Near-black
  static const Color surface = Color(0xFF161B22);        // Card background
  static const Color surfaceVariant = Color(0xFF21262D); // Elevated surface
  static const Color border = Color(0xFF30363D);

  // ── Macros Colors ─────────────────────────────────────
  static const Color calories = Color(0xFFFF6B35);       // Orange
  static const Color protein = Color(0xFF58A6FF);        // Blue
  static const Color carbs = Color(0xFFFFD93D);          // Yellow
  static const Color fats = Color(0xFFFF4757);           // Red

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // ── Status ────────────────────────────────────────────
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C896), Color(0xFF00A87E)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161B22), Color(0xFF21262D)],
  );
}
