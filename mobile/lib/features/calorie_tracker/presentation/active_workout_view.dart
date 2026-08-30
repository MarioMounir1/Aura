import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/models/workout_models.dart';
import '../domain/repositories/workout_repository.dart';
import 'bloc/workout_bloc.dart';
import 'bloc/workout_event.dart';
import 'bloc/workout_state.dart';

// ── Light-theme palette for ActiveWorkoutView ─────────────────
abstract class _C {
  // Backgrounds & Surfaces
  static const Color background    = Color(0xFFF6F8F5);
  static const Color card          = Color(0xFFFFFFFF);
  static const Color cardElev      = Color(0xFFF1F6F2);
  static const Color surface       = Color(0xFFF1F6F2);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Borders
  static const Color border        = Color(0xFFE2EBE4);
  static const Color borderMid     = Color(0xFFD3E4D7);

  // Text
  static const Color textPrimary   = Color(0xFF1C2B1E);
  static const Color textSecondary = Color(0xFF5A6E5D);
  static const Color textMuted     = Color(0xFF7A8B7B);
  static const Color textPri       = Color(0xFF1C2B1E);
  static const Color textSec       = Color(0xFF5A6E5D);
  static const Color textMut       = Color(0xFF7A8B7B);

  // Brand
  static const Color primary       = Color(0xFF235A42);
  static const Color cyan          = Color(0xFF235A42);
  static const Color accent        = Color(0xFF235A42);

  // Semantic
  static const Color success       = Color(0xFF235A42);
  static const Color error         = Color(0xFFEF4444);
  static const Color amber         = Color(0xFFF59E0B);
  static const Color warning       = Color(0xFFF59E0B);
}

// ═══════════════════════════════════════════════════════════════
// Active Workout View (Dynamic)
// ═══════════════════════════════════════════════════════════════

class ActiveWorkoutView extends StatefulWidget {
  final WorkoutSessionActive sessionState;
  final bool isArabic;
  final VoidCallback onFinish;
  final VoidCallback onExit;

  const ActiveWorkoutView({
    super.key,
    required this.sessionState,
    required this.isArabic,
    required this.onFinish,
    required this.onExit,
  });

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView> {
  Timer? _timer;
  int _timerSeconds = 0;
  int _totalTimerSeconds = 90;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _timerSeconds = seconds;
      _totalTimerSeconds = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 1) {
        _stopTimer();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 0;
    });
  }

  void _adjustTimer(int delta) {
    setState(() {
      _timerSeconds = (_timerSeconds + delta).clamp(0, 999);
      if (_timerSeconds > _totalTimerSeconds) {
        _totalTimerSeconds = _timerSeconds;
      }
    });
    if (_timerSeconds == 0) {
      _stopTimer();
    }
  }

  void _showAddExerciseSheet(BuildContext context) {
    if (widget.sessionState.availableExercises == null) {
      context.read<WorkoutBloc>().add(const FetchAvailableExercises());
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExerciseSheet(isArabic: widget.isArabic),
    );
  }

  Widget _buildTimerBanner() {
    final minutes = (_timerSeconds / 60).floor();
    final seconds = _timerSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = _timerSeconds / _totalTimerSeconds;

    return Container(
      decoration: BoxDecoration(
        color: _C.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cyan.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.cyan.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: _C.cyan, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    widget.isArabic ? 'وقت الراحة' : 'Rest Timer',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textPri,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _C.cyan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // -10s
                  TextButton(
                    onPressed: () => _adjustTimer(-10),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '-10s',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.textSec,
                      ),
                    ),
                  ),
                  // +10s
                  TextButton(
                    onPressed: () => _adjustTimer(10),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '+10s',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Skip
                  ElevatedButton(
                    onPressed: _stopTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.cardElev,
                      foregroundColor: _C.textPri,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'تخطي' : 'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress Bar
            Container(
              height: 3,
              width: double.infinity,
              color: _C.border,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(color: _C.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.sessionState.currentLogs;
    final totalSets = logs.fold<int>(0, (sum, log) => sum + log.sets.length);
    final loggedSets = logs.fold<int>(0, (sum, log) => sum + log.loggedSetsCount);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onExit();
      },
      child: Stack(
        children: [
        Column(
          key: const ValueKey('activeWorkout'),
          children: [
            // AppBar-like header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: _C.card,
                border: Border(bottom: BorderSide(color: _C.border, width: 1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: const Icon(Icons.close_rounded, color: _C.textPri, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.isArabic ? 'جلسة التمرين النشطة' : 'Active Workout Session',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _C.textPri),
                    ),
                  ),
                  // Logged set counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.cyan.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.cyan.withOpacity(0.25)),
                    ),
                    child: Text(
                      '$loggedSets/$totalSets sets',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700, color: _C.cyan),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemCount: logs.length + 1,
                itemBuilder: (context, index) {
                  if (index == logs.length) {
                    // Add Exercise & Finish Workout Buttons
                    return Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 40),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => _showAddExerciseSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.cardElev,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: _C.border, width: 1.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded, color: _C.cyan),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isArabic ? 'إضافة تمرين' : 'Add Exercise',
                                  style: GoogleFonts.inter(
                                    color: _C.cyan,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _C.cyan,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.cyan.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: widget.onFinish,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.isArabic ? 'إنهاء التمرين' : 'Finish Workout',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
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
                  return _ExerciseCard(
                    log: logs[index],
                    isArabic: widget.isArabic,
                    onSetCompleted: () => _startTimer(90),
                  );
                },
              ),
            ),
          ],
        ),
        if (_timerSeconds > 0)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildTimerBanner(),
          ),
      ],
    ),
  );
  }
}

