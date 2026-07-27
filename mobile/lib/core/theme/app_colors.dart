// lib/core/theme/app_colors.dart
// Aura — Centralized App-Wide Color Design Tokens

import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Backgrounds & Surfaces ──────────────────────────────────
  static const Color background     = Color(0xFF090C15);
  static const Color card           = Color(0xFF121824);
  static const Color surface        = Color(0xFF1B2232);
  static const Color border         = Color(0xFF222B3F);
  static const Color borderMid      = Color(0xFF374151);

  // ── Typography ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E929C);
  static const Color textMuted     = Color(0xFF5D616B);

  // ── Semantic Roles ──────────────────────────────────────────
  /// Success / Positive metric role (Emerald Green)
  static const Color success       = Color(0xFF4CAF50);
  static const Color emerald       = Color(0xFF4CAF50);

  /// Warning / Caution role (Vibrant Gold Amber - #FFC107)
  static const Color warning       = Color(0xFFFFC107);
  static const Color amber         = Color(0xFFFFC107);

  /// Error / Danger role (Red)
  static const Color error         = Color(0xFFF44336);
  static const Color danger        = Color(0xFFF44336);

  /// Primary Accent role (Cyan)
  static const Color accent        = Color(0xFF00BCD4);
  static const Color cyan          = Color(0xFF00BCD4);

  /// Secondary Accent / Highlight role (Lime)
  static const Color lime          = Color(0xFFCDDC39);

  // Aliases for dashboard and workout screens compatibility
  static const Color primary        = accent;
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
}
