// lib/features/calorie_tracker/presentation/workout_screen.dart
// Aura — Workout Hub (Full Dynamic Refactor)
//
// State Machine:
//   unconfigured → loading → ready → activeWorkout
//
// Flow:
//   1. onInit: GET /workouts/routine → unconfigured | ready
//   2. unconfigured → CoachChatCard with greeting (AI-chat-only setup)
//   3. User types → POST /workouts/session/interpret → setup_routine → state = ready
//   4. Start Workout → state = activeWorkout (inline tracker)
//   5. Finish → state = ready, sets cleared

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../premium/data/services/purchase_service.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../profile/presentation/bloc/profile_state.dart';
import '../data/models/workout_models.dart';
import 'bloc/workout_bloc.dart';
import 'bloc/workout_event.dart';
import '../../../../core/theme/app_colors.dart';
import 'bloc/workout_state.dart';
import 'active_workout_view.dart';

// ── State Machine ─────────────────────────────────────────────
enum WorkoutHubState { unconfigured, loading, ready, activeWorkout }

typedef _C = AppColors;

// ═══════════════════════════════════════════════════════════════
// WorkoutScreen
// ═══════════════════════════════════════════════════════════════

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────
  WorkoutHubState _state = WorkoutHubState.unconfigured;
  int _activeDays = 4;
  RoutineSuggestion? _activeRoutine;
  CurrentSession? _currentSession;
  String? _errorMessage;
  String? _swapSuggestionNote;
  bool _overtrainingRisk = false;
  String? _overtrainingNote;
  int? _expandedExerciseIndex;
  List<WeekDayDetail> _weekScheduleDetails = [];

  bool _showAllExercises = false;

  // ── Streak & Real-Time Weekly Completion ──────────────────────
  int _streakDays = 0;
  List<bool> _completedDaysThisWeek = List.filled(7, false);
  bool _isRefreshingInPlace = false;

  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = ApiClient().dio;
    _loadRoutine(silent: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Load existing routine from backend ─────────────────────
  Future<void> _loadRoutine({bool silent = false}) async {
    if (!mounted) return;
    setState(() => _isRefreshingInPlace = true);
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final resp = await _dio.get('/workouts/routine?date=$todayStr');
      if (!mounted) return;
      final data = resp.data['data']['routine'];
      final sessionData = resp.data['data']['currentSession'];
      final swapNote = resp.data['data']?['swapSuggestionNote'] as String?;
      if (data != null) {
        // Backend returned a saved routine
        final splitType = data['splitType'] as String;
        final splitName = data['splitName'] as String? ?? data['splitType'] as String;
        final days      = data['daysPerWeek'] as int? ?? 4;
        final suggestions = RoutineCatalogue.forDays(days);
        final found = suggestions.where((s) => s.splitType == splitType).toList();
        final streak = resp.data['data']['streakDays'] as int? ?? 0;
        final completedList = (resp.data['data']['completedDaysThisWeek'] as List<dynamic>?)
                ?.map((e) => e == true)
                .toList() ??
            List.filled(7, false);

        final rawWeekDetails = data['weekScheduleDetails'] as List<dynamic>?;
        final weekDetails = rawWeekDetails != null
            ? rawWeekDetails.map((e) => WeekDayDetail.fromJson(e as Map<String, dynamic>)).toList()
            : <WeekDayDetail>[];

        final overtrainRisk = data['overtrainingRisk'] as bool? ?? false;
        final overtrainNote = data['overtrainingNote'] as String?;

        if (!mounted) return;
        setState(() {
          _streakDays = streak;
          _completedDaysThisWeek = completedList;
          _weekScheduleDetails = weekDetails;
          _swapSuggestionNote = swapNote;
          _overtrainingRisk = overtrainRisk;
          _overtrainingNote = overtrainNote;
          _activeDays   = days;
          _activeRoutine = found.isNotEmpty
              ? found.first
              : RoutineSuggestion(
                  name: splitName,
                  splitType: splitType,
                  tagline: data['description'] as String? ?? '',
                  breakdown: (data['weekSchedule'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [],
                );
          _currentSession = sessionData != null
              ? CurrentSession.fromJson(sessionData as Map<String, dynamic>)
              : null;
          _state = WorkoutHubState.ready;
          _isRefreshingInPlace = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isRefreshingInPlace = false;
          _state = WorkoutHubState.unconfigured;
          _activeRoutine = null;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshingInPlace = false;
        _state = WorkoutHubState.unconfigured;
        _activeRoutine = null;
        if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
          _errorMessage = 'Could not load routine. Please try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRefreshingInPlace = false;
        _state = WorkoutHubState.unconfigured;
        _activeRoutine = null;
      });
    }
  }



  // ── Launch Active Workout ──────────────────────────────────
  void _startWorkout() {
    final profileState = context.read<ProfileBloc>().state;
    final isPremium = profileState is ProfileLoaded && profileState.isPremium;

    if (!isPremium) {
      PurchaseService.instance.presentPaywall(context);
      return;
    }

    final workoutState = context.read<WorkoutBloc>().state;
    if (workoutState is! WorkoutSessionActive) {
      context.read<WorkoutBloc>().add(StartWorkoutSession(
        _currentSession != null ? _currentSession!.routineName : 'Custom Session',
        initialExercises: _currentSession?.exercises,
      ));
    }

    setState(() {
      _state = WorkoutHubState.activeWorkout;
    });
  }

  void _finishWorkout() {
    context.read<WorkoutBloc>().add(const FinishWorkoutSession());

    setState(() {
      _state = WorkoutHubState.ready;
    });
  }

  void _showPostWorkoutSummarySheet(String summaryNote) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.cyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: _C.amber, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Workout Complete! 🎉',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _C.textPri,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _C.textMut),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.cyan.withValues(alpha: 0.25), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.cyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_rounded, color: _C.cyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COACH SUMMARY',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _C.cyan,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summaryNote,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: _C.textPri,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return MultiBlocListener(
      listeners: [
        BlocListener<WorkoutBloc, WorkoutState>(
          listener: (context, workoutState) {
            if (workoutState is WorkoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(workoutState.message, style: const TextStyle(color: Colors.white)),
                  backgroundColor: _C.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (workoutState is WorkoutSessionFinished) {
              _loadRoutine();
              _showPostWorkoutSummarySheet(workoutState.message);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.auraTheme.background,
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildCurrentView(isArabic),
          ),
        ),
      ),
    );
  }

  void _exitWorkoutWithoutFinishing() {
    setState(() {
      _state = WorkoutHubState.ready;
    });
  }

  Widget _buildCurrentView(bool isArabic) {
    switch (_state) {
      case WorkoutHubState.loading:
        return _buildLoadingView(isArabic);
      case WorkoutHubState.activeWorkout:
        return BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, workoutState) {
            if (workoutState is WorkoutSessionActive) {
              return ActiveWorkoutView(
                key: const ValueKey('activeWorkout'),
                sessionState: workoutState,
                isArabic: isArabic,
                onFinish: _finishWorkout,
                onExit: _exitWorkoutWithoutFinishing,
              );
            }
            return _buildLoadingView(isArabic);
          },
        );
      case WorkoutHubState.unconfigured:
      case WorkoutHubState.ready:
        return _buildHubView(isArabic);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // LOADING VIEW
  // ══════════════════════════════════════════════════════════════

  Widget _buildLoadingView(bool isArabic) {
    return const Align(
      alignment: Alignment.topCenter,
      child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_C.cyan),
        minHeight: 3,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  void _showRoutineDetailsModal(bool isArabic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E4D7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _activeRoutine?.name ?? 'Upper / Lower Split',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A2B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: ${_currentSession?.todayDayName ?? "Training Day"}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF235A42)),
            ),
            const SizedBox(height: 16),
            if (_activeRoutine != null)
              ..._activeRoutine!.breakdown.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF235A42)),
                        const SizedBox(width: 8),
                        Text(item, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1C2B1E))),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HUB VIEW  (unconfigured + ready)
  // ══════════════════════════════════════════════════════════════

  Widget _buildHubView(bool isArabic) {
    final exercises = _currentSession?.exercises ?? [];

    return Container(
      color: const Color(0xFFF6F8F5),
      child: ListView(
        key: const ValueKey('hub'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: [
          const SizedBox(height: 4),

          // 1. Top Header
          _WorkoutHeader(
            onActionTap: _startWorkout,
          ),
          const SizedBox(height: 16),

          // ── UNCONFIGURED: AI-chat onboarding ──────────
          if (_state == WorkoutHubState.unconfigured)
            CoachChatCard(
              coachNote: null,
              isArabic: isArabic,
              dio: _dio,
              isFirstTime: true,
              onSessionUpdated: (updatedSession) {
                setState(() {
                  _currentSession = updatedSession;
                });
              },
              onRoutineUpdated: () => _loadRoutine(silent: false),
            ),

          // ── READY: Timeline Hub content ──────────────
          if (_state == WorkoutHubState.ready) ...[
            // 2. Active Routine Banner
            _WorkoutActiveSummaryBanner(
              routineName: _activeRoutine?.name ?? 'Upper / Lower Split',
              focusArea: _currentSession?.todayDayName ?? 'Lower (Volume)',
              exerciseCount: exercises.isNotEmpty ? exercises.length : 4,
              onTap: () => _showRoutineDetailsModal(isArabic),
            ),
            const SizedBox(height: 22),

            // 3. Exercise Timeline Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EXERCISE TIMELINE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A6E5D),
                    letterSpacing: 0.6,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showRoutineDetailsModal(isArabic),
                  child: Row(
                    children: [
                      Text(
                        'See routine',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A2B),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF1E3A2B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Exercise Timeline Items
            if (exercises.isNotEmpty)
              ...List.generate(exercises.length, (idx) {
                final ex = exercises[idx];
                final prText = (ex.lastWeekWeight != null && ex.lastWeekWeight! > 0)
                    ? 'Last: ${ex.lastWeekWeight!.toStringAsFixed(0)} kg x ${ex.lastWeekReps ?? 10}'
                    : null;
                final setsRepsStr = '${ex.targetSets} Sets · ${ex.muscleGroup.isNotEmpty ? ex.muscleGroup : "Target"}';
                return _ExerciseTimelineTile(
                  key: ValueKey('${ex.name}_$idx'),
                  index: idx,
                  title: ex.name,
                  targetSetsReps: setsRepsStr,
                  prBadgeText: prText,
                  restTime: null,
                  isLast: idx == exercises.length - 1,
                  onTap: () => _showAIExerciseGuideModal(context, ex.name, setsRepsStr, isArabic),
                );
              })
            else ...[
              _ExerciseTimelineTile(
                index: 0,
                title: 'Barbell Bench Press',
                targetSetsReps: '3 Sets · Chest · Triceps',
                prBadgeText: 'Last: 80 kg x 8',
                restTime: '2:00',
                isLast: false,
                onTap: () => _showAIExerciseGuideModal(context, 'Barbell Bench Press', '3 Sets · Chest · Triceps', isArabic),
              ),
              _ExerciseTimelineTile(
                index: 1,
                title: 'Incline Dumbbell Press',
                targetSetsReps: '3 Sets · Upper Chest',
                prBadgeText: 'Last: 28 kg x 10',
                restTime: '2:00',
                isLast: false,
                onTap: () => _showAIExerciseGuideModal(context, 'Incline Dumbbell Press', '3 Sets · Upper Chest', isArabic),
              ),
              _ExerciseTimelineTile(
                index: 2,
                title: 'Overhead Press',
                targetSetsReps: '3 Sets · Front Delts',
                prBadgeText: 'Last: 50 kg x 8',
                restTime: '2:00',
                isLast: false,
                onTap: () => _showAIExerciseGuideModal(context, 'Overhead Press', '3 Sets · Front Delts', isArabic),
              ),
              _ExerciseTimelineTile(
                index: 3,
                title: 'Cable Lateral Raises',
                targetSetsReps: '3 Sets · Side Delts',
                prBadgeText: 'Last: 12 kg x 12',
                restTime: '1:30',
                isLast: false,
                onTap: () => _showAIExerciseGuideModal(context, 'Cable Lateral Raises', '3 Sets · Side Delts', isArabic),
              ),
              _ExerciseTimelineTile(
                index: 4,
                title: 'Cable Chest Flyes',
                targetSetsReps: '3 Sets · Chest',
                prBadgeText: 'Last: 20 kg x 12',
                restTime: '1:30',
                isLast: true,
                onTap: () => _showAIExerciseGuideModal(context, 'Cable Chest Flyes', '3 Sets · Chest', isArabic),
              ),
            ],

            const SizedBox(height: 4),

            // 5. Quick Action Card
            _WorkoutQuickActionCard(
              onTap: _startWorkout,
            ),
            const SizedBox(height: 20),

            // 6. AI Coach Assistant Card
            CoachChatCard(
              coachNote: _currentSession?.coachNote,
              isArabic: isArabic,
              dio: _dio,
              onSessionUpdated: (updatedSession) {
                setState(() {
                  _currentSession = updatedSession;
                });
              },
              onRoutineUpdated: () => _loadRoutine(silent: true),
            ),
            const SizedBox(height: 20),

            // 7. Weekly Progress Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'تقدمك' : 'Your Progress',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C2B1E),
                        ),
                      ),
                      Text(
                        isArabic ? '$_activeDays أيام/أسبوع' : '$_activeDays days/wk',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7C6E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  WeeklyCalendarRow(
                    weekScheduleDetails: _weekScheduleDetails,
                    completedDaysThisWeek: _completedDaysThisWeek,
                    isArabic: isArabic,
                    onDayTap: (detail) => _showDayDetailSheet(detail, isArabic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    if (_streakDays <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _C.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.amber.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '$_streakDays-Day Streak',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _C.amber),
          ),
        ],
      ),
    );
  }





  Widget _buildLocalAiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _C.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cyan.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.memory_rounded, color: _C.cyan, size: 11),
          const SizedBox(width: 4),
          Text(
            'Local AI · offline',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _C.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _overrideSession(String dayType) async {
    Navigator.of(context).pop();
    setState(() => _state = WorkoutHubState.loading);
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await _dio.post('/workouts/session/override', data: {
        'date': todayStr,
        'dayType': dayType,
      });
      await _loadRoutine();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dayType == 'skip'
                ? 'Today marked as skipped'
                : 'Session updated to $dayType'),
            backgroundColor: _C.cyan,
          ),
        );
      }
    } catch (e) {
      setState(() => _state = WorkoutHubState.ready);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSwapSessionSheet(bool isArabic) {
    final rawBreakdown = _activeRoutine?.breakdown ?? [];
    final uniqueTypes = <String>[];
    for (final t in rawBreakdown) {
      if (!uniqueTypes.contains(t)) {
        uniqueTypes.add(t);
      }
    }

    final currentType = _currentSession?.isSkipped == true
        ? 'skip'
        : (_currentSession?.todayDayName ?? 'Rest');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'تغيير تمرين اليوم' : "Swap Today's Session",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _C.textPri,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _C.textMut),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'اختر نوع التمرين لليوم بدون تغيير الجدول الأساسي'
                    : 'Override today\'s target session without modifying your overall routine split.',
                style: GoogleFonts.inter(fontSize: 12, color: _C.textMut),
              ),
              const SizedBox(height: 20),

              if (_swapSuggestionNote != null && _swapSuggestionNote!.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.cyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.cyan.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_rounded, color: _C.cyan, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _swapSuggestionNote!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _C.textPri,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ...uniqueTypes.map((type) {
                final isSelected = type == currentType;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _overrideSession(type),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _C.cyan.withValues(alpha: 0.12) : _C.cardElev,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _C.cyan : _C.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                type == 'Rest' ? Icons.nightlight_round : Icons.fitness_center_rounded,
                                color: isSelected ? _C.cyan : _C.textMut,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? _C.cyan : _C.textPri,
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: _C.cyan, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              Divider(color: _C.border, height: 1),
              const SizedBox(height: 12),

              InkWell(
                onTap: () => _overrideSession('skip'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: currentType == 'skip' ? _C.amber.withValues(alpha: 0.12) : _C.cardElev,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: currentType == 'skip' ? _C.amber : _C.border,
                      width: currentType == 'skip' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.do_not_disturb_on_rounded, color: currentType == 'skip' ? _C.amber : _C.amber.withValues(alpha: 0.8), size: 18),
                          const SizedBox(width: 12),
                          Text(
                            isArabic ? 'تخطي تمرين اليوم (راحة إضافية)' : 'Skip Today (Intentionally Rest)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: currentType == 'skip' ? FontWeight.w800 : FontWeight.w600,
                              color: currentType == 'skip' ? _C.amber : _C.textPri,
                            ),
                          ),
                        ],
                      ),
                      if (currentType == 'skip')
                        const Icon(Icons.check_circle_rounded, color: _C.amber, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDayDetailSheet(WeekDayDetail detail, bool isArabic) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (detail.isCompleted) {
      statusText = isArabic ? 'مكتمل' : 'Completed';
      statusColor = _C.cyan;
      statusIcon = Icons.check_circle_rounded;
    } else if (detail.isSkipped) {
      statusText = isArabic ? 'متخطى' : 'Skipped';
      statusColor = _C.amber;
      statusIcon = Icons.do_not_disturb_on_rounded;
    } else if (detail.isRest) {
      statusText = isArabic ? 'يوم راحة' : 'Rest Day';
      statusColor = _C.textMut;
      statusIcon = Icons.nightlight_round;
    } else if (detail.isMissed) {
      statusText = isArabic ? 'فائت' : 'Missed';
      statusColor = Colors.redAccent;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = isArabic ? 'مجدول' : 'Scheduled';
      statusColor = _C.textSec;
      statusIcon = Icons.schedule_rounded;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detail.dayName} · ${detail.dateStr}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _C.textPri,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail.dayType == 'skip' ? 'Skipped' : detail.dayType,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.cyan,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayCard(bool isArabic) {
    final routine = _activeRoutine!;
    final session = _currentSession;
    final workoutBlocState = context.watch<WorkoutBloc>().state;
    final hasActiveSession = workoutBlocState is WorkoutSessionActive;

    final todayLabel = session?.todayDayName
        ?? (() {
          final idx = DateTime.now().weekday - 1;
          final sched = routine.breakdown;
          return sched.isNotEmpty ? sched[idx % sched.length] : 'Training Day';
        })();

    final exercises = session?.exercises ?? [];
    final isRestDay = session?.isRestDay ?? exercises.isEmpty;
    final isSkipped = session?.isSkipped ?? false;
    final visibleCount = _showAllExercises ? exercises.length : (exercises.length > 2 ? 2 : exercises.length);
    final remainingCount = exercises.length - 2;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey('${routine.splitType}_${todayLabel}_${exercises.length}_${isSkipped}_$hasActiveSession'),
        child: Stack(
          children: [
            Column(
              children: [
                if (hasActiveSession)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _C.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.cyan.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _C.cyan.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fitness_center_rounded, color: _C.cyan, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'تمرين قيد التقدّم 🏋️‍♂️' : 'ACTIVE WORKOUT IN PROGRESS 🏋️‍♂️',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: _C.cyan, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isArabic
                                      ? 'لديك تمرين نشط! اضغط على "إنهاء التمرين" لتسجيل نتائجك.'
                                      : 'You have an active workout in progress! Please finish your workout to log your progress.',
                                  style: GoogleFonts.inter(fontSize: 12, color: _C.textPri, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isSkipped)
                  Container(
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _C.amber.withValues(alpha: 0.4), width: 1.2),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _C.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _C.amber.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Text(
                                isArabic ? 'تمرين متخطى' : 'SESSION SKIPPED',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _C.amber),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showSwapSessionSheet(isArabic),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: _C.cyan),
                              label: Text(
                                isArabic ? 'تغيير' : 'Swap Session',
                                style: GoogleFonts.inter(fontSize: 12, color: _C.cyan, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.do_not_disturb_on_rounded, color: _C.amber, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? 'تمت إضافة هذا اليوم كراحة إضافية. سيتواصل جدول تمرينك كالمعتاد غداً.'
                                    : 'You marked today as skipped for extra recovery. Regular split resumes tomorrow.',
                                style: GoogleFonts.inter(fontSize: 13, color: _C.textSec, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: context.auraTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000), // 0 4px 14px rgba(0,0,0,0.2)
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: context.auraTheme.border, width: 1.2),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + Swap Button Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (session?.isTodayCompleted == true && !hasActiveSession)
                                    ? _C.success.withValues(alpha: 0.15)
                                    : _C.cyan.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (session?.isTodayCompleted == true && !hasActiveSession)
                                      ? _C.success.withValues(alpha: 0.4)
                                      : _C.cyan.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (session?.isTodayCompleted == true && !hasActiveSession)
                                    ? (isArabic ? 'تمرين اليوم مكتمل 🎉' : 'TODAY COMPLETED 🎉')
                                    : (isArabic ? 'جلسة اليوم' : "TODAY'S SESSION"),
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w800,
                                    color: (session?.isTodayCompleted == true && !hasActiveSession) ? _C.success : _C.cyan,
                                    letterSpacing: 0.8),
                              ),
                            ),
                            _AnimatedPressable(
                              onTap: () => _showSwapSessionSheet(isArabic),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _C.cyan.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _C.cyan.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_horiz_rounded, size: 14, color: _C.cyan),
                                    const SizedBox(width: 4),
                                    Text(
                                      isArabic ? 'تغيير' : 'Swap Session',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _C.cyan),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                      // Routine name + today label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded, color: context.auraTheme.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                routine.name,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: context.auraTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (session?.isTodayCompleted == true && !hasActiveSession)
                                ? '$todayLabel (${isArabic ? "التمرين القادم" : "Next Session"})'
                                : todayLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.auraTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: context.auraTheme.border, height: 1),
                      const SizedBox(height: 14),

                      // ── Exercise List ──────────────────────────────
                      if (isRestDay)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.hotel_rounded, color: _C.textMut, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'يوم راحة — استرح واستعد' : 'Rest Day — Recover & recharge',
                              style: GoogleFonts.inter(fontSize: 13, color: _C.textMut),
                            ),
                          ]),
                        )
                      else
                        ...[
                          ...List.generate(visibleCount, (i) {
                            return WorkoutExerciseRow(
                              key: ValueKey(exercises[i].id ?? exercises[i].name),
                              exercise: exercises[i],
                              index: i,
                              isFirst: i == 0,
                              dio: _dio,
                              isArabic: isArabic,
                              onSessionUpdated: (updatedSession) {
                                setState(() {
                                  _currentSession = updatedSession;
                                });
                              },
                            );
                          }),
                          if (exercises.length > 2) ...[
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showAllExercises = !_showAllExercises;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showAllExercises
                                          ? (isArabic ? 'إخفاء التمارين' : 'Show less')
                                          : (isArabic ? '+ $remainingCount تمارين إضافية' : '+ $remainingCount more exercises'),
                                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.cyan),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showAllExercises ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: _C.cyan,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 16),
                        Divider(color: _C.border, height: 1),
                        const SizedBox(height: 14),

                        // Start / Finish Workout CTA
                        _AnimatedPressable(
                          onTap: isRestDay ? null : _startWorkout,
                          child: AppButton.primary(
                            onPressed: isRestDay ? null : _startWorkout,
                            icon: isRestDay
                                ? Icons.hotel_rounded
                                : (hasActiveSession ? Icons.check_circle_rounded : Icons.play_arrow_rounded),
                            label: isRestDay
                                ? (isArabic ? 'يوم راحة' : 'Rest Day')
                                : (hasActiveSession
                                    ? (isArabic ? 'إنهاء / متابعة التمرين' : 'Finish Workout')
                                    : (isArabic ? 'ابدأ التمرين الآن' : 'Start Workout')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isRefreshingInPlace)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: const LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(_C.cyan),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

  Widget _buildPerformanceBadge(bool isArabic) {
    final theme = context.auraTheme;
    // Contextually reads from the FIRST exercise in today's session
    final top = _currentSession?.topHistoricalSet;
    final label = top?.displayLabel ?? '— No data yet';
    final delta = top?.progressionDelta ?? '';
    final hasData = top != null && top.weight > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.bolt_rounded, color: theme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isArabic ? 'أفضل أداء الأسبوع الماضي' : 'Last week top performance',
                style: GoogleFonts.inter(fontSize: 11, color: theme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: theme.textPrimary),
              ),
            ]),
          ),
          if (hasData && delta.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '↑ $delta',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _C.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(bool isArabic) {
    final theme = context.auraTheme;
    const weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final detail = i < _weekScheduleDetails.length ? _weekScheduleDetails[i] : null;
        final label = weekDayLabels[i];

        final isCompleted = detail?.isCompleted ?? (i < _completedDaysThisWeek.length ? _completedDaysThisWeek[i] : false);
        final isRest      = detail?.isRest ?? detail?.isSkipped ?? false;
        final isToday     = detail?.isToday ?? (i == todayIndex);

        return GestureDetector(
          onTap: () {
            if (detail != null) {
              _showDayDetailSheet(detail, isArabic);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? theme.primary : theme.textSecondary,
                )),
            const SizedBox(height: 6),
            _buildDayCircleWidget(
              isCompleted: isCompleted,
              isToday: isToday,
              isRest: isRest,
            ),
          ]),
        );
      }),
    );
  }



  Future<void> _showWeeklyRecapSheet(bool isArabic) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder(
            future: _dio.get('/workouts/weekly-recap'),
            builder: (context, AsyncSnapshot<Response> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_C.cyan)),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      isArabic ? 'فشل تحميل الملخص الأسبوعي' : 'Failed to load weekly recap',
                      style: GoogleFonts.inter(color: _C.textMut),
                    ),
                  ),
                );
              }

              final data = snapshot.data!.data['data'];
              final recapNote = data['recapNote'] as String? ?? '';
              final completed = data['completedDaysCount'] as int? ?? 0;
              final streak = data['streakDays'] as int? ?? 0;
              final prs = (data['prsAchieved'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _C.cyan.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: _C.cyan, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isArabic ? 'الملخص الأسبوعي بالذكاء الاصطناعي' : 'Weekly AI Recap',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _C.textPri,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: _C.textMut, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRecapStatBadge(
                        label: isArabic ? 'مكتمل' : 'Completed',
                        value: '$completed days',
                        color: _C.cyan,
                      ),
                      const SizedBox(width: 10),
                      _buildRecapStatBadge(
                        label: isArabic ? 'سلسلة' : 'Streak',
                        value: '$streak days',
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 10),
                      _buildRecapStatBadge(
                        label: isArabic ? 'أرقام قياسية' : 'PRs',
                        value: '${prs.length}',
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _C.cardElev,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border, width: 1),
                    ),
                    child: Text(
                      recapNote,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _C.textPri,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.cyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isArabic ? 'حسناً' : 'Got it',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecapStatBadge({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _C.textMut),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ACTIVE WORKOUT VIEW
  // ══════════════════════════════════════════════════════════════
}
// ══════════════════════════════════════════════════════════════
// EXTRACTED COMPONENT 1: CoachInputCard (Isolated text field state)
// ══════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════
// EXTRACTED COMPONENT 1: CoachChatCard (Isolated chat conversation state)
// ══════════════════════════════════════════════════════════════

class CoachChatMessage {
  final String text;
  final bool isUser;
  final bool isTyping;

  const CoachChatMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });
}

