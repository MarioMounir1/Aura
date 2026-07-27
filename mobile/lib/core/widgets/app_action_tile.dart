// lib/core/widgets/app_action_tile.dart
// Aura — Standardized Bold Action Tile / Button Component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AppActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  final bool isFilled;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const AppActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color = AppColors.primaryAccent,
    this.gradient,
    required this.onTap,
    this.isFilled = true,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final bool hasGradient = gradient != null;

    BoxDecoration decoration;
    Color iconAndTitleColor;
    Color subtitleColor;

    if (hasGradient) {
      decoration = BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient!.colors.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
      iconAndTitleColor = Colors.white;
      subtitleColor = Colors.white.withValues(alpha: 0.85);
    } else if (isFilled) {
      decoration = BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      );
      iconAndTitleColor = color.computeLuminance() > 0.5 ? theme.textPrimary : Colors.white;
      subtitleColor = iconAndTitleColor.withValues(alpha: 0.8);
    } else {
      // Secondary / Flatter tile style (e.g., Search Food)
      decoration = BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: theme.border, width: 1),
      );
      iconAndTitleColor = (color == AppColors.cyan || color == AppColors.primaryAccent)
          ? theme.accentCyan
          : color;
      subtitleColor = theme.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: decoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconAndTitleColor, size: 22),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isFilled || hasGradient ? iconAndTitleColor : theme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

