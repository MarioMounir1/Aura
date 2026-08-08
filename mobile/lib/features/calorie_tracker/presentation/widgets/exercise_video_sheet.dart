// lib/features/calorie_tracker/presentation/widgets/exercise_video_sheet.dart
// Aura — Premium Interactive 60fps Motion Visualizer & Gemini AI Exercise Form Guide

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
  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;
  bool _isPlaying = true;

  String? _aiInstructions;
  String? _aiTips;
  String? _aiCommonMistakes;
  bool _isAiLoading = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );

    _fetchGeminiFormGuide();
  }

  Future<void> _fetchGeminiFormGuide() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/workouts/exercise-guide', queryParameters: {
        'name': widget.exerciseName,
        'muscleGroup': widget.muscleGroup,
      });

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
      debugPrint('⚠️ [ExerciseVideoSheet] AI form guide fetch error: $e');
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleMotionPlay() {
    setState(() {
      if (_animCtrl.isAnimating) {
        _animCtrl.stop();
        _isPlaying = false;
      } else {
        _animCtrl.repeat(reverse: true);
        _isPlaying = true;
      }
    });
  }

  String _getTempoPhaseText(double value) {
    if (value < 0.4) {
      return 'Phase 1: Eccentric Lowering (2s Controlled)';
    } else if (value < 0.6) {
      return 'Phase 2: Peak Contraction (1s Hold & Squeeze)';
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
                            'Form Guide & Motion Visualizer',
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
                // 🎬 Interactive 60fps HD Motion Visualizer Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 215,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A2B), Color(0xFF0F1E16)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing Target Muscle Halo
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF81C784).withOpacity(0.18),
                                ),
                              ),
                            ),

                            // Main Exercise Card Details
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _toggleMotionPlay,
                                    child: Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF81C784),
                                            width: 2.2),
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.fitness_center_rounded
                                            : Icons.play_arrow_rounded,
                                        color: const Color(0xFF81C784),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.exerciseName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Dynamic Tempo Guide Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFF81C784).withOpacity(0.4),
                                          width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF81C784),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          _getTempoPhaseText(_animCtrl.value),
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFA1C4AC),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Top 60fps HD Badge
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '60 FPS HD Visualizer',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF81C784),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🎯 Form Instructions (Gemini AI Powered)
                _buildSectionCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF235A42),
                  title: 'Step-by-Step Execution (AI Guide)',
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
              if (_isAiLoading && title.contains('AI')) ...[
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
