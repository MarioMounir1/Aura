// lib/features/auth/presentation/widgets/auth_components.dart
// Aura — Google Material Standard Design Tokens & Shared Authentication UI Components

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/error_handler.dart';

/// Google Material Standard design tokens tailored for Aura's luxury wellness experience.
abstract class AuraAuthTokens {
  static const Color brandDark           = Color(0xFF1B3D2F); // Deep Forest Green
  static const Color brandDeep           = Color(0xFF142F24); // Darker Forest for Headings
  static const Color brandButton         = Color(0xFF1E513D); // Primary CTA Button
  static const Color brandButtonDisabled = Color(0xFF98B8A6); // Disabled CTA Button
  static const Color terracotta          = Color(0xFFBA6942); // Warm Earth Eyebrow / Links
  static const Color amberBadge          = Color(0xFFD97736); // Small badge dot
  static const Color sageBgLight         = Color(0xFFE6F0E8); // Top ambient glow
  static const Color sageSurface         = Color(0xFFF1F6F2); // Input field background
  static const Color sageBorder          = Color(0xFFDEECE2); // Input and card borders
  static const Color cardBg              = Color(0xFFFFFFFF); // Card background
  static const Color textPrimary         = Color(0xFF182A22); // Primary heading/input text
  static const Color textSecondary       = Color(0xFF5A7065); // Subtitles & field labels
  static const Color textMuted           = Color(0xFF889D91); // Placeholders & dividers
  static const Color checkPillBg         = Color(0xFFDCEEE2); // Reassurance icon pill background
  static const Color checkPillIcon       = Color(0xFF1E513D); // Reassurance icon color
  static const Color dividerLine         = Color(0xFFE4ECE6); // Horizontal divider
  static const Color cardShadow          = Color(0x0C1B3D2F); // Soft ambient card shadow

  // Max width for Google standard responsive aspect ratios on phones/tablets
  static const double maxContentWidth    = 460.0;
}

/// Serene ambient background with Google standard gradient transitioning from sage glow to ivory.
class AuraAuthBackground extends StatelessWidget {
  final Widget child;

