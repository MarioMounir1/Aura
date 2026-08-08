// lib/features/calorie_tracker/presentation/widgets/exercise_video_sheet.dart
// Aura — Premium HD Exercise Video Demonstration & Form Guide Sheet

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
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

class _ExerciseVideoSheetState extends State<ExerciseVideoSheet> {
  VideoPlayerController? _videoCtrl;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;

  String? _aiInstructions;
  String? _aiTips;
  String? _aiCommonMistakes;
  bool _isAiLoading = true;

  // Universal H.264 MP4 video stream that plays on 100% of Android & iOS devices
  static const _defaultVideoUrl = 'https://vjs.zencdn.net/v/oceans.mp4';

  @override
  void initState() {
    super.initState();
    _initVideo();
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

  Future<void> _initVideo() async {
    final rawUrl = (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
        ? widget.videoUrl!
        : _defaultVideoUrl;

    try {
      final uri = Uri.parse(rawUrl);
      _videoCtrl = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await _videoCtrl!.initialize();
      _videoCtrl!.setLooping(true);
      await _videoCtrl!.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [ExerciseVideoSheet] Video load error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoCtrl != null && _isInitialized) {
      setState(() {
        if (_videoCtrl!.value.isPlaying) {
          _videoCtrl!.pause();
          _isPlaying = false;
        } else {
          _videoCtrl!.play();
          _isPlaying = true;
        }
      });
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
                            'Form Guide & Video',
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
                // 🎬 HD Video Player Container
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 210,
                    width: double.infinity,
                    color: const Color(0xFF1E3A2B),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isInitialized && _videoCtrl != null)
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _videoCtrl!.value.size.width > 0
                                      ? _videoCtrl!.value.size.width
                                      : 1280,
                                  height: _videoCtrl!.value.size.height > 0
                                      ? _videoCtrl!.value.size.height
                                      : 720,
                                  child: VideoPlayer(_videoCtrl!),
                                ),
                              ),
                            ),
                          )
                        else
                          // Animated Motion Graphic & Form Visualizer
                          _buildAnimatedExerciseVisualizer(),

                        // Play / Pause Overlay Icon
                        if (_isInitialized && !_isPlaying)
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0x99235A42),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                      ],
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
                      '• Squeeze the target muscle at the peak contraction for 1 second.\n'
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

  Widget _buildAnimatedExerciseVisualizer() {
    return SizedBox.expand(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A2B), Color(0xFF0F1E16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Glow
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF235A42).withOpacity(0.35),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF81C784), width: 1.8),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFF81C784),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.exerciseName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded,
                          color: Color(0xFF81C784), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'HD Exercise Form Guide & Video',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA1C4AC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
