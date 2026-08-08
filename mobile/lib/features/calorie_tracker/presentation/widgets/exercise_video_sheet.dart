// lib/features/calorie_tracker/presentation/widgets/exercise_video_sheet.dart
// Aura — AI-Generated Exercise Form Video with Biomechanical Animation

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
    with TickerProviderStateMixin {
  AnimationController? _repCtrl;
  AnimationController? _pulseCtrl;
  bool _isPlaying = true;
  bool _isSlowMo = false;
  int _currentRep = 1;
  static const int _totalReps = 8;

  String? _aiInstructions;
  String? _aiTips;
  String? _aiCommonMistakes;
  bool _isAiLoading = true;

  @override
  void initState() {
    super.initState();

    _repCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _currentRep =
                  _currentRep < _totalReps ? _currentRep + 1 : 1;
            });
          }
          _repCtrl?.forward(from: 0.0);
        }
      });

    _pulseCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _repCtrl!.forward();
    _fetchGeminiFormGuide();
  }

  @override
  void dispose() {
    _repCtrl?.dispose();
    _pulseCtrl?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_repCtrl == null || _pulseCtrl == null) return;
    setState(() {
      if (_repCtrl!.isAnimating) {
        _repCtrl!.stop();
        _pulseCtrl!.stop();
        _isPlaying = false;
      } else {
        _repCtrl!.forward();
        _pulseCtrl!.repeat(reverse: true);
        _isPlaying = true;
      }
    });
  }

  void _toggleSpeed() {
    if (_repCtrl == null) return;
    setState(() {
      _isSlowMo = !_isSlowMo;
      final currentVal = _repCtrl!.value;
      _repCtrl!.duration =
          Duration(milliseconds: _isSlowMo ? 5000 : 2400);
      if (_isPlaying) _repCtrl!.forward(from: currentVal);
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
      if (response.statusCode == 200 &&
          response.data['success'] == true) {
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
    } catch (_) {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  ExerciseType get _exerciseType {
    final n = widget.exerciseName.toLowerCase();
    if (n.contains('bench') || n.contains('chest press') || n.contains('push-up') || n.contains('pushup')) {
      return ExerciseType.benchPress;
    }
    if (n.contains('overhead') || n.contains('shoulder press') || n.contains('military') || n.contains('arnold')) {
      return ExerciseType.overheadPress;
    }
    if (n.contains('squat') || n.contains('leg press') || n.contains('lunge')) {
      return ExerciseType.squat;
    }
    if (n.contains('deadlift') || n.contains('rdl') || n.contains('romanian')) {
      return ExerciseType.deadlift;
    }
    if (n.contains('pull') || n.contains('row') || n.contains('lat') || n.contains('chin')) {
      return ExerciseType.pullUp;
    }
    if (n.contains('curl') || n.contains('bicep')) {
      return ExerciseType.curl;
    }
    if (n.contains('tricep') || n.contains('pushdown') || n.contains('extension') || n.contains('dip') || n.contains('skull')) {
      return ExerciseType.tricepPushdown;
    }
    return ExerciseType.benchPress;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

          // Header
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
                      const SizedBox(height: 4),
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
                          if (_pulseCtrl != null)
                            AnimatedBuilder(
                              animation: _pulseCtrl!,
                              builder: (_, __) => Opacity(
                                opacity: _isPlaying
                                    ? 0.5 + _pulseCtrl!.value * 0.5
                                    : 0.5,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF81C784),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI Form Video',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF235A42),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // AI Form Video Player
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D1F14), Color(0xFF0A1610)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _repCtrl == null
                        ? const SizedBox.shrink()
                        : AnimatedBuilder(
                      animation: _repCtrl!,
                      builder: (context, _) {
                        final raw = _repCtrl!.value;
                        final t = math.sin(raw * math.pi);
                        return Stack(
                          children: [
                            // Background grid
                            CustomPaint(
                              size: const Size(double.infinity, 240),
                              painter: _GridPainter(),
                            ),
                            // Main athlete animation
                            CustomPaint(
                              size: const Size(double.infinity, 240),
                              painter: AthletePainter(
                                t: t,
                                raw: raw,
                                exerciseType: _exerciseType,
                              ),
                            ),

                            // Top bar
                            Positioned(
                              top: 10,
                              left: 12,
                              right: 12,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: _pulseCtrl == null
                                        ? const SizedBox.shrink()
                                        : AnimatedBuilder(
                                      animation: _pulseCtrl!,
                                      builder: (_, __) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: _isPlaying
                                                  ? Color.lerp(
                                                      const Color(0xFF81C784),
                                                      Colors.white,
                                                      _pulseCtrl!.value * 0.4)
                                                  : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _isPlaying
                                                ? 'GENERATING • AI FORM VIDEO'
                                                : 'PAUSED',
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF81C784),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF235A42)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'REP $_currentRep / $_totalReps',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Muscle group label (mid)
                            Positioned(
                              left: 12,
                              top: 110,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getMuscleLabel(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color.lerp(
                                        const Color(0xFF81C784),
                                        Colors.white,
                                        t * 0.4)!,
                                  ),
                                ),
                              ),
                            ),

                            // Progress bar at bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  // Timeline scrubber
                                  Container(
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: raw,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF81C784),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Controls row
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      children: [
                                        // Phase text
                                        Expanded(
                                          child: Text(
                                            _getPhaseLabel(t),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF8FB89A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Play/pause
                                        GestureDetector(
                                          onTap: _togglePlayPause,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF81C784),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: const Color(0xFF0D1F14),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Speed
                                        GestureDetector(
                                          onTap: _toggleSpeed,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _isSlowMo
                                                  ? const Color(0xFFF59E0B)
                                                  : Colors.white
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _isSlowMo ? '0.5×' : '1×',
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
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildSectionCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF235A42),
                  title: 'Step-by-Step Execution',
                  content: widget.instructions ??
                      _aiInstructions ??
                      '1. Set up with your feet shoulder-width apart.\n'
                          '2. Engage your core and keep your chest proud.\n'
                          '3. Control the eccentric phase for 2-3 seconds.\n'
                          '4. Drive powerfully through the full range of motion.',
                ),

                const SizedBox(height: 12),

                _buildSectionCard(
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Pro Coaching Cues',
                  content: widget.tips ??
                      _aiTips ??
                      '• Squeeze the target muscle at peak contraction for 1 second.\n'
                          '• Keep your shoulder blades retracted and avoid using momentum.',
                ),

                const SizedBox(height: 12),

                _buildSectionCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Common Mistakes to Avoid',
                  content: widget.commonMistakes ??
                      _aiCommonMistakes ??
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

  String _getMuscleLabel() {
    switch (_exerciseType) {
      case ExerciseType.benchPress: return '🔥 Chest · Triceps · Anterior Delt';
      case ExerciseType.overheadPress: return '🔥 Delts · Triceps · Upper Trap';
      case ExerciseType.squat: return '🔥 Quads · Glutes · Hamstrings';
      case ExerciseType.deadlift: return '🔥 Hamstrings · Glutes · Erectors';
      case ExerciseType.pullUp: return '🔥 Lats · Rhomboids · Biceps';
      case ExerciseType.curl: return '🔥 Biceps · Brachialis';
      case ExerciseType.tricepPushdown: return '🔥 Triceps Long · Lateral Head';
    }
  }

  String _getPhaseLabel(double t) {
    if (t < 0.2) return '⬇ Eccentric — controlled lowering';
    if (t < 0.8) return '💥 Concentric — explosive drive';
    return '🔝 Peak contraction — hold & squeeze';
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
              if (_isAiLoading && title.contains('Step')) ...[
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
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EXERCISE TYPE ENUM ──────────────────────────────────────────────────────
enum ExerciseType {
  benchPress,
  overheadPress,
  squat,
  deadlift,
  pullUp,
  curl,
  tricepPushdown,
}

// ─── BACKGROUND GRID PAINTER ─────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF81C784).withOpacity(0.05)
      ..strokeWidth = 0.8;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── ATHLETE PAINTER ─────────────────────────────────────────────────────────
class AthletePainter extends CustomPainter {
  final double t;   // 0→1→0  smooth eased
  final double raw; // 0→1 linear
  final ExerciseType exerciseType;

  AthletePainter({
    required this.t,
    required this.raw,
    required this.exerciseType,
  });

  // helpers
  static const _white = Color(0xFFE8F5E9);
  static const _green = Color(0xFF81C784);
  static const _darkGreen = Color(0xFF235A42);

  Paint _joint({double r = 5}) => Paint()..color = _white;
  Paint _bone({double w = 3.5}) => Paint()
    ..color = _white
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  Paint _musclePaint(Color c, double opacity) => Paint()
    ..color = c.withOpacity(opacity)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

  void _dot(Canvas c, Offset p, {double r = 5, Color color = _white}) {
    c.drawCircle(p, r, Paint()..color = color);
  }

  void _line(Canvas c, Offset a, Offset b, {double w = 3.5, Color color = _white}) {
    c.drawLine(a, b, Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final floor = size.height - 22;

    switch (exerciseType) {
      case ExerciseType.benchPress:
        _drawBenchPress(canvas, size, cx, floor);
        break;
      case ExerciseType.overheadPress:
        _drawOverheadPress(canvas, size, cx, floor);
        break;
      case ExerciseType.squat:
        _drawSquat(canvas, size, cx, floor);
        break;
      case ExerciseType.deadlift:
        _drawDeadlift(canvas, size, cx, floor);
        break;
      case ExerciseType.pullUp:
        _drawPullUp(canvas, size, cx, floor);
        break;
      case ExerciseType.curl:
        _drawCurl(canvas, size, cx, floor);
        break;
      case ExerciseType.tricepPushdown:
        _drawTricepPushdown(canvas, size, cx, floor);
        break;
    }
  }

  // ── BENCH PRESS ─────────────────────────────────────────────────────────
  void _drawBenchPress(Canvas canvas, Size size, double cx, double floor) {
    // Arms go up/down with t
    final liftAmount = t * 58.0;

    // Bench
    _line(canvas, Offset(cx - 65, floor - 42), Offset(cx + 65, floor - 42),
        w: 9, color: _darkGreen);
    _line(canvas, Offset(cx - 30, floor - 42), Offset(cx - 30, floor),
        w: 6, color: _darkGreen);
    _line(canvas, Offset(cx + 30, floor - 42), Offset(cx + 30, floor),
        w: 6, color: _darkGreen);

    // Body lying on bench
    final torsoY = floor - 58.0;
    // Torso
    _line(canvas, Offset(cx - 25, torsoY), Offset(cx + 25, torsoY),
        w: 22, color: const Color(0xFF1E3A2B));
    _line(canvas, Offset(cx - 25, torsoY), Offset(cx + 25, torsoY),
        w: 18, color: const Color(0xFF2A5240));

    // Head
    _dot(canvas, Offset(cx + 30, torsoY), r: 11, color: const Color(0xFF2A5240));
    _dot(canvas, Offset(cx + 30, torsoY), r: 8, color: const Color(0xFF3D7A62));

    // Chest muscle glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, torsoY), width: 50 + t * 10, height: 24 + t * 6),
      _musclePaint(_green, 0.18 + t * 0.45),
    );

    // Barbell
    final barY = torsoY - 38 + liftAmount;
    _line(canvas, Offset(cx - 82, barY), Offset(cx + 82, barY),
        w: 5, color: Colors.white);
    // Plates
    _plateRect(canvas, Offset(cx - 82, barY), left: true);
    _plateRect(canvas, Offset(cx + 82, barY), left: false);

    // Arms
    final shoulderL = Offset(cx - 20, torsoY - 5);
    final shoulderR = Offset(cx + 20, torsoY - 5);
    final elbowL = Offset(cx - 50, torsoY - 5 - liftAmount * 0.5);
    final elbowR = Offset(cx + 50, torsoY - 5 - liftAmount * 0.5);
    final handL = Offset(cx - 65, barY);
    final handR = Offset(cx + 65, barY);

    // Upper arms
    _line(canvas, shoulderL, elbowL, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, shoulderR, elbowR, w: 7, color: const Color(0xFF3D7A62));
    // Forearms
    _line(canvas, elbowL, handL, w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, elbowR, handR, w: 6, color: const Color(0xFF3D7A62));

    // Joints
    _dot(canvas, elbowL, r: 5, color: _white);
    _dot(canvas, elbowR, r: 5, color: _white);
    _dot(canvas, handL, r: 4, color: _white);
    _dot(canvas, handR, r: 4, color: _white);
  }

  void _plateRect(Canvas canvas, Offset pos, {required bool left}) {
    final dx = left ? -10.0 : 0.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx + dx, pos.dy - 20, 10, 40),
        const Radius.circular(3),
      ),
      Paint()..color = _green,
    );
  }

  // ── OVERHEAD PRESS ───────────────────────────────────────────────────────
  void _drawOverheadPress(Canvas canvas, Size size, double cx, double floor) {
    final liftAmount = t * 50.0;
    final standY = floor;
    final hipY = standY - 50;
    final waistY = hipY - 30;
    final chestY = waistY - 35;
    final neckY = chestY - 10;
    final headY = neckY - 13;

    // Legs
    _line(canvas, Offset(cx, hipY), Offset(cx - 16, standY), w: 9, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx, hipY), Offset(cx + 16, standY), w: 9, color: const Color(0xFF2A5240));

    // Feet
    _line(canvas, Offset(cx - 16, standY), Offset(cx - 26, standY), w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, Offset(cx + 16, standY), Offset(cx + 26, standY), w: 7, color: const Color(0xFF3D7A62));

    // Torso
    _line(canvas, Offset(cx, hipY), Offset(cx, chestY), w: 13, color: const Color(0xFF2A5240));

    // Shoulder glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, chestY), width: 44 + t * 12, height: 18 + t * 8),
      _musclePaint(const Color(0xFF64B5F6), 0.18 + t * 0.5),
    );

    // Head
    _dot(canvas, Offset(cx, headY), r: 13, color: const Color(0xFF2A5240));
    _dot(canvas, Offset(cx, headY), r: 10, color: const Color(0xFF3D7A62));

    // Barbell (starts at chin, presses overhead)
    final barY = chestY - 30 - liftAmount;
    _line(canvas, Offset(cx - 75, barY), Offset(cx + 75, barY), w: 5, color: Colors.white);
    _plateRect(canvas, Offset(cx - 75, barY), left: true);
    _plateRect(canvas, Offset(cx + 75, barY), left: false);

    // Arms
    final sL = Offset(cx - 14, chestY);
    final sR = Offset(cx + 14, chestY);
    final eL = Offset(cx - 38, chestY - 15 - liftAmount * 0.4);
    final eR = Offset(cx + 38, chestY - 15 - liftAmount * 0.4);
    final hL = Offset(cx - 58, barY);
    final hR = Offset(cx + 58, barY);

    _line(canvas, sL, eL, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, sR, eR, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, eL, hL, w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, eR, hR, w: 6, color: const Color(0xFF3D7A62));
    _dot(canvas, eL, r: 5);
    _dot(canvas, eR, r: 5);
  }

  // ── SQUAT ────────────────────────────────────────────────────────────────
  void _drawSquat(Canvas canvas, Size size, double cx, double floor) {
    // t=0 standing, t=1 bottom of squat
    final squat = t;
    final hipDrop = squat * 55.0;
    final kneeSpread = squat * 20.0;

    final standY = floor;
    final ankleL = Offset(cx - 22, standY);
    final ankleR = Offset(cx + 22, standY);
    final kneeL = Offset(cx - 22 - kneeSpread, standY - 55 + hipDrop);
    final kneeR = Offset(cx + 22 + kneeSpread, standY - 55 + hipDrop);
    final hipL = Offset(cx - 14, standY - 110 + hipDrop);
    final hipR = Offset(cx + 14, standY - 110 + hipDrop);
    final hip = Offset(cx, standY - 110 + hipDrop);
    final waist = Offset(cx, standY - 140 + hipDrop * 0.6);
    final chest = Offset(cx, standY - 170 + hipDrop * 0.4);
    final head = Offset(cx, standY - 192 + hipDrop * 0.3);

    // Quad / glute glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, standY - 80 + hipDrop),
          width: 70 + squat * 20, height: 35 + squat * 15),
      _musclePaint(const Color(0xFFFFB74D), 0.18 + squat * 0.42),
    );

    // Barbell across shoulders
    _line(canvas, Offset(cx - 80, chest.dy - 4), Offset(cx + 80, chest.dy - 4),
        w: 5, color: Colors.white);
    _plateRect(canvas, Offset(cx - 80, chest.dy - 4), left: true);
    _plateRect(canvas, Offset(cx + 80, chest.dy - 4), left: false);

    // Calves
    _line(canvas, ankleL, kneeL, w: 8, color: const Color(0xFF2A5240));
    _line(canvas, ankleR, kneeR, w: 8, color: const Color(0xFF2A5240));
    // Thighs
    _line(canvas, kneeL, hipL, w: 10, color: const Color(0xFF2A5240));
    _line(canvas, kneeR, hipR, w: 10, color: const Color(0xFF2A5240));
    // Torso
    _line(canvas, hip, waist, w: 13, color: const Color(0xFF2A5240));
    _line(canvas, waist, chest, w: 13, color: const Color(0xFF2A5240));

    // Feet
    _line(canvas, ankleL, Offset(ankleL.dx - 10, ankleL.dy), w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, ankleR, Offset(ankleR.dx + 10, ankleR.dy), w: 6, color: const Color(0xFF3D7A62));

    // Joints
    _dot(canvas, kneeL, r: 6);
    _dot(canvas, kneeR, r: 6);
    _dot(canvas, hip, r: 7);

    // Head
    _dot(canvas, head, r: 13, color: const Color(0xFF2A5240));
    _dot(canvas, head, r: 10, color: const Color(0xFF3D7A62));
  }

  // ── DEADLIFT ─────────────────────────────────────────────────────────────
  void _drawDeadlift(Canvas canvas, Size size, double cx, double floor) {
    // t=0 bottom, t=1 standing
    final lift = t;
    final hipRise = lift * 75.0;

    final ankleL = Offset(cx - 18, floor);
    final ankleR = Offset(cx + 18, floor);
    final kneeL = Offset(cx - 18, floor - 50 - hipRise * 0.2);
    final kneeR = Offset(cx + 18, floor - 50 - hipRise * 0.2);
    final hip = Offset(cx, floor - 70 - hipRise);
    final chest = Offset(cx, floor - 120 - hipRise * 0.5);
    final head = Offset(cx, floor - 145 - hipRise * 0.4);

    // Barbell stays near floor (hand position)
    final barY = floor - 18;
    _line(canvas, Offset(cx - 85, barY), Offset(cx + 85, barY), w: 5, color: Colors.white);
    _plateRect(canvas, Offset(cx - 85, barY), left: true);
    _plateRect(canvas, Offset(cx + 85, barY), left: false);

    // Hamstring glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, floor - 35 - hipRise * 0.5),
          width: 50, height: 30 + lift * 20),
      _musclePaint(const Color(0xFFEF9A9A), 0.2 + lift * 0.4),
    );

    // Legs
    _line(canvas, ankleL, kneeL, w: 8, color: const Color(0xFF2A5240));
    _line(canvas, ankleR, kneeR, w: 8, color: const Color(0xFF2A5240));
    _line(canvas, kneeL, hip, w: 10, color: const Color(0xFF2A5240));
    _line(canvas, kneeR, hip, w: 10, color: const Color(0xFF2A5240));

    // Torso
    _line(canvas, hip, chest, w: 13, color: const Color(0xFF2A5240));

    // Arms (hanging, holding bar)
    final handL = Offset(cx - 34, barY);
    final handR = Offset(cx + 34, barY);
    final shoulderL = Offset(cx - 14, chest.dy);
    final shoulderR = Offset(cx + 14, chest.dy);
    _line(canvas, shoulderL, handL, w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, shoulderR, handR, w: 6, color: const Color(0xFF3D7A62));

    // Joints
    _dot(canvas, kneeL, r: 5);
    _dot(canvas, kneeR, r: 5);
    _dot(canvas, hip, r: 7);

    // Head
    _dot(canvas, head, r: 13, color: const Color(0xFF2A5240));
    _dot(canvas, head, r: 10, color: const Color(0xFF3D7A62));

    // Feet
    _line(canvas, ankleL, Offset(ankleL.dx - 10, ankleL.dy), w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, ankleR, Offset(ankleR.dx + 10, ankleR.dy), w: 6, color: const Color(0xFF3D7A62));
  }

  // ── PULL-UP ──────────────────────────────────────────────────────────────
  void _drawPullUp(Canvas canvas, Size size, double cx, double floor) {
    final pullUp = t;
    final chinRise = pullUp * 60.0;

    final barY = 22.0;
    // Pull-up bar
    _line(canvas, Offset(cx - 70, barY), Offset(cx + 70, barY), w: 8, color: _white);
    _dot(canvas, Offset(cx - 70, barY), r: 5);
    _dot(canvas, Offset(cx + 70, barY), r: 5);

    final handY = barY + 5;
    final bodyY = handY + 90 - chinRise;
    final hipY = bodyY + 40;

    // Lat glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyY),
          width: 50 + pullUp * 20, height: 30 + pullUp * 12),
      _musclePaint(const Color(0xFF4DD0E1), 0.18 + pullUp * 0.48),
    );

    // Torso
    _line(canvas, Offset(cx, bodyY - 15), Offset(cx, hipY), w: 13, color: const Color(0xFF2A5240));

    // Legs hanging
    _line(canvas, Offset(cx, hipY), Offset(cx - 12, hipY + 45), w: 8, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx, hipY), Offset(cx + 12, hipY + 45), w: 8, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx - 12, hipY + 45), Offset(cx - 8, hipY + 80), w: 7, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx + 12, hipY + 45), Offset(cx + 8, hipY + 80), w: 7, color: const Color(0xFF2A5240));

    // Arms
    final hL = Offset(cx - 28, handY);
    final hR = Offset(cx + 28, handY);
    final eL = Offset(cx - 38, bodyY - 20 + (1 - pullUp) * 20);
    final eR = Offset(cx + 38, bodyY - 20 + (1 - pullUp) * 20);
    final sL = Offset(cx - 14, bodyY - 10);
    final sR = Offset(cx + 14, bodyY - 10);

    _line(canvas, hL, eL, w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, hR, eR, w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, eL, sL, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, eR, sR, w: 7, color: const Color(0xFF3D7A62));
    _dot(canvas, eL, r: 5);
    _dot(canvas, eR, r: 5);
    _dot(canvas, hL, r: 4);
    _dot(canvas, hR, r: 4);

    // Head
    final headY = bodyY - 28;
    _dot(canvas, Offset(cx, headY), r: 13, color: const Color(0xFF2A5240));
    _dot(canvas, Offset(cx, headY), r: 10, color: const Color(0xFF3D7A62));
  }

  // ── BICEP CURL ───────────────────────────────────────────────────────────
  void _drawCurl(Canvas canvas, Size size, double cx, double floor) {
    final curl = t;
    final curlAngle = curl * (math.pi * 0.78);

    final standY = floor;
    final hipY = standY - 50;
    final waistY = hipY - 30;
    final chestY = waistY - 40;
    final headY = chestY - 25;

    // Legs
    _line(canvas, Offset(cx - 16, standY), Offset(cx - 16, hipY), w: 9, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx + 16, standY), Offset(cx + 16, hipY), w: 9, color: const Color(0xFF2A5240));
    // Feet
    _line(canvas, Offset(cx - 16, standY), Offset(cx - 26, standY), w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, Offset(cx + 16, standY), Offset(cx + 26, standY), w: 6, color: const Color(0xFF3D7A62));

    // Torso
    _line(canvas, Offset(cx, hipY), Offset(cx, chestY), w: 13, color: const Color(0xFF2A5240));

    // Bicep glow
    final bicepCenter = Offset(cx - 30, chestY + 18);
    canvas.drawOval(
      Rect.fromCenter(center: bicepCenter, width: 18 + curl * 10, height: 30 + curl * 8),
      _musclePaint(_green, 0.2 + curl * 0.5),
    );

    // Right arm (static, slightly bent)
    final rshoulder = Offset(cx + 14, chestY);
    final relbow = Offset(cx + 30, chestY + 30);
    final rhand = Offset(cx + 28, chestY + 60);
    _line(canvas, rshoulder, relbow, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, relbow, rhand, w: 6, color: const Color(0xFF3D7A62));
    _dot(canvas, relbow, r: 5);

    // Left arm (curling)
    final lshoulder = Offset(cx - 14, chestY);
    final lelbow = Offset(cx - 30, chestY + 32);
    // Hand position based on curl angle
    final forearmLen = 42.0;
    final lhand = Offset(
      lelbow.dx - math.sin(curlAngle) * forearmLen,
      lelbow.dy - math.cos(curlAngle) * forearmLen + forearmLen,
    );

    _line(canvas, lshoulder, lelbow, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, lelbow, lhand, w: 6, color: const Color(0xFF3D7A62));
    _dot(canvas, lelbow, r: 5);

    // Dumbbell in left hand
    _dot(canvas, lhand, r: 7, color: Colors.white);
    _line(canvas, Offset(lhand.dx - 10, lhand.dy), Offset(lhand.dx + 10, lhand.dy), w: 4, color: Colors.white);

    // Dumbbell in right hand
    _dot(canvas, rhand, r: 7, color: Colors.white);
    _line(canvas, Offset(rhand.dx - 10, rhand.dy), Offset(rhand.dx + 10, rhand.dy), w: 4, color: Colors.white);

    // Head
    _dot(canvas, Offset(cx, headY), r: 13, color: const Color(0xFF2A5240));
    _dot(canvas, Offset(cx, headY), r: 10, color: const Color(0xFF3D7A62));
  }

  // ── TRICEP PUSHDOWN ──────────────────────────────────────────────────────
  void _drawTricepPushdown(Canvas canvas, Size size, double cx, double floor) {
    final push = t;

    final standY = floor;
    final hipY = standY - 50;
    final chestY = hipY - 70;
    final headY = chestY - 25;

    // Legs
    _line(canvas, Offset(cx - 15, standY), Offset(cx - 15, hipY), w: 9, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx + 15, standY), Offset(cx + 15, hipY), w: 9, color: const Color(0xFF2A5240));
    _line(canvas, Offset(cx - 15, standY), Offset(cx - 25, standY), w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, Offset(cx + 15, standY), Offset(cx + 25, standY), w: 6, color: const Color(0xFF3D7A62));

    // Torso
    _line(canvas, Offset(cx, hipY), Offset(cx, chestY), w: 13, color: const Color(0xFF2A5240));

    // Cable from top
    _line(canvas, Offset(cx, 20), Offset(cx, chestY - 15), w: 2, color: Colors.white38);

    // Tricep glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, chestY + 25 + push * 15),
          width: 38 + push * 8, height: 22 + push * 10),
      _musclePaint(const Color(0xFFCE93D8), 0.2 + push * 0.5),
    );

    // Arms: elbows pinned to sides, forearms push down
    final elbowL = Offset(cx - 22, chestY + 5);
    final elbowR = Offset(cx + 22, chestY + 5);
    final shoulderL = Offset(cx - 14, chestY);
    final shoulderR = Offset(cx + 14, chestY);
    final handY = chestY + 10 + push * 55;
    final handL = Offset(cx - 16, handY);
    final handR = Offset(cx + 16, handY);

    _line(canvas, shoulderL, elbowL, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, shoulderR, elbowR, w: 7, color: const Color(0xFF3D7A62));
    _line(canvas, elbowL, handL, w: 6, color: const Color(0xFF3D7A62));
    _line(canvas, elbowR, handR, w: 6, color: const Color(0xFF3D7A62));
    _dot(canvas, elbowL, r: 5);
    _dot(canvas, elbowR, r: 5);

    // Bar attachment
    _line(canvas, handL, handR, w: 5, color: Colors.white);
    _dot(canvas, handL, r: 5);
    _dot(canvas, handR, r: 5);

    // Head
    _dot(canvas, Offset(cx, headY), r: 13, color: const Color(0xFF2A5240));
    _dot(canvas, Offset(cx, headY), r: 10, color: const Color(0xFF3D7A62));
  }

  @override
  bool shouldRepaint(covariant AthletePainter old) =>
      old.t != t || old.raw != raw;
}