  const AuraAuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBF9),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE2EFE5), // Soft sage ambient aura glow
            Color(0xFFEDF5EF),
            Color(0xFFF7FAF7),
            Color(0xFFFAFBF9), // Porcelain bottom
          ],
          stops: [0.0, 0.22, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// The official Aura Brand Header featuring the app logo and Google Material typography.
class AuraBrandHeader extends StatelessWidget {
  final bool showWordmark;
  final double iconSize;

  const AuraBrandHeader({
    super.key,
    this.showWordmark = true,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Squircle Icon container loading the official app logo asset
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AuraAuthTokens.brandDark,
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            boxShadow: [
              BoxShadow(
                color: AuraAuthTokens.brandDark.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/aura_logo.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AuraAuthTokens.brandDark,
              padding: EdgeInsets.all(iconSize * 0.20),
              child: const CustomPaint(
                painter: AuraEmblemPainter(),
              ),
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'AURA',
            style: GoogleFonts.fraunces(
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: AuraAuthTokens.brandDeep,
              ),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AuraAuthTokens.brandDeep,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the continuous elegant looped ribbon/butterfly emblem.
class AuraEmblemPainter extends CustomPainter {
  const AuraEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.5, h * 0.88);
    path.cubicTo(
      w * 0.10, h * 0.70,
      w * 0.10, h * 0.15,
      w * 0.48, h * 0.15,
    );
    path.cubicTo(
      w * 0.65, h * 0.15,
      w * 0.52, h * 0.55,
      w * 0.50, h * 0.88,
    );
    path.cubicTo(
      w * 0.48, h * 0.55,
      w * 0.35, h * 0.15,
      w * 0.52, h * 0.15,
    );
    path.cubicTo(
      w * 0.90, h * 0.15,
      w * 0.90, h * 0.70,
      w * 0.50, h * 0.88,
    );

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(w * 0.28, h * 0.72),
      Offset(w * 0.72, h * 0.60),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular back navigation button meeting Google 48dp touch target standards.
class AuraCircularBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AuraCircularBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AuraAuthTokens.sageBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x081B3D2F),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              size: 20,
              color: AuraAuthTokens.brandDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Google Material Standard Input Field with scalable typography and adaptive padding.
class AuraInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? trailingLabelWidget;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const AuraInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.trailingLabelWidget,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row with dynamic scalable typography
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                textStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AuraAuthTokens.textPrimary,
                  letterSpacing: -0.1,
                ),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AuraAuthTokens.textPrimary,
              ),
            ),
            if (trailingLabelWidget != null) trailingLabelWidget!,
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: GoogleFonts.inter(
            textStyle: textTheme.bodyMedium?.copyWith(
              color: AuraAuthTokens.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            color: AuraAuthTokens.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              textStyle: textTheme.bodyMedium?.copyWith(
                color: AuraAuthTokens.textMuted,
              ),
              color: AuraAuthTokens.textMuted,
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                prefixIcon,
                color: AuraAuthTokens.textSecondary,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 48),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AuraAuthTokens.sageSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuraAuthTokens.sageBorder, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuraAuthTokens.brandDark, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary Forest Green CTA Button conforming to Google Material 3 action standards.
class AuraPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const AuraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool active = isEnabled && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: active ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? AuraAuthTokens.brandButton : AuraAuthTokens.brandButtonDisabled,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuraAuthTokens.brandButtonDisabled,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        textStyle: textTheme.labelLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// "OR CONTINUE WITH" divider with standard Material proportions.
class AuraDividerWithText extends StatelessWidget {
  final String text;

  const AuraDividerWithText({
    super.key,
    this.text = 'OR CONTINUE WITH',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AuraAuthTokens.dividerLine,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: GoogleFonts.inter(
              textStyle: textTheme.labelSmall?.copyWith(
                color: AuraAuthTokens.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
              color: AuraAuthTokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AuraAuthTokens.dividerLine,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Google Sign-In button adhering to Google Brand & Material design specifications.
class AuraGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuraGoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AuraAuthTokens.sageBorder, width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFFFAFBF9),
          foregroundColor: AuraAuthTokens.textPrimary,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleIcon(),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                textStyle: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AuraAuthTokens.textPrimary,
                ),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AuraAuthTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Text(
        'G',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}

/// Apple Sign-In button for iOS devices.
class AuraAppleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuraAppleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraAuthTokens.brandDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Continue with Apple',
              style: GoogleFonts.inter(
                textStyle: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a simple, clean floating error notification for the user.
Future<void> showAuraAuthErrorDialog(
  BuildContext context, {
  String title = 'Sign-In Error',
  required String message,
  String? code,
  String? details,
}) async {
  if (!context.mounted) return;
  AppErrorHandler.showErrorSnackBar(
    context,
    message,
    fallback: 'Unable to complete sign-in. Please try again.',
  );
}

class AuraAuthErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? code;
  final String? details;

  const AuraAuthErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.code,
    this.details,
  });

  String _buildFullErrorText() {
    final buffer = StringBuffer();
    if (code != null && code!.isNotEmpty) {
      buffer.writeln('Code: $code');
    }
    buffer.writeln(message);
    if (details != null && details!.isNotEmpty) {
      buffer.writeln('\nDetails:\n$details');
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final fullText = _buildFullErrorText();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon and Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFD9534F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AuraAuthTokens.brandDeep,
                          ),
                        ),
                        if (code != null && code!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              code!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Full error details:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuraAuthTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // Scrollable selectable code container
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      fullText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFE2E8F0),
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error copied to clipboard',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AuraAuthTokens.brandDark,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        'Copy Error',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuraAuthTokens.brandDeep,
                        side: const BorderSide(color: AuraAuthTokens.sageBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraAuthTokens.brandButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