class _ExerciseCard extends StatefulWidget {
  final WorkoutLog log;
  final bool isArabic;
  final VoidCallback onSetCompleted;

  const _ExerciseCard({
    required this.log,
    required this.isArabic,
    required this.onSetCompleted,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late List<TextEditingController> _weightCtrl;
  late List<TextEditingController> _repsCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(_ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsReinit = oldWidget.log.sets.length != widget.log.sets.length;
    if (!needsReinit) {
      for (int i = 0; i < widget.log.sets.length; i++) {
        final os = oldWidget.log.sets[i];
        final ns = widget.log.sets[i];
        if (os.isLogged != ns.isLogged ||
            os.loggedWeightKg != ns.loggedWeightKg ||
            os.loggedReps != ns.loggedReps) {
          needsReinit = true;
          break;
        }
      }
    }
    if (needsReinit) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    _weightCtrl = widget.log.sets.map((s) {
      final val = s.loggedWeightKg ?? s.targetWeightKg;
      String text = '';
      if (val != null) {
        text = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
      }
      return TextEditingController(text: text);
    }).toList();

    _repsCtrl = widget.log.sets.map((s) {
      final val = s.loggedReps ?? s.targetReps;
      String text = '';
      if (val != null) {
        text = val.toString();
      }
      return TextEditingController(text: text);
    }).toList();
  }

  void _stepWeight(int index, double delta) {
    if (widget.log.sets[index].isLogged) return;
    final currentText = _weightCtrl[index].text.trim();
    double currentVal = double.tryParse(currentText) ?? widget.log.sets[index].targetWeightKg ?? 0.0;
    double newVal = (currentVal + delta).clamp(0.0, 500.0);
    newVal = double.parse(newVal.toStringAsFixed(1));
    _weightCtrl[index].text = newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toString();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _stepReps(int index, int delta) {
    if (widget.log.sets[index].isLogged) return;
    final currentText = _repsCtrl[index].text.trim();
    int currentVal = int.tryParse(currentText) ?? widget.log.sets[index].targetReps ?? 0;
    int newVal = (currentVal + delta).clamp(0, 100);
    _repsCtrl[index].text = newVal.toString();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _disposeControllers() {
    for (final c in _weightCtrl) c.dispose();
    for (final c in _repsCtrl) c.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _logSet(int index) {
    final weightStr = _weightCtrl[index].text.trim();
    final repsStr   = _repsCtrl[index].text.trim();

    final weight = weightStr.isEmpty
        ? widget.log.sets[index].targetWeightKg
        : double.tryParse(weightStr);
    final reps = repsStr.isEmpty
        ? widget.log.sets[index].targetReps
        : int.tryParse(repsStr);

    if (weight == null || reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter valid weight and reps.',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: _C.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final s = widget.log.sets[index];
    final bool willLog = !s.isLogged;

    if (willLog) {
      context.read<WorkoutBloc>().add(
        LogSetEvent(
          setIndex: s.setIndex,
          weightKg: weight,
          reps: reps,
          workoutExerciseId: s.id ?? widget.log.exerciseName,
        ),
      );
      widget.onSetCompleted();
    }
    HapticFeedback.lightImpact();
  }

  /// Opens the bottom-sheet numpad for weight or reps entry.
  Future<void> _openNumpad({
    required int index,
    required bool isWeight,
  }) async {
    if (widget.log.sets[index].isLogged) return;
    final s = widget.log.sets[index];
    final ctrl = isWeight ? _weightCtrl[index] : _repsCtrl[index];
    final lastVal = isWeight
        ? (s.loggedWeightKg ?? s.targetWeightKg)
        : (s.loggedReps ?? s.targetReps)?.toDouble();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ValueNumpad(
        initialValue: ctrl.text.isNotEmpty ? ctrl.text : '',
        hintValue: lastVal,
        isWeight: isWeight,
        label: isWeight ? 'Weight (kg)' : 'Reps',
        quickAdds: isWeight
            ? const [2.5, 5.0, 10.0]
            : const [1.0, 2.0, 5.0],
        onConfirm: (value) {
          setState(() {
            ctrl.text = value;
          });
        },
      ),
    );
  }

  Future<void> _showSwapAlternativesSheet(BuildContext context, WorkoutLog log) async {
    final workoutExerciseId = log.sets.isNotEmpty ? log.sets.first.id : null;
    if (workoutExerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isArabic ? 'لا يمكن تبديل هذا التمرين حالياً' : 'Cannot swap this exercise right now.',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: _C.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _AlternativesBottomSheet(
          log: log,
          workoutExerciseId: workoutExerciseId,
          availableExercises: context.read<WorkoutBloc>().state is WorkoutSessionActive
              ? (context.read<WorkoutBloc>().state as WorkoutSessionActive).availableExercises
              : null,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name + muscle group
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.exerciseName,
                        style: GoogleFonts.inter(
                            fontSize: 22, fontWeight: FontWeight.w900, color: _C.textPri),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: _C.cyan, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: widget.isArabic ? 'استبدال التمرين' : 'Swap Exercise',
                      onPressed: () => _showSwapAlternativesSheet(context, log),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.cardElev,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.border),
                ),
                child: Text(log.muscleGroup,
                    style: GoogleFonts.inter(fontSize: 11, color: _C.textSec)),
              ),
            ],
          ),
          if (log.lastWeekTopPerformance != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.isArabic
                  ? 'الأسبوع الماضي: ${log.lastWeekTopPerformance}'
                  : 'Last week: ${log.lastWeekTopPerformance}',
              style: GoogleFonts.inter(fontSize: 11, color: _C.cyan, fontWeight: FontWeight.w600),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              widget.isArabic ? 'الجلسة الأولى' : 'First Session',
              style: GoogleFonts.inter(fontSize: 11, color: _C.textMut, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 16),

          // Dynamic set rows
          ...List.generate(log.sets.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildSetRow(i, log.sets[i]),
          )),
        ],
      ),
    );
  }

  Widget _buildSetRow(int index, ExerciseSet s) {
    final locked = s.isLogged;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: locked ? _C.cyan.withValues(alpha: 0.10) : _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: locked ? _C.cyan.withValues(alpha: 0.55) : _C.borderMid.withValues(alpha: 0.7),
          width: locked ? 1.8 : 1.0,
        ),
        boxShadow: locked
            ? [BoxShadow(color: _C.cyan.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          // ── Set label ──────────────────────────
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (s.label == 'Top Set') ...[
                    const Icon(Icons.star_rounded, color: _C.amber, size: 13),
                    const SizedBox(width: 3),
                  ],
                  Text('Set ${s.setIndex}',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: s.label == 'Top Set' ? _C.amber : (locked ? _C.cyan : _C.textSec))),
                ]),
                const SizedBox(height: 2),
                Text(s.targetDisplayLabel,
                    style: GoogleFonts.inter(fontSize: 9.5, color: _C.textMut)),
              ],
            ),
          ),

          // ── Weight chip ────────────────────────
          Expanded(
            child: _SwipeValueChip(
              controller: _weightCtrl[index],
              locked: locked,
              hint: s.targetWeightKg != null
                  ? '${s.targetWeightKg!.toStringAsFixed(s.targetWeightKg! % 1 == 0 ? 0 : 1)} kg'
                  : '— kg',
              unit: 'kg',
              stepSmall: 2.5,
              stepLarge: 5.0,
              isDecimal: true,
              onTap: () => _openNumpad(index: index, isWeight: true),
              onStep: (delta) => _stepWeight(index, delta),
            ),
          ),

          const SizedBox(width: 8),

          // ── Reps chip ──────────────────────────
          Expanded(
            child: _SwipeValueChip(
              controller: _repsCtrl[index],
              locked: locked,
              hint: s.targetReps?.toString() ?? '—',
              unit: 'reps',
              stepSmall: 1.0,
              stepLarge: 2.0,
              isDecimal: false,
              onTap: () => _openNumpad(index: index, isWeight: false),
              onStep: (delta) => _stepReps(index, delta.toInt()),
            ),
          ),

          const SizedBox(width: 6),

          // ── Complete button ───────────────────
          GestureDetector(
            onTap: () => _logSet(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: locked ? _C.cyan : _C.cardElev,
                shape: BoxShape.circle,
                border: Border.all(
                  color: locked ? _C.cyan : _C.borderMid,
                  width: 1.5,
                ),
                boxShadow: locked
                    ? [BoxShadow(color: _C.cyan.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Icon(
                locked ? Icons.check_rounded : Icons.check_rounded,
                color: locked ? Colors.white : _C.textMut,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _SwipeValueChip — tappable big chip with swipe-to-adjust
// ═══════════════════════════════════════════════════════════════

class _SwipeValueChip extends StatefulWidget {
  final TextEditingController controller;
  final bool locked;
  final String hint;
  final String unit;
  final double stepSmall;
  final double stepLarge;
  final bool isDecimal;
  final VoidCallback onTap;
  final void Function(double delta) onStep;

  const _SwipeValueChip({
    required this.controller,
    required this.locked,
    required this.hint,
    required this.unit,
    required this.stepSmall,
    required this.stepLarge,
    required this.isDecimal,
    required this.onTap,
    required this.onStep,
  });

  @override
  State<_SwipeValueChip> createState() => _SwipeValueChipState();
}

class _SwipeValueChipState extends State<_SwipeValueChip> {
  double _swipeStartX = 0;
  double _accumulated = 0;
  static const double _pixelsPerStep = 14.0;

  String get _displayText {
    final t = widget.controller.text.trim();
    if (t.isEmpty) return widget.hint;
    return widget.isDecimal
        ? (double.tryParse(t) != null
            ? (double.parse(t) % 1 == 0
                ? '${double.parse(t).toInt()} ${widget.unit}'
                : '${double.parse(t).toStringAsFixed(1)} ${widget.unit}')
            : t)
        : '$t ${widget.unit}';
  }

  bool get _hasValue => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragStart: locked
          ? null
          : (d) {
              _swipeStartX = d.globalPosition.dx;
              _accumulated = 0;
            },
      onHorizontalDragUpdate: locked
          ? null
          : (d) {
              final diff = d.globalPosition.dx - _swipeStartX;
              _accumulated += diff;
              _swipeStartX = d.globalPosition.dx;
              while (_accumulated >= _pixelsPerStep) {
                widget.onStep(widget.stepSmall);
                _accumulated -= _pixelsPerStep;
              }
              while (_accumulated <= -_pixelsPerStep) {
                widget.onStep(-widget.stepSmall);
                _accumulated += _pixelsPerStep;
              }
            },
      onHorizontalDragEnd: locked ? null : (_) => _accumulated = 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: locked
              ? _C.cyan.withValues(alpha: 0.08)
              : (_hasValue ? _C.cardElev : _C.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: locked
                ? _C.cyan.withValues(alpha: 0.35)
                : (_hasValue ? _C.borderMid : _C.border),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _hasValue ? _displayText : widget.hint,
              style: GoogleFonts.inter(
                fontSize: _hasValue ? 15 : 13,
                fontWeight: _hasValue ? FontWeight.w800 : FontWeight.w500,
                color: _hasValue
                    ? (locked ? _C.cyan : _C.textPri)
                    : _C.textMut.withValues(alpha: 0.6),
              ),
            ),
            if (!locked) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left_rounded, size: 12, color: _C.textMut.withValues(alpha: 0.5)),
                  Text(
                    'swipe',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: _C.textMut.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 12, color: _C.textMut.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ValueNumpad — Full bottom-sheet numpad for weight / reps entry
// ═══════════════════════════════════════════════════════════════

class _ValueNumpad extends StatefulWidget {
  final String initialValue;
  final double? hintValue;
  final bool isWeight;
  final String label;
  final List<double> quickAdds;
  final void Function(String value) onConfirm;

  const _ValueNumpad({
    required this.initialValue,
    required this.hintValue,
    required this.isWeight,
    required this.label,
    required this.quickAdds,
    required this.onConfirm,
  });

  @override
  State<_ValueNumpad> createState() => _ValueNumpadState();
}

class _ValueNumpadState extends State<_ValueNumpad> {
  late String _input;
  bool _hasDecimal = false;

  @override
  void initState() {
    super.initState();
    _input = widget.initialValue;
    _hasDecimal = _input.contains('.');
  }

  String get _displayInput {
    if (_input.isEmpty) {
      if (widget.hintValue != null) {
        final v = widget.hintValue!;
        return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      }
      return '0';
    }
    return _input;
  }

  void _append(String digit) {
    setState(() {
      if (digit == '.' && _hasDecimal) return;
      if (digit == '.') _hasDecimal = true;
      if (_input.length >= 6) return;
      _input += digit;
    });
    HapticFeedback.selectionClick();
  }

  void _delete() {
    setState(() {
      if (_input.isEmpty) return;
      if (_input[_input.length - 1] == '.') _hasDecimal = false;
      _input = _input.substring(0, _input.length - 1);
    });
    HapticFeedback.selectionClick();
  }

  void _clear() {
    setState(() {
      _input = '';
      _hasDecimal = false;
    });
    HapticFeedback.mediumImpact();
  }

  void _quickAdd(double amount) {
    final currentStr = _input.isEmpty ? (_displayInput) : _input;
    double current = double.tryParse(currentStr) ?? 0;
    double next = (current + amount).clamp(0, widget.isWeight ? 500 : 100);
    setState(() {
      if (widget.isWeight) {
        _hasDecimal = next % 1 != 0;
        _input = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
      } else {
        _input = next.toInt().toString();
        _hasDecimal = false;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _useLast() {
    if (widget.hintValue == null) return;
    final v = widget.hintValue!;
    setState(() {
      _hasDecimal = v % 1 != 0;
      _input = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
    });
    HapticFeedback.mediumImpact();
  }

  void _confirm() {
    final val = _input.isNotEmpty ? _input : _displayInput;
    widget.onConfirm(val);
    Navigator.pop(context);
    HapticFeedback.lightImpact();
  }

  Widget _numKey(String label, {Color? labelColor, FontWeight? weight}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => label == '⌫' ? _delete() : (label == 'C' ? _clear() : _append(label)),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: label == 'C'
                ? _C.error.withValues(alpha: 0.08)
                : _C.cardElev,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: label == 'C' ? _C.error.withValues(alpha: 0.25) : _C.border,
              width: 1.0,
            ),
          ),
          child: Center(
            child: label == '⌫'
                ? const Icon(Icons.backspace_rounded, size: 20, color: _C.textSec)
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: weight ?? FontWeight.w600,
                      color: labelColor ?? _C.textPri,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _C.borderMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Label
          Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textMut,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Big value display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.borderMid, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _displayInput,
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: _input.isNotEmpty ? _C.textPri : _C.textMut.withValues(alpha: 0.4),
                  ),
                ),
                // Use last button
                if (widget.hintValue != null)
                  GestureDetector(
                    onTap: _useLast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.cyan.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.cyan.withValues(alpha: 0.30), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 13, color: _C.cyan),
                          const SizedBox(width: 4),
                          Text(
                            'Use last',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _C.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick-add chips
          Row(
            children: widget.quickAdds.map((amount) {
              final label = amount % 1 == 0
                  ? '+${amount.toInt()}'
                  : '+$amount';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _quickAdd(amount),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: _C.cyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.cyan.withValues(alpha: 0.25), width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _C.cyan,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Numpad grid
          SizedBox(
            height: 52 * 4,
            child: Column(
              children: [
                Expanded(child: Row(children: [
                  _numKey('1'), _numKey('2'), _numKey('3'),
                ])),
                Expanded(child: Row(children: [
                  _numKey('4'), _numKey('5'), _numKey('6'),
                ])),
                Expanded(child: Row(children: [
                  _numKey('7'), _numKey('8'), _numKey('9'),
                ])),
                Expanded(child: Row(children: [
                  if (widget.isWeight) _numKey('.') else _numKey('C', labelColor: _C.error),
                  _numKey('0'),
                  _numKey('⌫'),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.cyan,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Add Exercise Sheet
// ═══════════════════════════════════════════════════════════════

class _AddExerciseSheet extends StatelessWidget {
  final bool isArabic;

  const _AddExerciseSheet({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, state) {
        if (state is! WorkoutSessionActive) return const SizedBox.shrink();

        final exercises = state.availableExercises;

        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _C.borderMid, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(
                  isArabic ? 'اختر تمريناً' : 'Choose an Exercise',
                  style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _C.textPri,
                  ),
                ),
                const SizedBox(height: 20),
                if (exercises == null)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: _C.cyan)))
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        return InkWell(
                          onTap: () {
                            context.read<WorkoutBloc>().add(AddExerciseToSessionEvent(ex.id));
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: _C.cardElev,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _C.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fitness_center_rounded, color: _C.cyan, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 15, fontWeight: FontWeight.w700, color: _C.textPri,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ex.muscleGroup,
                                        style: GoogleFonts.inter(
                                          fontSize: 12, color: _C.textSec,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.add_circle_outline_rounded, color: _C.cyan, size: 24),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Alternatives Bottom Sheet (Subtle swaps helper)
// ═══════════════════════════════════════════════════════════════

class _AlternativesBottomSheet extends StatefulWidget {
  final WorkoutLog log;
  final String workoutExerciseId;
  final List<Exercise>? availableExercises;
  final bool isArabic;

  const _AlternativesBottomSheet({
    required this.log,
    required this.workoutExerciseId,
    required this.availableExercises,
    required this.isArabic,
  });

  @override
  State<_AlternativesBottomSheet> createState() => _AlternativesBottomSheetState();
}

class _AlternativesBottomSheetState extends State<_AlternativesBottomSheet> {
  List<Exercise> _alternatives = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlternatives();
  }

  Future<void> _fetchAlternatives() async {
    try {
      final available = widget.availableExercises;
      if (available == null) {
        setState(() {
          _error = widget.isArabic ? 'تأكد من تحميل قائمة التمارين أولاً' : 'Exercises catalog not loaded.';
          _isLoading = false;
        });
        return;
      }

      // Find the ID of the current exercise log
      final template = available.firstWhere(
        (e) => e.name.toLowerCase() == widget.log.exerciseName.toLowerCase(),
        orElse: () => Exercise(id: '', name: widget.log.exerciseName, muscleGroup: widget.log.muscleGroup),
      );

      if (template.id.isEmpty) {
        setState(() {
          _error = widget.isArabic ? 'لم يتم العثور على التمرين في الكتالوج' : 'Original exercise not found in catalog.';
          _isLoading = false;
        });
        return;
      }

      final repo = context.read<WorkoutRepository>();
      final data = await repo.getAlternatives(template.id);
      final list = data.map((e) => Exercise.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _alternatives = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _C.border, width: 1.5)),
      ),
      padding: const EdgeInsets.only(top: 14, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: _C.borderMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isArabic ? 'تمارين بديلة' : 'Alternative Movements',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _C.textPri,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isArabic 
                      ? 'استبدل "${widget.log.exerciseName}" بأحد هذه البدائل المقترحة:'
                      : 'Swap "${widget.log.exerciseName}" with one of these alternatives:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _C.textSec,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content body
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(color: _C.cyan),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error!,
            style: GoogleFonts.inter(color: _C.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_alternatives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            widget.isArabic ? 'لا توجد بدائل مقترحة لهذا التمرين' : 'No alternative exercises found.',
            style: GoogleFonts.inter(color: _C.textSec, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _alternatives.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ex = _alternatives[index];
        return InkWell(
          onTap: () {
            context.read<WorkoutBloc>().add(
              SwapWorkoutExercise(
                workoutExerciseId: widget.workoutExerciseId,
                newExerciseId: ex.id,
              ),
            );
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _C.cardElev,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: _C.cyan, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.textPri,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex.muscleGroup,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _C.textSec,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  widget.isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: _C.textSec,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
