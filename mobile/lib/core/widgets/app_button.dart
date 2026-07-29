import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final Color? iconColor;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconColor,
    this.isFullWidth = true,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.isFullWidth = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.isFullWidth = true,
  }) : variant = AppButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final bool isPrimary = variant == AppButtonVariant.primary;
    final bool isDisabled = onPressed == null;

    // Define colors based on variant and disabled state
    final Color backgroundColor;
    final Color textColor;
    
    if (isDisabled) {
      backgroundColor = isPrimary ? theme.surfaceVariant : Colors.transparent;
      textColor = theme.textSecondary;
    } else {
      backgroundColor = isPrimary ? AppColors.primary : theme.surfaceVariant;
      textColor = isPrimary ? Colors.white : theme.textPrimary;
    }
    
    final effectiveIconColor = iconColor ?? textColor;
    
    // Define borders and shadows
    final border = isPrimary ? null : Border.all(color: isDisabled ? theme.border.withValues(alpha: 0.5) : theme.border, width: 1);
    final boxShadow = (isPrimary && !isDisabled)
        ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: border,
            boxShadow: boxShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: effectiveIconColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