class CoachChatCard extends StatefulWidget {
  final String? coachNote;
  final bool isArabic;
  final Dio dio;
  final bool isFirstTime;
  final ValueChanged<CurrentSession> onSessionUpdated;
  final VoidCallback onRoutineUpdated; // called after a change_plan or setup_routine is confirmed

  const CoachChatCard({
    super.key,
    required this.coachNote,
    required this.isArabic,
    required this.dio,
    required this.onSessionUpdated,
    required this.onRoutineUpdated,
    this.isFirstTime = false,
  });

  @override
  State<CoachChatCard> createState() => _CoachChatCardState();
}

class _CoachChatCardState extends State<CoachChatCard> {
  final List<CoachChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInterpreting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFirstTime) {
      // Pre-seed the coach greeting for brand-new users
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _messages.add(CoachChatMessage(
              text: widget.isArabic
                  ? 'مرحباً! أنا مدربك الشخصي. لنبدأ بإعداد خطة تدريبية مخصصة لك. كم يوماً في الأسبوع تريد التدريب؟'
                  : "Hi! I'm your AI Coach 💪 Let's set up your personalized workout plan. How many days a week do you want to train — 3, 4, 5, or 6?",
              isUser: false,
            ));
          });
          _scrollToBottom();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submit() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty || _isInterpreting) return;

    _controller.clear();

    setState(() {
      _messages.add(CoachChatMessage(text: msg, isUser: true));
      _messages.add(CoachChatMessage(text: '', isUser: false, isTyping: true));
      _isInterpreting = true;
    });
    _scrollToBottom();

    try {
      final resp = await widget.dio.post('/workouts/session/interpret', data: {'message': msg});
      final data = resp.data['data'];
      final intent = data?['intent'] as String? ?? 'unrecognized';
      final actionExecuted = data?['actionExecuted'] as bool? ?? false;
      final confirmationMsg = data?['confirmationMessage'] as String? ?? 'Session updated.';
      final updatedSessionJson = data?['currentSession'];

      if (updatedSessionJson != null) {
        final session = CurrentSession.fromJson(updatedSessionJson as Map<String, dynamic>);
        widget.onSessionUpdated(session);
      }

      if ((intent == 'change_plan' || intent == 'setup_routine') && actionExecuted) {
        widget.onRoutineUpdated();
      }

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isTyping);
          _messages.add(CoachChatMessage(text: confirmationMsg, isUser: false));
          _isInterpreting = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isTyping);
          _messages.add(CoachChatMessage(
            text: widget.isArabic
                ? 'فشل في معالجة الطلب. يرجى المحاولة مرة أخرى.'
                : 'Failed to process command. Please try again.',
            isUser: false,
          ));
          _isInterpreting = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachNote = widget.coachNote;
    final hasNote = coachNote != null && coachNote.trim().isNotEmpty;
    final isArabic = widget.isArabic;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon Badge + "Your Coach" Label & Note ─────────────
          if (hasNote) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCEEE3),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF235A42), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'مدربك الشخصي' : 'Your Coach',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF235A42),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        coachNote,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1C2B1E),
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── Chat Bubbles (if active conversation) ──────────────
          if (_messages.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildBubble(message, isArabic);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Pill-Shaped Input Bar ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD3E4D7), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6B7C6E), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isInterpreting,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1C2B1E)),
                    decoration: InputDecoration(
                      hintText: isArabic
                          ? 'اسأل مدربك أي شيء...'
                          : 'Ask your coach anything',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7C6E)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 6),
                _AnimatedPressable(
                  onTap: _isInterpreting ? null : _submit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF235A42),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _isInterpreting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(CoachChatMessage message, bool isArabic) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF235A42),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(2),
            ),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // Normal coach bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EE),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(2),
          ),
          border: Border.all(color: const Color(0xFFD3E4D7), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF235A42), size: 13),
            const SizedBox(width: 6),
            Flexible(
              child: message.isTyping
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? 'المدرب يفكر...' : 'Coach is thinking...',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF6B7C6E),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF235A42)),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message.text,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E3A2B), height: 1.35),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EXTRACTED COMPONENT 2: WorkoutExerciseRow (Isolated accordion state)
// ══════════════════════════════════════════════════════════════

