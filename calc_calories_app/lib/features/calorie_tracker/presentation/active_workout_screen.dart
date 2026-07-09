// lib/features/calorie_tracker/presentation/active_workout_screen.dart
// The Teneen — Active AI Workout Tracker logging screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with TickerProviderStateMixin {
  // Stopwatch timer state
  late Timer _stopwatchTimer;
  int _secondsElapsed = 1455; // start at 00:24:15

  // Rest timer state
  bool _showRestTimer = false;
  int _restSecondsLeft = 105; // 1:45rest time
  Timer? _restTimer;

  // Set inputs logging values
  final TextEditingController _set1Weight = TextEditingController(text: '100');
  final TextEditingController _set1Reps = TextEditingController(text: '5');
  bool _set1Checked = true;

  final TextEditingController _set2Weight = TextEditingController(text: '90');
  final TextEditingController _set2Reps = TextEditingController();
  bool _set2Checked = false;

  @override
  void initState() {
    super.initState();
    // Start active workout stopwatch timer
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _stopwatchTimer.cancel();
    _restTimer?.cancel();
    _set1Weight.dispose();
    _set1Reps.dispose();
    _set2Weight.dispose();
    _set2Reps.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _showRestTimer = true;
      _restSecondsLeft = 105; // reset to 1:45
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsLeft > 0) {
        setState(() {
          _restSecondsLeft--;
        });
      } else {
        setState(() {
          _showRestTimer = false;
        });
        _restTimer?.cancel();
      }
    });
  }

  String _formatStopwatch(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    
    final String hStr = hours.toString().padLeft(2, '0');
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');
    
    return '$hStr:$mStr:$sStr';
  }

  String _formatRestTimer(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String sStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$sStr';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'اليوم ١: دفع (أسلوب RPT)' : 'Day 1: Push Day (RPT Style)',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatStopwatch(_secondsElapsed),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // Exercise Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'بنش برس بالبار' : 'Barbell Bench Press',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isArabic ? 'الصدر / الكتف' : 'Chest / Shoulders',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Exercise Form Video/Media Card Graphic
              _buildFormPreviewCard(isArabic),

              const SizedBox(height: 24),

              // RPT logging table header
              _buildTableHeader(isArabic),

              const SizedBox(height: 8),

              // Set 1 (Top Set)
              _buildSetRow(
                setIndex: 1,
                targetText: isArabic ? 'الهدف: ٤-٦ عدات' : 'Target: 4-6 Reps',
                weightController: _set1Weight,
                repsController: _set1Reps,
                isChecked: _set1Checked,
                hasGoldStar: true,
                onCheckedChange: (val) {
                  setState(() {
                    _set1Checked = val ?? false;
                    if (_set1Checked) _startRestTimer();
                  });
                },
                isArabic: isArabic,
              ),

              const SizedBox(height: 12),

              // Set 2 (Back-off Set)
              _buildSetRow(
                setIndex: 2,
                targetText: isArabic
                    ? 'الهدف: ٩٠ كجم | ٦-٨ عدات'
                    : 'Target: 90 kg | 6-8 Reps',
                weightController: _set2Weight,
                repsController: _set2Reps,
                isChecked: _set2Checked,
                hasGoldStar: false,
                onCheckedChange: (val) {
                  setState(() {
                    _set2Checked = val ?? false;
                    if (_set2Checked) _startRestTimer();
                  });
                },
                isArabic: isArabic,
              ),
            ],
          ),

          // Floating rest timer widget
          if (_showRestTimer)
            Positioned(
              bottom: 84,
              left: 20,
              right: 20,
              child: _buildRestTimerPopup(isArabic),
            ),

          // Bottom CTA button fixed
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: _buildFinishWorkoutButton(isArabic),
          ),
        ],
      ),
    );
  }

  // ── Exercise Preview Mock ──────────────────────────────────────────
  Widget _buildFormPreviewCard(bool isArabic) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceVariant,
            AppColors.surface,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Graphic form vectors
          Opacity(
            opacity: 0.25,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          // Loop playback labels
          Positioned(
            bottom: 12,
            right: isArabic ? null : 12,
            left: isArabic ? 12 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.loop_rounded, color: AppColors.primary, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'دليل الأداء الحي' : 'FORM DEMO LOOP',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Table Header labels ────────────────────────────────────────────
  Widget _buildTableHeader(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              isArabic ? 'المجموعة والهدف' : 'SET & TARGET',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isArabic ? 'الوزن (كجم)' : 'WEIGHT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isArabic ? 'العدات' : 'REPS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Space for checkbox
        ],
      ),
    );
  }

  // ── Set Logging Row Widget ──────────────────────────────────────────
  Widget _buildSetRow({
    required int setIndex,
    required String targetText,
    required TextEditingController weightController,
    required TextEditingController repsController,
    required bool isChecked,
    required bool hasGoldStar,
    required ValueChanged<bool?> onCheckedChange,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isChecked ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked ? AppColors.primary.withValues(alpha: 0.6) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Set description & target
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (hasGoldStar) ...[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isArabic ? 'مجموعة $setIndex' : 'Set $setIndex',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasGoldStar ? Colors.amber : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  targetText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Weight Input Field
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),

          // Reps Input Field
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),

          // Checkbox status log
          SizedBox(
            width: 48,
            child: Checkbox(
              value: isChecked,
              onChanged: onCheckedChange,
              activeColor: AppColors.primary,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Auto Rest-Timer Widget ─────────────────────────────────────────
  Widget _buildRestTimerPopup(bool isArabic) {
    final double pct = _restSecondsLeft / 105;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer title & progress ring
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? 'وقت الراحة التلقائي' : 'Rest Timer Active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? 'متبقي ${_formatRestTimer(_restSecondsLeft)} د'
                        : 'Remaining: ${_formatRestTimer(_restSecondsLeft)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Timer controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: AppColors.primary, size: 22),
                onPressed: () {
                  setState(() {
                    _showRestTimer = false;
                    _restTimer?.cancel();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
                onPressed: () {
                  setState(() {
                    _showRestTimer = false;
                    _restTimer?.cancel();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Finish Workout Button Action ──────────────────────────────────
  Widget _buildFinishWorkoutButton(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Success action reward dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isArabic ? 'أحسنت يا بطل! 🚀' : 'Great Job! 🚀',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              content: Text(
                isArabic
                    ? 'تم تسجيل تمرينك بنجاح وكسبت +٣٠ نقطة مكافأة.'
                    : 'Workout successfully logged. You earned +30 reward points.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Pop workout screen back to dashboard
                  },
                  child: Text(
                    isArabic ? 'حسناً' : 'Awesome',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          isArabic ? 'إنهاء التمرين والمطالبة بـ +٣٠ نقطة' : 'Finish Workout & Claim +30 Pts',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
