// lib/core/widgets/app_metric_ring.dart
// Aura — Standardized Circular Metric Ring Badge Component

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AppMetricRing extends StatelessWidget {
  final String value;
  final String? label;
  final double progress; // 0.0 to 1.0
  final Color roleColor;
  final double size;
  final double strokeWidth;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  const AppMetricRing({
    super.key,
    required this.value,
    this.label,
    this.progress = 1.0,
    this.roleColor = AppColors.success,
    this.size = 80.0,
    this.strokeWidth = 6.0,
    this.valueStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final clampedProgress = progress.clamp(0.0, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: roleColor.withValues(alpha: 0.12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: clampedProgress,
              color: roleColor,
              trackColor: theme.border,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: valueStyle ??
                    GoogleFonts.outfit(
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
              ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label!,
                  style: labelStyle ??
                      GoogleFonts.inter(
                        fontSize: size * 0.13,
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Draw active progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

