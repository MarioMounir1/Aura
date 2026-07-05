// lib/features/calorie_tracker/domain/repositories/meal_repository.dart
// Calc-Calories — Repository Interface (Domain Layer)

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/meal_log_entity.dart';

abstract class MealRepository {
  /// Analyze a meal from a text description.
  /// Returns [MealLogEntity] or [Failure].
  Future<Either<Failure, MealLogEntity>> analyzeTextMeal({
    required String restaurantName,
    required String mealDescription,
  });

  /// Analyze a meal from an image file.
  /// Returns [MealLogEntity] or [Failure].
  Future<Either<Failure, MealLogEntity>> analyzeImageMeal({
    required String imagePath,
    String? restaurantName,
  });

  /// Get paginated meal history from server (network-first, cache fallback).
  Future<Either<Failure, List<MealLogEntity>>> getMealHistory({
    int page = 1,
    int limit = 20,
    String? date,
  });

  /// Delete a meal log by ID.
  Future<Either<Failure, void>> deleteMealLog(String id);

  /// Get cached meal logs from Hive (offline fallback).
  Future<Either<Failure, List<MealLogEntity>>> getCachedMealLogs();

  /// Save a meal log to local Hive cache.
  Future<Either<Failure, void>> cacheMealLog(MealLogEntity mealLog);

  /// Get macro suggestions and sponsored product recommendations.
  Future<Either<Failure, Map<String, dynamic>>> getSuggestions();
}
