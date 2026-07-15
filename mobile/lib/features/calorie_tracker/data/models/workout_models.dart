// lib/features/calorie_tracker/data/models/workout_models.dart
// Aura — Workout Data Models
//
// RoutineCatalogue  → static set of recommended splits per frequency
// RoutineSuggestion → a selectable training split with breakdown
// WorkoutLog        → a live logging session (exercise + sets)
// ExerciseSet       → one logged set (weight, reps, locked state)

// ═══════════════════════════════════════════════════════════════
// RoutineSuggestion
// ═══════════════════════════════════════════════════════════════

class RoutineSuggestion {
  final String name;
  final String splitType;  // unique key, sent to backend
  final String tagline;
  final List<String> breakdown; // per-day labels (7 entries max)

  const RoutineSuggestion({
    required this.name,
    required this.splitType,
    required this.tagline,
    required this.breakdown,
  });

  Map<String, dynamic> toJson() => {
    'name':      name,
    'splitType': splitType,
    'tagline':   tagline,
    'breakdown': breakdown,
  };
}

// ═══════════════════════════════════════════════════════════════
// RoutineCatalogue — static catalogue keyed by daysPerWeek
// ═══════════════════════════════════════════════════════════════

class RoutineCatalogue {
  RoutineCatalogue._();

  static List<RoutineSuggestion> forDays(int days) {
    switch (days) {
      case 3:
        return _3day;
      case 4:
        return _4day;
      case 5:
        return _5day;
      case 6:
        return _6day;
      default:
        return _3day;
    }
  }

  static const List<RoutineSuggestion> _3day = [
    RoutineSuggestion(
      name: 'Full Body A/B/C',
      splitType: 'full_body',
      tagline: '3 full-body sessions — all major muscle groups hit each day.',
      breakdown: ['Full Body (Heavy)', 'Rest', 'Full Body (Moderate)', 'Rest', 'Full Body (Light)', 'Rest', 'Rest'],
    ),
    RoutineSuggestion(
      name: 'Classic PPL (1×)',
      splitType: 'ppl_1x',
      tagline: 'Push / Pull / Legs — each muscle group once per week.',
      breakdown: ['Push', 'Pull', 'Legs', 'Rest', 'Rest', 'Rest', 'Rest'],
    ),
  ];

  static const List<RoutineSuggestion> _4day = [
    RoutineSuggestion(
      name: 'Upper / Lower Split',
      splitType: 'upper_lower',
      tagline: 'Each muscle group trained twice per week — optimal frequency for hypertrophy.',
      breakdown: ['Upper (Heavy)', 'Lower (Heavy)', 'Rest', 'Upper (Volume)', 'Lower (Volume)', 'Rest', 'Rest'],
    ),
    RoutineSuggestion(
      name: 'Bro Split (4-day)',
      splitType: 'bro_split',
      tagline: 'One primary muscle group per day — maximum per-session volume.',
      breakdown: ['Chest', 'Back', 'Shoulders', 'Legs + Arms', 'Rest', 'Rest', 'Rest'],
    ),
  ];

  static const List<RoutineSuggestion> _5day = [
    RoutineSuggestion(
      name: 'Upper / Lower / PPL Hybrid',
      splitType: 'ul_ppl',
      tagline: 'Combines upper/lower efficiency with PPL frequency.',
      breakdown: ['Upper', 'Lower', 'Push', 'Pull', 'Legs', 'Rest', 'Rest'],
    ),
    RoutineSuggestion(
      name: 'Bro Split (5-day)',
      splitType: 'bro_split_5',
      tagline: 'Full weekly coverage — arms get a dedicated session.',
      breakdown: ['Chest', 'Back', 'Shoulders', 'Legs', 'Arms + Abs', 'Rest', 'Rest'],
    ),
  ];

  static const List<RoutineSuggestion> _6day = [
    RoutineSuggestion(
      name: 'PPL 2× (Classic)',
      splitType: 'ppl_2x',
      tagline: 'Each muscle group hit twice — considered the king of hypertrophy splits.',
      breakdown: ['Push A', 'Pull A', 'Legs A', 'Rest', 'Push B', 'Pull B', 'Legs B'],
    ),
    RoutineSuggestion(
      name: 'Arnold Split',
      splitType: 'arnold_split',
      tagline: "Arnold's original 6-day blueprint — antagonist supersets per session.",
      breakdown: ['Chest + Back', 'Shoulders + Arms', 'Legs', 'Chest + Back', 'Shoulders + Arms', 'Legs', 'Rest'],
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// ExerciseSet — one set entry in the active workout tracker
// ═══════════════════════════════════════════════════════════════

class ExerciseSet {
  final int setIndex;       // 1-based display number
  final String label;       // 'Warm-up', 'Working Set', 'Top Set'
  final double? targetWeightKg;
  final int? targetReps;

  // Mutable (user input)
  double? loggedWeightKg;
  int?    loggedReps;
  bool    isLogged;
  DateTime? loggedAt;

  ExerciseSet({
    required this.setIndex,
    required this.label,
    this.targetWeightKg,
    this.targetReps,
    this.loggedWeightKg,
    this.loggedReps,
    this.isLogged = false,
    this.loggedAt,
  });

  String get targetDisplayLabel {
    if (targetWeightKg != null && targetReps != null) {
      return '${targetWeightKg!.toStringAsFixed(0)} kg × $targetReps reps';
    }
    if (targetReps != null) return 'Target: $targetReps reps';
    return label;
  }

  Map<String, dynamic> toJson() => {
    'setIndex':       setIndex,
    'label':          label,
    'targetWeightKg': targetWeightKg,
    'targetReps':     targetReps,
    'loggedWeightKg': loggedWeightKg,
    'loggedReps':     loggedReps,
    'isLogged':       isLogged,
    'loggedAt':       loggedAt?.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════
// WorkoutLog — the full live session
// ═══════════════════════════════════════════════════════════════

class WorkoutLog {
  final String exerciseName;
  final String muscleGroup;
  final List<ExerciseSet> sets;
  final String? lastWeekTopPerformance;
  final DateTime startedAt;

  WorkoutLog({
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    this.lastWeekTopPerformance,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  int get loggedSetsCount => sets.where((s) => s.isLogged).length;
  bool get isComplete => loggedSetsCount == sets.length;

  Duration get elapsed => DateTime.now().difference(startedAt);

  /// Default push day session — used when backend has not yet provided live data
  factory WorkoutLog.defaultPushDay() {
    return WorkoutLog(
      exerciseName: 'Bench Press',
      muscleGroup: 'Chest · Triceps',
      lastWeekTopPerformance: '80 kg × 5 reps',
      sets: [
        ExerciseSet(
          setIndex: 1, label: 'Warm-up',
          targetWeightKg: 60, targetReps: 10,
        ),
        ExerciseSet(
          setIndex: 2, label: 'Working Set',
          targetWeightKg: 80, targetReps: 8,
        ),
        ExerciseSet(
          setIndex: 3, label: 'Working Set',
          targetWeightKg: 80, targetReps: 8,
        ),
        ExerciseSet(
          setIndex: 4, label: 'Top Set',
          targetWeightKg: 85, targetReps: 5,
        ),
        ExerciseSet(
          setIndex: 5, label: 'Back-off Set',
          targetWeightKg: 75, targetReps: 10,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseName':           exerciseName,
    'muscleGroup':            muscleGroup,
    'sets':                   sets.map((s) => s.toJson()).toList(),
    'lastWeekTopPerformance': lastWeekTopPerformance,
    'startedAt':              startedAt.toIso8601String(),
  };
}
