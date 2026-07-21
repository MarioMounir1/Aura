import 'package:equatable/equatable.dart';
import '../../data/models/workout_models.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class StartWorkoutSession extends WorkoutEvent {
  final String sessionName;
  final List<SessionExercise>? initialExercises;
  const StartWorkoutSession(this.sessionName, {this.initialExercises});

  @override
  List<Object> get props => [sessionName];
}

class FetchAvailableExercises extends WorkoutEvent {
  const FetchAvailableExercises();
}

class AddExerciseToSessionEvent extends WorkoutEvent {
  final String exerciseId;
  const AddExerciseToSessionEvent(this.exerciseId);

  @override
  List<Object> get props => [exerciseId];
}

class LogSetEvent extends WorkoutEvent {
  final int setIndex;
  final double weightKg;
  final int reps;
  final String workoutExerciseId;

  const LogSetEvent({
    required this.setIndex,
    required this.weightKg,
    required this.reps,
    required this.workoutExerciseId,
  });

  @override
  List<Object> get props => [setIndex, weightKg, reps, workoutExerciseId];
}

class FinishWorkoutSession extends WorkoutEvent {
  const FinishWorkoutSession();
}
