import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/models/workout_models.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository repository;

  WorkoutBloc(this.repository) : super(WorkoutInitial()) {
    on<StartWorkoutSession>(_onStartWorkoutSession);
    on<FetchAvailableExercises>(_onFetchAvailableExercises);
    on<AddExerciseToSessionEvent>(_onAddExerciseToSessionEvent);
    on<LogSetEvent>(_onLogSetEvent);
    on<FinishWorkoutSession>(_onFinishWorkoutSession);
    on<SwapWorkoutExercise>(_onSwapWorkoutExercise);
    on<ResetWorkoutEvent>((event, emit) => emit(WorkoutInitial()));
  }

  Future<void> _onStartWorkoutSession(
    StartWorkoutSession event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());
    try {
      List<Map<String, dynamic>>? payloadExercises;
      if (event.initialExercises != null) {
        payloadExercises = event.initialExercises!.map((e) => {
          if (e.id != null) 'id': e.id,
          'name': e.name,
          'targetSets': e.targetSets,
          if (e.muscleGroup.isNotEmpty) 'muscleGroup': e.muscleGroup,
          if (e.lastWeekWeight != null) 'lastWeekWeight': e.lastWeekWeight,
          if (e.lastWeekReps != null) 'lastWeekReps': e.lastWeekReps,
        }).toList();
      }

      final sessionData = await repository.startSession(
        event.sessionName,
        exercises: payloadExercises,
      );
      final sessionId = sessionData['id'] as String;

      // The backend returns the created WorkoutSession along with nested exercises (WorkoutExercise)
      // We map these back to WorkoutLog objects
      List<WorkoutLog> initialLogs = [];
      
      final createdExercises = sessionData['exercises'] as List<dynamic>? ?? [];
      if (createdExercises.isNotEmpty && event.initialExercises != null) {
        for (int i = 0; i < event.initialExercises!.length; i++) {
          final exTemplate = event.initialExercises![i];
          // Match by order if possible, or just index
          final dbEx = createdExercises.firstWhere(
            (e) => e['exerciseId'] == exTemplate.id && e['order'] == i,
            orElse: () => createdExercises.length > i ? createdExercises[i] : null,
          );
          
          if (dbEx != null) {
             initialLogs.add(
                WorkoutLog(
                  sessionId: sessionId,
                  exerciseName: exTemplate.name,
                  muscleGroup: exTemplate.muscleGroup,
                  lastWeekTopPerformance: (exTemplate.lastWeekWeight != null && exTemplate.lastWeekReps != null)
                      ? '${exTemplate.lastWeekWeight!.toStringAsFixed(0)} kg × ${exTemplate.lastWeekReps}'
                      : null,
                  sets: List.generate(exTemplate.targetSets, (sIdx) => ExerciseSet(
                    id: dbEx['id'] as String, // the workoutExerciseId
                    setIndex: sIdx + 1,
                    label: sIdx == exTemplate.targetSets - 1 ? 'Top Set' : 'Working Set',
                  )),
                ),
             );
          }
        }
      }

      emit(WorkoutSessionActive(
        sessionId: sessionId,
        currentLogs: initialLogs,
      ));
    } catch (e) {
      emit(WorkoutError(e.toString()));
    }
  }

  Future<void> _onFetchAvailableExercises(
    FetchAvailableExercises event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      final exercises = await repository.getAvailableExercises();
      final parsed = exercises.map((e) => Exercise.fromJson(e)).toList();
      emit(currentState.copyWith(availableExercises: parsed));
    } catch (e) {
      emit(currentState.copyWith(error: e.toString()));
    }
  }

  Future<void> _onAddExerciseToSessionEvent(
    AddExerciseToSessionEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    emit(currentState.copyWith(isSubmitting: true));

    try {
      final order = currentState.currentLogs.length;
      final addedExercise = await repository.addExercise(
        currentState.sessionId,
        event.exerciseId,
        order,
      );

      final dbWorkoutExerciseId = addedExercise['id'] as String;
      
      // Find the exercise details from availableExercises
      final exDetail = currentState.availableExercises?.firstWhere(
        (e) => e.id == event.exerciseId,
        orElse: () => Exercise(id: event.exerciseId, name: 'Unknown', muscleGroup: 'Unknown'),
      );

      final newLog = WorkoutLog(
        sessionId: currentState.sessionId,
        exerciseName: exDetail?.name ?? 'Unknown',
        muscleGroup: exDetail?.muscleGroup ?? 'Unknown',
        sets: [
          ExerciseSet(
            id: dbWorkoutExerciseId, // We temporarily store the workoutExerciseId in the first set or somewhere else. Wait!
            setIndex: 1,
            label: 'Working Set',
          )
        ],
      );

      final updatedLogs = List<WorkoutLog>.from(currentState.currentLogs)..add(newLog);

      emit(currentState.copyWith(
        currentLogs: updatedLogs,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onLogSetEvent(
    LogSetEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    emit(currentState.copyWith(isSubmitting: true));

    try {
      // Call repository to log set
      await repository.logSet(
        event.workoutExerciseId,
        event.setIndex,
        reps: event.reps,
        weightKg: event.weightKg,
      );

      // Find which log contains this set and update it
      final updatedLogs = List<WorkoutLog>.from(currentState.currentLogs);
      bool setFound = false;
      for (var log in updatedLogs) {
        for (var s in log.sets) {
          if (s.setIndex == event.setIndex && s.id == event.workoutExerciseId) {
            s.loggedWeightKg = event.weightKg;
            s.loggedReps = event.reps;
            s.isLogged = true;
            s.loggedAt = DateTime.now();
            setFound = true;
            break;
          }
        }
        if (setFound) break;
      }

      emit(currentState.copyWith(
        currentLogs: updatedLogs,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onFinishWorkoutSession(
    FinishWorkoutSession event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    emit(currentState.copyWith(isSubmitting: true));

    try {
      await repository.finishSession(currentState.sessionId, notes: 'Great workout!');
      emit(const WorkoutSessionFinished('Workout successfully completed!'));
    } catch (e) {
      emit(currentState.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSwapWorkoutExercise(
    SwapWorkoutExercise event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    emit(currentState.copyWith(isSubmitting: true));

    try {
      // 1. Perform Swap via repository
      await repository.swapExercise(event.workoutExerciseId, event.newExerciseId);
      
      // 2. Fetch the metadata for the replacement exercise
      final newExerciseDetail = currentState.availableExercises?.firstWhere(
        (e) => e.id == event.newExerciseId,
        orElse: () => Exercise(id: event.newExerciseId, name: 'Alternative Movement', muscleGroup: 'Alternative'),
      );

      // 3. Map logs to updated exercise state
      final updatedLogs = currentState.currentLogs.map((log) {
        final matches = log.sets.any((s) => s.id == event.workoutExerciseId);
        if (matches) {
          final targetSetsCount = log.sets.length;
          return WorkoutLog(
            sessionId: log.sessionId,
            exerciseName: newExerciseDetail?.name ?? 'Alternative Movement',
            muscleGroup: newExerciseDetail?.muscleGroup ?? 'Alternative',
            lastWeekTopPerformance: null, // Reset history as movement changed
            sets: List.generate(targetSetsCount, (sIdx) => ExerciseSet(
              id: event.workoutExerciseId,
              setIndex: sIdx + 1,
              label: sIdx == targetSetsCount - 1 ? 'Top Set' : 'Working Set',
            )),
          );
        }
        return log;
      }).toList();

      emit(currentState.copyWith(
        currentLogs: updatedLogs,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }
}
