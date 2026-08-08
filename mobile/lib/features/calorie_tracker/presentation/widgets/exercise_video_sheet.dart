// lib/features/calorie_tracker/presentation/widgets/exercise_video_sheet.dart
// Aura — Gemini AI Exercise Motion Renderer & Form Guide Sheet

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';

class ExerciseVideoSheet extends StatefulWidget {
  final String exerciseName;
  final String muscleGroup;
  final String? videoUrl;
  final String? instructions;
  final String? tips;
  final String? commonMistakes;

  const ExerciseVideoSheet({
    super.key,
    required this.exerciseName,
    required this.muscleGroup,
    this.videoUrl,
    this.instructions,
    this.tips,
    this.commonMistakes,
  });

  static void show(
    BuildContext context, {
    required String exerciseName,
    required String muscleGroup,
    String? videoUrl,
    String? instructions,
    String? tips,
    String? commonMistakes,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExerciseVideoSheet(
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        videoUrl: videoUrl,
        instructions: instructions,
        tips: tips,
        commonMistakes: commonMistakes,
      ),
    );
  }

  @override
  State<ExerciseVideoSheet> createState() => _ExerciseVideoSheetState();
}

class _ExerciseVideoSheetState extends State<ExerciseVideoSheet>
    with SingleTickerProviderStateMixin {
  AnimationController? _animCtrl;
  bool _isPlaying = true;
  bool _isSlowMo = false;
  int _repCount = 1;

  String? _aiInstructions;
  String? _aiTips;
  String? _aiCommonMistakes;
  bool _isAiLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _fetchGeminiFormGuide();
  }

  void _initAnimation() {
    if (_animCtrl == null) {
      _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (mounted) {
              setState(() {
                _repCount = (_repCount % 12) + 1;
              });
            }
            _animCtrl?.forward(from: 0.0);
          }
        });

      _animCtrl!.forward();
    }
  }

  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_animCtrl == null) return;
    setState(() {
      if (_animCtrl!.isAnimating) {
        _animCtrl!.stop();
        _isPlaying = false;
      } else {
        _animCtrl!.forward();
        _isPlaying = true;
      }
    });
  }

  void _toggleSpeed() {
    if (_animCtrl == null) return;
    setState(() {
      _isSlowMo = !_isSlowMo;
      _animCtrl!.duration = Duration(milliseconds: _isSlowMo ? 5200 : 2600);
      if (_isPlaying) {
        final currentVal = _animCtrl!.value;
        _animCtrl!.forward(from: currentVal);
      }
    });
  }

  Future<void> _fetchGeminiFormGuide() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get(
        '/workouts/exercise-guide',
        queryParameters: {
          'name': widget.exerciseName,
          'muscleGroup': widget.muscleGroup,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _aiInstructions = data['instructions'];
            _aiTips = data['tips'];
            _aiCommonMistakes = data['commonMistakes'];
            _isAiLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isAiLoading = false);
      }
    } catch (e) {
      debugPrint('ℹ️ [ExerciseVideoSheet] Local form guide fallback active.');
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  String _getMotionPhaseText(double progress) {
    if (progress < 0.45) {
      return 'Phase 1: Eccentric Lowering (Controlled Tempo)';
    } else if (progress < 0.55) {
      return 'Phase 2: Peak Contraction & Squeeze';
    } else {
      return 'Phase 3: Concentric Drive (Explosive Push)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle Header
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD3E4D7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Muscle Badge Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exerciseName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C2B1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF235A42).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.muscleGroup,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF235A42),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gemini AI 60FPS Motion Guide ⚡',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF5A6E5D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF5A6E5D)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Scrollable Content Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // 🎬 GEMINI AI 60FPS MOTION VIDEO PLAYER CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 230,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF132A1F), Color(0xFF0A1610)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        _initAnimation();
                        if (_animCtrl == null) {
                          return const SizedBox.shrink();
                        }
                        return AnimatedBuilder(
                          animation: _animCtrl!,
                          builder: (context, child) {
                            final progress = _animCtrl!.value;
                            return Stack(
                              children: [
                                // 60FPS AI Vector Motion Canvas
                                CustomPaint(
                                  size: const Size(double.infinity, 230),
                                  painter: GeminiMotionPainter(
                                    progress: progress,
                                    exerciseName: widget.exerciseName,
                                    muscleGroup: widget.muscleGroup,
                                  ),
                                ),

                            // Top Left AI Status Badge
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF81C784)
                                          .withOpacity(0.5),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF81C784),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'AI MOTION STREAM • 60 FPS',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF81C784),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Top Right Rep Counter HUD
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF235A42)
                                      .withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'REP $_repCount / 12',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // Bottom Controls HUD Bar
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Row(
                                children: [
                                  // Motion Phase Indicator
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getMotionPhaseText(progress),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFA1C4AC),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Play / Pause Button
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF81C784),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: const Color(0xFF0F1E16),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Speed Toggle (Slow-Mo)
                                  GestureDetector(
                                    onTap: _toggleSpeed,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isSlowMo
                                            ? const Color(0xFFF59E0B)
                                            : Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _isSlowMo ? '0.5x' : '1.0x',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: _isSlowMo
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

                const SizedBox(height: 20),

                // 🎯 Form Instructions
                _buildSectionCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF235A42),
                  title: 'Step-by-Step Execution',
                  content: widget.instructions ?? _aiInstructions ??
                      '1. Set up with your feet shoulder-width apart.\n'
                          '2. Engage your core and keep your chest proud.\n'
                          '3. Control the eccentric phase for 2-3 seconds.\n'
                          '4. Drive powerfully through the full range of motion.',
                ),

                const SizedBox(height: 12),

                // 💡 Pro Tips for Muscle Engagement
                _buildSectionCard(
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Pro Coaching Cues',
                  content: widget.tips ?? _aiTips ??
                      '• Squeeze the target muscle at peak contraction for 1 second.\n'
                          '• Keep your shoulder blades retracted and avoid using momentum.',
                ),

                const SizedBox(height: 12),

                // ⚠️ Common Mistakes to Avoid
                _buildSectionCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Common Mistakes to Avoid',
                  content: widget.commonMistakes ?? _aiCommonMistakes ??
                      '• Arching lower back excessively.\n'
                          '• Cutting range of motion short.\n'
                          '• Rushing repetitions without controlled tempo.',
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C2B1E),
                ),
              ),
              if (_isAiLoading && title.contains('Step-by-Step')) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF235A42)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5A6E5D),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 GEMINI AI 60FPS VECTOR MOTION PAINTER
