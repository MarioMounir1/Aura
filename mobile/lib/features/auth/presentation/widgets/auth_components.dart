// lib/features/auth/presentation/widgets/auth_components.dart
// Aura — Design Tokens & Shared Authentication UI Components

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens specifically tailored for the luxury wellness Aura authentication experience.
abstract class AuraAuthTokens {
  static const Color brandDark       = Color(0xFF1B3D2F); // Deep Forest Green
  static const Color brandDeep       = Color(0xFF142F24); // Darker Forest for Headings
  static const Color brandButton     = Color(0xFF1E513D); // Primary CTA Button
  static const Color brandButtonDisabled = Color(0xFF98B8A6); // Disabled CTA Button
  static const Color terracotta      = Color(0xFFBA6942); // Warm Earth Eyebrow / Links
  static const Color amberBadge      = Color(0xFFD97736); // Small badge dot
  static const Color sageBgLight     = Color(0xFFE6F0E8); // Top ambient glow
  static const Color sageSurface     = Color(0xFFF1F6F2); // Input field background
  static const Color sageBorder      = Color(0xFFDEECE2); // Input and card borders
  static const Color cardBg          = Color(0xFFFFFFFF); // Card background
  static const Color textPrimary     = Color(0xFF182A22); // Primary heading/input text
  static const Color textSecondary   = Color(0xFF5A7065); // Subtitles & field labels
  static const Color textMuted       = Color(0xFF889D91); // Placeholders & dividers
  static const Color checkPillBg     = Color(0xFFDCEEE2); // Reassurance icon pill background
  static const Color checkPillIcon   = Color(0xFF1E513D); // Reassurance icon color
  static const Color dividerLine     = Color(0xFFE4ECE6); // Horizontal divider
  static const Color cardShadow      = Color(0x0C1B3D2F); // Soft ambient card shadow
}

/// Serene ambient background with sage/mint glow at the top fading into porcelain white.
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
            Color(0xFFE2EFE5), // Soft sage glow
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

/// The official Aura Squircle Brand Logo & Editorial Wordmark.
class AuraBrandHeader extends StatelessWidget {
  final bool showWordmark;
  final double iconSize;

  const AuraBrandHeader({
    super.key,
    this.showWordmark = true,
    this.iconSize = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Squircle Icon container
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AuraAuthTokens.brandDark,
            borderRadius: BorderRadius.circular(iconSize * 0.32),
            boxShadow: [
              BoxShadow(
                color: AuraAuthTokens.brandDark.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(iconSize * 0.20),
          child: const CustomPaint(
            painter: AuraEmblemPainter(),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'AURA',
            style: GoogleFonts.fraunces(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: AuraAuthTokens.brandDeep,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the continuous elegant looped ribbon/butterfly wellness emblem.
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
    // Elegant interlocking organic loop (two petals intersecting gracefully)
    path.moveTo(w * 0.5, h * 0.88);
    // Left loop
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
    // Right loop
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

    // Diagonal crossing stem line
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

/// Circular back navigation button.
class AuraCircularBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AuraCircularBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
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
              size: 19,
              color: AuraAuthTokens.brandDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled input field with soft sage fill and border.
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AuraAuthTokens.textPrimary,
                letterSpacing: -0.1,
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
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: GoogleFonts.inter(
            color: AuraAuthTokens.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: AuraAuthTokens.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                prefixIcon,
                color: AuraAuthTokens.textSecondary,
                size: 19,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AuraAuthTokens.sageSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuraAuthTokens.sageBorder, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuraAuthTokens.brandDark, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary Forest Green CTA Button with arrow symbol and loading state.
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

/// "OR CONTINUE WITH" divider with lines.
class AuraDividerWithText extends StatelessWidget {
  final String text;

  const AuraDividerWithText({
    super.key,
    this.text = 'OR CONTINUE WITH',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AuraAuthTokens.dividerLine,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AuraAuthTokens.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
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

/// Google Sign-In button matching the clean bordered style.
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
            // Google 'G' icon or stylized letter
            _buildGoogleIcon(),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
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
