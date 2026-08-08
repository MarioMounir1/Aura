// lib/features/calorie_tracker/presentation/widgets/exercise_video_sheet.dart
// Aura — Premium HD Exercise Video Demonstration & Gemini AI Form Guide Sheet

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  WebViewController? _webCtrl;
  bool _isWebReady = false;

  String? _aiInstructions;
  String? _aiTips;
  String? _aiCommonMistakes;
  bool _isAiLoading = true;

  static String _getYoutubeVideoId(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('incline')) return '8iPEnn-ltC8';
    if (lower.contains('bench press')) return 'rT7DgCr-3pg';
    if (lower.contains('overhead') || lower.contains('shoulder press') || lower.contains('arnold')) return '2yjwXTZQDDI';
    if (lower.contains('lateral')) return 'PzsMitR9d0E';
    if (lower.contains('flye') || lower.contains('crossover') || lower.contains('pec deck')) return 'Iwe6AmxVf7o';
    if (lower.contains('pull-up') || lower.contains('chin-up')) return 'eGo4IYlbE5g';
    if (lower.contains('lat pulldown')) return 'CAwf7n6Luuc';
    if (lower.contains('row')) return 'FWJR5Ve8bnQ';
    if (lower.contains('squat')) return 'ultWZbUMPL8';
    if (lower.contains('deadlift') || lower.contains('rdl')) return '2SHsk9AzdjA';
    if (lower.contains('leg press')) return 'IZxyjW7MPJQ';
    if (lower.contains('curl')) return 'ykJmrZ5v0Oo';
    if (lower.contains('tricep') || lower.contains('pushdown') || lower.contains('dip') || lower.contains('skull')) return '2-LAMcpzODU';
    return 'rT7DgCr-3pg';
  }

  @override
  void initState() {
    super.initState();
    _initWebPlayer();
    _fetchGeminiFormGuide();
  }

  void _initWebPlayer() {
    final videoId = _getYoutubeVideoId(widget.exerciseName);
    final embedUrl = Uri.parse(
        'https://www.youtube.com/embed/$videoId?autoplay=1&mute=1&loop=1&playlist=$videoId&controls=1&modestbranding=1&rel=0&playsinline=1');

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E3A2B))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isWebReady = true);
            }
          },
        ),
      )
      ..loadRequest(embedUrl);
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
                            'Form Guide & HD Video',
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
                // 🎬 YouTube HD Embedded Video Player
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 215,
                    width: double.infinity,
                    color: const Color(0xFF1E3A2B),
                    child: Stack(
                      children: [
                        if (_webCtrl != null) WebViewWidget(controller: _webCtrl!),
                        if (!_isWebReady)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF81C784)),
                            ),
                          ),
                      ],
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