class GeminiMotionPainter extends CustomPainter {
  final double progress;
  final String exerciseName;
  final String muscleGroup;

  GeminiMotionPainter({
    required this.progress,
    required this.exerciseName,
    required this.muscleGroup,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final isPress = exerciseName.toLowerCase().contains('press') ||
        exerciseName.toLowerCase().contains('bench') ||
        exerciseName.toLowerCase().contains('push');
    final isPull = exerciseName.toLowerCase().contains('pull') ||
        exerciseName.toLowerCase().contains('row') ||
        exerciseName.toLowerCase().contains('lat');

    // Sine wave motion curve (smooth 60fps rep cycle)
    final motion = (math.sin(progress * math.pi * 2 - math.pi / 2) + 1) / 2;

    // Background Grid Pattern
    final gridPaint = Paint()
      ..color = const Color(0xFF81C784).withOpacity(0.06)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 24) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Target Muscle Glowing Aura
    final auraPaint = Paint()
      ..color = const Color(0xFF81C784).withOpacity(0.12 + motion * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, 70 + motion * 15, auraPaint);

    if (isPress) {
      // 🏋️ PRESSING MOTION (Bench Press / Overhead Press)
      final barY = center.dy + 35 - (motion * 65);

      // Bench Platform
      final benchPaint = Paint()
        ..color = const Color(0xFF1E3A2B)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(center.dx - 60, center.dy + 45), Offset(center.dx + 60, center.dy + 45), benchPaint);

      // Barbell Shaft
      final barPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(center.dx - 80, barY), Offset(center.dx + 80, barY), barPaint);

      // Weight Plates (Left & Right)
      final platePaint = Paint()..color = const Color(0xFF81C784);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - 82, barY - 22, 10, 44),
            const Radius.circular(3)),
        platePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx + 72, barY - 22, 10, 44),
            const Radius.circular(3)),
        platePaint,
      );

      // Glowing Active Muscle Zones (Chest & Arms)
      final muscleGlow = Paint()
        ..color = const Color(0xFF81C784).withOpacity(0.3 + motion * 0.5)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawLine(
          Offset(center.dx - 30, center.dy + 25), Offset(center.dx - 55, barY), muscleGlow);
      canvas.drawLine(
          Offset(center.dx + 30, center.dy + 25), Offset(center.dx + 55, barY), muscleGlow);
    } else if (isPull) {
      // 🏋️ PULLING MOTION (Lat Pulldown / Cable Rows)
      final handleY = center.dy - 40 + (motion * 55);

      // Pulley Cable
      final cablePaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 2;
      canvas.drawLine(
          Offset(center.dx, center.dy - 75), Offset(center.dx, handleY), cablePaint);

      // Lat Bar
      final barPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(center.dx - 75, handleY), Offset(center.dx + 75, handleY), barPaint);

      // Glowing Back Muscle Activation Wings
      final backGlow = Paint()
        ..color = const Color(0xFF4DD0E1).withOpacity(0.25 + motion * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final leftWing = Path()
        ..moveTo(center.dx - 15, center.dy - 10)
        ..lineTo(center.dx - 65, center.dy + 20)
        ..lineTo(center.dx - 20, center.dy + 45)
        ..close();
      canvas.drawPath(leftWing, backGlow);

      final rightWing = Path()
        ..moveTo(center.dx + 15, center.dy - 10)
        ..lineTo(center.dx + 65, center.dy + 20)
        ..lineTo(center.dx + 20, center.dy + 45)
        ..close();
      canvas.drawPath(rightWing, backGlow);
    } else {
      // 🏋️ SQUAT / LEGS MOTION
      final hipY = center.dy - 20 + (motion * 45);

      // Barbell on Shoulders
      final barPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(center.dx - 70, hipY - 25), Offset(center.dx + 70, hipY - 25), barPaint);

      // Glowing Quad & Glute Muscle Activation
      final legGlow = Paint()
        ..color = const Color(0xFFFFB74D).withOpacity(0.3 + motion * 0.5)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawLine(
          Offset(center.dx - 22, hipY), Offset(center.dx - 30, center.dy + 55), legGlow);
      canvas.drawLine(
          Offset(center.dx + 22, hipY), Offset(center.dx + 30, center.dy + 55), legGlow);
    }
  }

  @override
  bool shouldRepaint(covariant GeminiMotionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