class WorkoutExerciseRow extends StatefulWidget {
  final SessionExercise exercise;
  final int index;
  final bool isFirst;
  final Dio dio;
  final bool isArabic;
  final ValueChanged<CurrentSession> onSessionUpdated;

  const WorkoutExerciseRow({
    super.key,
    required this.exercise,
    required this.index,
    required this.isFirst,
    required this.dio,
    required this.isArabic,
    required this.onSessionUpdated,
  });

  @override
  State<WorkoutExerciseRow> createState() => _WorkoutExerciseRowState();
}

class _WorkoutExerciseRowState extends State<WorkoutExerciseRow> {
  bool _isExpanded = false;
  bool _showAlternatives = false;
  bool _isLoadingAlternatives = false;
  bool _isSwapping = false;
  List<dynamic>? _alternatives;

  Future<void> _toggleAlternatives() async {
    if (_showAlternatives) {
      setState(() {
        _showAlternatives = false;
      });
      return;
    }

    setState(() {
      _showAlternatives = true;
    });

    if (_alternatives == null) {
      final exId = widget.exercise.id;
      if (exId == null || exId.isEmpty) {
        setState(() {
          _alternatives = [];
        });
        return;
      }

      setState(() {
        _isLoadingAlternatives = true;
      });

      try {
        final resp = await widget.dio.get('/workouts/exercises/$exId/alternatives');
        final data = resp.data['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _alternatives = data;
            _isLoadingAlternatives = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _alternatives = [];
            _isLoadingAlternatives = false;
          });
        }
      }
    }
  }

  Future<void> _performSwap(String altName) async {
    if (_isSwapping) return;
    setState(() {
      _isSwapping = true;
    });

    try {
      final resp = await widget.dio.post(
        '/workouts/session/interpret',
        data: {'message': 'swap ${widget.exercise.name} for $altName'},
      );
      final data = resp.data['data'];
      final updatedSessionJson = data?['currentSession'];

      if (updatedSessionJson != null) {
        final session = CurrentSession.fromJson(updatedSessionJson as Map<String, dynamic>);
        widget.onSessionUpdated(session);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isArabic ? 'فشل تبديل التمرين' : 'Failed to swap exercise'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwapping = false;
          _showAlternatives = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final ex = widget.exercise;
    final i = widget.index;
    final isFirst = widget.isFirst;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedPressable(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Index badge
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? theme.primary.withValues(alpha: 0.15)
                        : theme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFirst ? theme.primary : theme.border,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: isFirst ? theme.primary : theme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Exercise name + muscle group
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ex.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isFirst ? FontWeight.w700 : FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ex.isPlateaued) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _C.amber.withValues(alpha: 0.4), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.show_chart_rounded, color: _C.amber, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Plateau',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: _C.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        ex.muscleGroup,
                        style: GoogleFonts.inter(fontSize: 10, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Sets badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.border),
                  ),
                  child: Text(
                    '${ex.targetSets} sets',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w600, color: theme.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),

                // Alternatives Swap Icon Badge Button (34x34px, 10px corner radius, bg-accent background, text-accent icon, 0 0 8px accent glow)
                _AnimatedPressable(
                  onTap: _toggleAlternatives,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _C.cyan.withValues(alpha: _showAlternatives ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4000BCD4), // 0 0 8px rgba(0,188,212,0.25)
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: _C.cyan,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Chevron accordion indicator
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _C.textMut,
                  size: 20,
                ),
              ],
            ),
          ),

          // Accordion Expanded Alternatives Body
          if (_showAlternatives) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.cardElev,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: _C.cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        widget.isArabic ? 'التمارين البديلة' : 'ALTERNATIVES',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _C.cyan,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_isSwapping) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(_C.cyan),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingAlternatives)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_C.cyan),
                          ),
                        ),
                      ),
                    )
                  else if (_alternatives == null || _alternatives!.isEmpty)
                    Text(
                      widget.isArabic
                          ? 'لا توجد بدائل مدرجة لهذا التمرين بعد'
                          : 'No alternatives listed for this one yet',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: _C.textMut,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _alternatives!.map<Widget>((dynamic alt) {
                        final altName = (alt is Map ? alt['name'] : alt.toString()) as String? ?? 'Alternative';
                        return InkWell(
                          onTap: _isSwapping ? null : () => _performSwap(altName),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _C.cyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              altName,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _C.textPri,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],

          // Accordion Expanded Coach Note Body
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.cardElev,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.borderMid),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: _C.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ex.coachNote ??
                          (ex.lastWeekWeight != null
                              ? 'Target matching ${ex.lastWeekWeight}kg × ${ex.lastWeekReps} reps.'
                              : 'First time on this exercise — start conservative and focus on form.'),
                      style: GoogleFonts.inter(fontSize: 12, color: _C.textSec, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reusable Press Motion Scale Feedback Widget ──────────────

class _AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedPressable({
    required this.child,
    this.onTap,
  });

  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<_AnimatedPressable> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ── Dashed Circle Painter for Rest Days ──────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({required this.color, this.strokeWidth = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const dashCount = 12;
    const dashArc = (2 * 3.141592653589793) / dashCount;
    const drawArc = dashArc * 0.55;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashArc;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        drawArc,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

// ── Weekly Calendar Day Circle Builder ────────────────────────

Widget _buildDayCircleWidget({
  required bool isCompleted,
  required bool isToday,
  required bool isRest,
}) {
  if (isCompleted) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: _C.success,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x804CAF50), blurRadius: 10), // 0 0 10px rgba(76,175,80,0.5)
        ],
      ),
      child: const Center(
        child: Icon(Icons.check_rounded, color: Colors.white, size: 13),
      ),
    );
  } else if (isToday) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEE3),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF235A42), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x20235A42), blurRadius: 10),
        ],
      ),
    );
  } else if (isRest) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _DashedCirclePainter(color: const Color(0xFFD3E4D7), strokeWidth: 1.0),
    );
  } else {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD3E4D7), width: 1.0),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EXTRACTED COMPONENT 3: WeeklyCalendarRow (Isolated status dots)
