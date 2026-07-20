// lib/features/calorie_tracker/data/repositories/workout_repository_impl.dart
// Aura — Workout Repository Implementation

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/workout_repository.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final ApiClient _apiClient;

  WorkoutRepositoryImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> startSession(String name) async {
    try {
      final response = await _apiClient.dio.post(
        '/workouts/session/start',
        data: {'name': name},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> addExercise(
    String sessionId,
    String exerciseId,
    int order, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/workouts/session/exercise',
        data: {
          'sessionId': sessionId,
          'exerciseId': exerciseId,
          'order': order,
          if (notes != null) 'notes': notes,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to add exercise: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> logSet(
    String workoutExerciseId,
    int setNumber, {
    int? reps,
    double? weightKg,
    int? rpe,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/workouts/session/set',
        data: {
          'workoutExerciseId': workoutExerciseId,
          'setNumber': setNumber,
          if (reps != null) 'reps': reps,
          if (weightKg != null) 'weightKg': weightKg,
          if (rpe != null) 'rpe': rpe,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to log set: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> finishSession(String sessionId, {String? notes}) async {
    try {
      final response = await _apiClient.dio.post(
        '/workouts/session/$sessionId/finish',
        data: {
          if (notes != null) 'notes': notes,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to finish session: $e');
    }
  }
}
