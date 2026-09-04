// lib/features/auth/presentation/pre_screen.dart
// Aura — Atmospheric Pre-Screen / Splash Screen with Orbital Animation & Progress Indicator

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/auth_components.dart';

class PreSplashScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final Duration duration;

  const PreSplashScreen({
    super.key,
    this.onCompleted,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<PreSplashScreen> createState() => _PreSplashScreenState();
}

class _PreSplashScreenState extends State<PreSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Orbital animation for continuous gentle rotation
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Progress animation from 0% to 100% over the splash duration
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward().then((_) {
      if (mounted && widget.onCompleted != null) {
        widget.onCompleted!();
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF9),
      body: AuraAuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AuraAuthTokens.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // ── Top Header: Brand Logo & Status Tag ──────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const AuraBrandHeader(
                          showWordmark: true,
                          iconSize: 40,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AuraAuthTokens.amberBadge,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'QUIETLY GETTING READY',
                              style: GoogleFonts.roboto(
                                textStyle: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3,
                                  color: AuraAuthTokens.textSecondary,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                                color: AuraAuthTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // ── Animated Cosmic / Orbital Rings Visual ────────────
                    _buildOrbitalVisual(),

                    const SizedBox(height: 32),

                    // ── Eyebrow Label ─────────────────────────────────────
                    Text(
                      'YOUR SPACE TO RETURN\nTO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        textStyle: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AuraAuthTokens.terracotta,
                          height: 1.3,
                        ),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AuraAuthTokens.terracotta,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Editorial Serif Heading ───────────────────────────
                    Text(
                      'A little more you,\nevery day.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        textStyle: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.15,
                          color: AuraAuthTokens.brandDeep,
                        ),
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.15,
                        color: AuraAuthTokens.brandDeep,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Subtitle ─────────────────────────────────────────
                    Text(
                      "We're shaping a rhythm around how you want\nto feel.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        textStyle: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AuraAuthTokens.textSecondary,
                          height: 1.45,
                        ),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: AuraAuthTokens.textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // ── Preparing Your Experience Loading Card ────────────
                    _buildLoadingCard(textTheme),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Animated Orbital rings with orbiting amber particle and centered Aura emblem
  Widget _buildOrbitalVisual() {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _orbitController,
        builder: (context, child) {
          return CustomPaint(
            painter: _OrbitalRingsPainter(
              orbitProgress: _orbitController.value,
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFD4E8DC),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AuraAuthTokens.brandDark.withValues(alpha: 0.08),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/aura_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: CustomPaint(
                        size: Size(44, 44),
                        painter: AuraEmblemPainter(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bottom progress card with percentage and status indicators
  Widget _buildLoadingCard(TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final progress = _progressAnimation.value.clamp(0.0, 1.0);
        final percentInt = (progress * 100).toInt();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AuraAuthTokens.cardBg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AuraAuthTokens.sageBorder,
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: AuraAuthTokens.cardShadow,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Row: Title & Percentage ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREPARING YOUR EXPERIENCE',
                        style: GoogleFonts.roboto(
                          textStyle: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AuraAuthTokens.textSecondary,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AuraAuthTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tuning the details to you',
                        style: GoogleFonts.roboto(
                          textStyle: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AuraAuthTokens.textPrimary,
                          ),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AuraAuthTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percentInt%',
                    style: GoogleFonts.roboto(
                      textStyle: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AuraAuthTokens.brandDeep,
                      ),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AuraAuthTokens.brandDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Animated Smooth Progress Bar ─────────────────────
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EEE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * progress,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF388E6A),
                              Color(0xFF1E513D),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Bottom Status Row ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AuraAuthTokens.checkPillBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: AuraAuthTokens.checkPillIcon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Finding your starting point',
                        style: GoogleFonts.roboto(
                          textStyle: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AuraAuthTokens.textSecondary,
                          ),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AuraAuthTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'NEARLY THERE',
                    style: GoogleFonts.roboto(
                      textStyle: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AuraAuthTokens.textMuted,
                      ),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AuraAuthTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Painter for the delicate concentric orbital ripples and revolving amber particle
class _OrbitalRingsPainter extends CustomPainter {
  final double orbitProgress;

  const _OrbitalRingsPainter({required this.orbitProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Inner soft aura glow disc
    final glowPaint = Paint()
      ..color = const Color(0xFFDCEEE2).withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 76, glowPaint);

    // Middle concentric circle
    final middleRingPaint = Paint()
      ..color = const Color(0xFFCBE2D3).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 64, middleRingPaint);

    // Outermost orbit ring (radius ~ 98)
    const double outerRadius = 96.0;
    final outerRingPaint = Paint()
      ..color = const Color(0xFFB8D4C2).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Draw dashed outer orbit
    const int dashCount = 48;
    const double angleStep = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        angleStep,
        false,
        outerRingPaint,
      );
    }

    // Orbiting Amber Particle
    final angle = orbitProgress * 2 * math.pi - (math.pi / 4);
    final particleX = center.dx + outerRadius * math.cos(angle);
    final particleY = center.dy + outerRadius * math.sin(angle);
    final particleCenter = Offset(particleX, particleY);

    // Particle soft shadow/glow
    final particleGlow = Paint()
      ..color = AuraAuthTokens.amberBadge.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particleCenter, 7.5, particleGlow);

    // Particle solid body
    final particlePaint = Paint()
      ..color = AuraAuthTokens.amberBadge
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particleCenter, 4.5, particlePaint);

    // Inner white highlight on particle
    final particleHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(particleX - 1, particleY - 1), 1.4, particleHighlight);
  }

  @override
  bool shouldRepaint(covariant _OrbitalRingsPainter oldDelegate) {
    return oldDelegate.orbitProgress != orbitProgress;
  }
}
