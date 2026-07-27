// lib/core/theme/app_colors.dart
// Aura — Centralized App-Wide Color Design Tokens & Dark Theme Extension

import 'package:flutter/material.dart';

/// ThemeExtension for Aura's design system tokens to support seamless dark/light mode toggling.
@immutable
class AuraThemeExtension extends ThemeExtension<AuraThemeExtension> {
  final Color background;
  final Color card;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color borderMid;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color accentCyan;
  final Color success;
  final Color warning;
  final Color error;
  final Color protein;
  final Color carbs;
  final Color fats;
  final LinearGradient snapMealGradient;
  final LinearGradient uploadScreenshotGradient;
  final LinearGradient scanBarcodeGradient;

  const AuraThemeExtension({
    required this.background,
    required this.card,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.borderMid,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.accentCyan,
    required this.success,
    required this.warning,
    required this.error,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.snapMealGradient,
    required this.uploadScreenshotGradient,
    required this.scanBarcodeGradient,
  });

  static const AuraThemeExtension dark = AuraThemeExtension(
    background: Color(0xFF090C15),
    card: Color(0xFF121824),
    surface: Color(0xFF1B2232),
    surfaceVariant: Color(0xFF1B2232),
    border: Color(0xFF222B3F),
    borderMid: Color(0xFF374151),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E929C),
    textMuted: Color(0xFF5D616B),
    primary: Color(0xFF00BCD4),
    accentCyan: Color(0xFF00BCD4),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFC107),
    error: Color(0xFFF44336),
    protein: Color(0xFF4CAF50),
    carbs: Color(0xFF00BCD4),
    fats: Color(0xFFF44336),
    snapMealGradient: LinearGradient(
      colors: [Color(0xFF064E3B), Color(0xFF065F46)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    uploadScreenshotGradient: LinearGradient(
      colors: [Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    scanBarcodeGradient: LinearGradient(
      colors: [Color(0xFF451A03), Color(0xFF92400E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const AuraThemeExtension light = dark;

  @override
  AuraThemeExtension copyWith({
    Color? background,
    Color? card,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? borderMid,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? accentCyan,
    Color? success,
    Color? warning,
    Color? error,
    Color? protein,
    Color? carbs,
    Color? fats,
    LinearGradient? snapMealGradient,
    LinearGradient? uploadScreenshotGradient,
    LinearGradient? scanBarcodeGradient,
  }) {
    return AuraThemeExtension(
      background: background ?? this.background,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      borderMid: borderMid ?? this.borderMid,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      accentCyan: accentCyan ?? this.accentCyan,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      snapMealGradient: snapMealGradient ?? this.snapMealGradient,
      uploadScreenshotGradient: uploadScreenshotGradient ?? this.uploadScreenshotGradient,
      scanBarcodeGradient: scanBarcodeGradient ?? this.scanBarcodeGradient,
    );
  }

  @override
  AuraThemeExtension lerp(ThemeExtension<AuraThemeExtension>? other, double t) {
    if (other is! AuraThemeExtension) return this;
    return AuraThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderMid: Color.lerp(borderMid, other.borderMid, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fats: Color.lerp(fats, other.fats, t)!,
      snapMealGradient: LinearGradient.lerp(snapMealGradient, other.snapMealGradient, t)!,
      uploadScreenshotGradient: LinearGradient.lerp(uploadScreenshotGradient, other.uploadScreenshotGradient, t)!,
      scanBarcodeGradient: LinearGradient.lerp(scanBarcodeGradient, other.scanBarcodeGradient, t)!,
    );
  }
}

extension AuraThemeBuildContext on BuildContext {
  AuraThemeExtension get auraTheme =>
      Theme.of(this).extension<AuraThemeExtension>() ?? AuraThemeExtension.dark;
}

abstract class AppColors {
  // ── Backgrounds & Surfaces (Dark Mode Specs) ─────────────────
  static const Color background     = Color(0xFF090C15);
  static const Color card           = Color(0xFF121824);
  static const Color surface        = Color(0xFF1B2232);
  static const Color border         = Color(0xFF222B3F);
  static const Color borderMid      = Color(0xFF374151);

  // ── Typography ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E929C);
  static const Color textMuted     = Color(0xFF5D616B);

  // ── Primary Brand & Signature Accents ────────────────────────
  static const Color primaryAccent = Color(0xFF00BCD4); // Cyan Accent
  static const Color accent        = Color(0xFF00BCD4);
  static const Color cyan          = Color(0xFF00BCD4);
  static const Color primary       = Color(0xFF00BCD4);
  static const Color lime          = Color(0xFFCDDC39);

  // ── Semantic Roles ──────────────────────────────────────────
  static const Color success       = Color(0xFF4CAF50);
  static const Color emerald       = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFFFC107);
  static const Color amber         = Color(0xFFFFC107);
  static const Color error         = Color(0xFFF44336);
  static const Color danger        = Color(0xFFF44336);

  // ── Macro Nutrients ──────────────────────────────────────────
  static const Color protein       = Color(0xFF4CAF50);
  static const Color carbs         = Color(0xFF00BCD4);
  static const Color fats          = Color(0xFFF44336);

  // ── Action Tile Gradients ────────────────────────────────────
  static const LinearGradient snapMealGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF065F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient uploadScreenshotGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient scanBarcodeGradient = LinearGradient(
    colors: [Color(0xFF451A03), Color(0xFF92400E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Aliases for dashboard and workout screens compatibility
  static const Color bg             = background;
  static const Color cardBackground = card;
  static const Color cardSurface    = surface;
  static const Color cardElev       = surface;
  static const Color surfaceVariant = surface;
  static const Color textPri        = textPrimary;
  static const Color textSec        = textSecondary;
  static const Color textMut        = textMuted;
  static const Color accentEmerald  = emerald;
  static const Color accentLime     = lime;
  static const Color accentBlue     = cyan;
  static const Color accentCyan     = cyan;
  static const Color accentRed      = error;
  static const Color accentAmber    = amber;
  static const Color trackBg        = border;
  static const Color track          = border;
  static const Color bgSecondary    = surface;
  static const Color borderSubtle   = border;
  static const Color red            = error;
  static const Color blue           = cyan;
  static const LinearGradient cardGradient = LinearGradient(
    colors: [card, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color primaryDark    = Color(0xFF008BA3);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, Color(0xFF008BA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


