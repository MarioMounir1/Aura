import 'package:equatable/equatable.dart';
import '../../data/models/workout_models.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutSessionActive extends WorkoutState {
  final String sessionId;
  final List<WorkoutLog> currentLogs;
  final bool isSubmitting;
  final String? error;
  final List<Exercise>? availableExercises;

  const WorkoutSessionActive({
    required this.sessionId,
    required this.currentLogs,
    this.isSubmitting = false,
    this.error,
    this.availableExercises,
  });

  WorkoutSessionActive copyWith({
    String? sessionId,
    List<WorkoutLog>? currentLogs,
    bool? isSubmitting,
    String? error,
    List<Exercise>? availableExercises,
  }) {
    return WorkoutSessionActive(
      sessionId: sessionId ?? this.sessionId,
      currentLogs: currentLogs ?? this.currentLogs,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error, // overwrite with null or value
      availableExercises: availableExercises ?? this.availableExercises,
    );
  }

  @override
  List<Object?> get props => [sessionId, currentLogs, isSubmitting, error, availableExercises];
}

class WorkoutError extends WorkoutState {
  final String message;
  const WorkoutError(this.message);

  @override
  List<Object> get props => [message];
}

class WorkoutSessionFinished extends WorkoutState {
  final String message;
  const WorkoutSessionFinished(this.message);

  @override
  List<Object> get props => [message];
}
