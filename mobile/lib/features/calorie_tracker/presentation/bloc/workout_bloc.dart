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
  }

  Future<void> _onStartWorkoutSession(
    StartWorkoutSession event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());
    try {
      final sessionData = await repository.startSession(event.sessionName);
      final sessionId = sessionData['id'] as String;

      // Initialize empty session
      emit(WorkoutSessionActive(
        sessionId: sessionId,
        currentLogs: [],
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
}