// ══════════════════════════════════════════════════════════════

class WeeklyCalendarRow extends StatelessWidget {
  final List<WeekDayDetail> weekScheduleDetails;
  final List<bool> completedDaysThisWeek;
  final bool isArabic;
  final void Function(WeekDayDetail detail) onDayTap;

  const WeeklyCalendarRow({
    super.key,
    required this.weekScheduleDetails,
    required this.completedDaysThisWeek,
    required this.isArabic,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    const weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final detail = i < weekScheduleDetails.length ? weekScheduleDetails[i] : null;
        final label = weekDayLabels[i];

        final isCompleted = detail?.isCompleted ?? (i < completedDaysThisWeek.length ? completedDaysThisWeek[i] : false);
        final isRest      = detail?.isRest ?? detail?.isSkipped ?? false;
        final isToday     = detail?.isToday ?? (i == todayIndex);

        return GestureDetector(
          onTap: () {
            if (detail != null) {
              onDayTap(detail);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? const Color(0xFF235A42) : const Color(0xFF7A8B7B),
                )),
            const SizedBox(height: 6),
            _buildDayCircleWidget(
              isCompleted: isCompleted,
              isToday: isToday,
              isRest: isRest,
            ),
          ]),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// REDESIGNED WORKOUT TIMELINE WIDGETS
// ══════════════════════════════════════════════════════════════

class _WorkoutHeader extends StatelessWidget {
  final VoidCallback onActionTap;
  const _WorkoutHeader({required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7A8B7B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Workout Hub',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2B1E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF235A42),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x20235A42),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutActiveSummaryBanner extends StatelessWidget {
  final String routineName;
  final String focusArea;
  final int exerciseCount;
  final VoidCallback onTap;

  const _WorkoutActiveSummaryBanner({
    required this.routineName,
    required this.focusArea,
    required this.exerciseCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEE3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 18,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE SUMMARY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4A6B56),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF235A42), size: 22),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          routineName,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A2B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Today: $focusArea',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF235A42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$exerciseCount Exercises · 60 mins · Est. 450 kcal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B5745),
                    ),
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

void _showAIExerciseGuideModal(BuildContext context, String title, String targetSetsReps, bool isArabic) {
  final lower = title.toLowerCase();
  String muscleGroup = 'Chest & Triceps';
  String setupGuide = 'Lie flat on the bench, grip the bar slightly wider than shoulder-width, and retract your shoulder blades.';
  String executionGuide = 'Unrack the weight, lower it steadily to mid-chest while keeping elbows at a 45° angle, then explode upward.';
  String proTip = 'Maintain a solid arch with feet planted firmly. Focus on squeezing your chest at peak contraction.';

  if (lower.contains('incline')) {
    muscleGroup = 'Upper Chest & Front Delts';
    setupGuide = 'Set the bench angle to 30°, press your back firmly against the pad, and position dumbbells at upper chest level.';
    executionGuide = 'Drive dumbbells straight up toward the ceiling, keeping wrists neutral. Lower smoothly under full tension.';
    proTip = 'Do not set bench angle higher than 30° to prevent shifting load away from upper chest onto front shoulders.';
  } else if (lower.contains('overhead') || lower.contains('military')) {
    muscleGroup = 'Shoulders (Front & Side Delts)';
    setupGuide = 'Stand tall with core braced, hold dumbbells/barbell at collarbone height with elbows stacked under wrists.';
    executionGuide = 'Press vertically overhead until arms are fully extended. Lower with control back to shoulder level.';
    proTip = 'Brace glutes and abs tight to avoid arching lower back during heavy overhead pressing.';
  } else if (lower.contains('lateral') || lower.contains('delt')) {
    muscleGroup = 'Side Deltoids';
    setupGuide = 'Stand with slight forward lean, hold handles with neutral grip, lead slightly with your elbows.';
    executionGuide = 'Raise arms outward in a broad arc until parallel to floor. Pause briefly before lowering smoothly.';
    proTip = 'Avoid using momentum or shrugging shoulders. Treat it as a controlled lateral sweep.';
  } else if (lower.contains('fly') || lower.contains('crossover')) {
    muscleGroup = 'Inner Chest & Pectoralis Major';
    setupGuide = 'Set pulleys at chest height, step forward into a staggered stance, and keep a subtle bend in elbows.';
    executionGuide = 'Hug the handles together in front of your chest, squeezing hard at peak contraction.';
    proTip = 'Think about hugging a big tree trunk to maintain optimal elbow angle throughout the entire range.';
  } else if (lower.contains('squat') || lower.contains('leg press')) {
    muscleGroup = 'Quadriceps & Glutes';
    setupGuide = 'Position feet shoulder-width apart, keep chest lifted, and brace your core deeply.';
    executionGuide = 'Sit back and down between your hips until thighs are parallel. Press through full foot to drive up.';
    proTip = 'Ensure knees track in line with your toes throughout the entire movement.';
  } else if (lower.contains('deadlift') || lower.contains('rdl')) {
    muscleGroup = 'Hamstrings, Glutes & Lower Back';
    setupGuide = 'Stand hip-width apart, hinge at your hips while keeping spine flat and chest upright.';
    executionGuide = 'Lower bar down along your shins until feeling a stretch in hamstrings, then drive hips forward to stand.';
    proTip = 'Keep the bar close to your body at all times to protect lower back and maximize hamstring tension.';
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E4D7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF235A42),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C2B1E),
                      ),
                    ),
                    Text(
                      targetSetsReps,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF235A42),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD3E4D7), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.track_changes_rounded, color: Color(0xFF235A42), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic ? 'العضلة المستهدفة: $muscleGroup' : 'Primary Target: $muscleGroup',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C2B1E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? '💡 دليل الأداء الفني' : '💡 Execution & Technique Guide',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C2B1E),
            ),
          ),
          const SizedBox(height: 8),
          _buildGuideStep('1', isArabic ? 'الإعداد والوضعية' : 'Setup & Position', setupGuide),
          const SizedBox(height: 8),
          _buildGuideStep('2', isArabic ? 'طريقة الحركة' : 'Movement Drive', executionGuide),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EBE4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    proTip,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3B5745),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF235A42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                isArabic ? 'تم، شكراً كوتش!' : 'Got it, Coach!',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDCEEE3),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildGuideStep(String step, String title, String body) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF235A42),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            step,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1C2B1E)),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6E5D), height: 1.35),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ExerciseTimelineTile extends StatelessWidget {
  final int index;
  final String title;
  final String targetSetsReps;
  final String? prBadgeText;
  final String? restTime;
  final String? emoji;
  final bool isLast;
  final VoidCallback onTap;

  const _ExerciseTimelineTile({
    super.key,
    required this.index,
    required this.title,
    required this.targetSetsReps,
    this.prBadgeText,
    this.restTime,
    this.emoji,
    required this.isLast,
    required this.onTap,
  });

  Widget _buildExerciseThumbnail(String title) {
    final lower = title.toLowerCase();
    IconData icon = Icons.fitness_center_rounded;
    String badge = 'CHEST';

    if (lower.contains('incline')) {
      icon = Icons.unfold_more_rounded;
      badge = 'UPPER';
    } else if (lower.contains('bench') || lower.contains('barbell bench')) {
      icon = Icons.fitness_center_rounded;
      badge = 'CHEST';
    } else if (lower.contains('fly') || lower.contains('crossover')) {
      icon = Icons.compare_arrows_rounded;
      badge = 'FLYES';
    } else if (lower.contains('overhead') || lower.contains('military')) {
      icon = Icons.arrow_upward_rounded;
      badge = 'DELTS';
    } else if (lower.contains('lateral') || lower.contains('delt') || lower.contains('raise')) {
      icon = Icons.open_in_full_rounded;
      badge = 'SIDE';
    } else if (lower.contains('deadlift') || lower.contains('rdl')) {
      icon = Icons.download_rounded;
      badge = 'BACK';
    } else if (lower.contains('split squat') || lower.contains('lunge')) {
      icon = Icons.nordic_walking_rounded;
      badge = 'LEGS';
    } else if (lower.contains('squat') || lower.contains('leg press')) {
      icon = Icons.directions_walk_rounded;
      badge = 'QUADS';
    } else if (lower.contains('warmup') || lower.contains('stretch')) {
      icon = Icons.self_improvement_rounded;
      badge = 'WARM';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD3E4D7), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF235A42),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 17),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF235A42),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    left: 15,
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2EBE4),
                    ),
                  ),
                Positioned(
                  top: 20,
                  left: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: index == 0 ? const Color(0xFFDCEEE3) : const Color(0xFF235A42),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF235A42),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        index == 0 ? '✓' : '$index',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: index == 0 ? const Color(0xFF235A42) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildExerciseThumbnail(title),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1C2B1E),
                                      ),
                                    ),
                                  ),
                                  if (restTime != null) ...[
                                    const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF7A8B7B)),
                                    const SizedBox(width: 3),
                                    Text(
                                      restTime!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF7A8B7B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                targetSetsReps,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF6B7C6E),
                                ),
                              ),
                              if (prBadgeText != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF5EE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    prBadgeText!,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E3A2B),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFB0C0B4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutQuickActionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _WorkoutQuickActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD3E4D7),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF235A42),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Workout Session',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to begin live tracking & set logging',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6B7C6E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

