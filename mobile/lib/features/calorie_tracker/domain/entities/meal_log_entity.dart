// lib/features/calorie_tracker/domain/entities/meal_log_entity.dart
// Calc-Calories — Domain entity (pure, no framework deps)

import 'package:equatable/equatable.dart';

class IngredientBreakdown extends Equatable {
  final String ingredient;
  final double estimatedWeightGrams;

  const IngredientBreakdown({
    required this.ingredient,
    required this.estimatedWeightGrams,
  });

  @override
  List<Object?> get props => [ingredient, estimatedWeightGrams];
}

class MealLogEntity extends Equatable {
  final String? id;
  final String restaurantName;
  final String mealName;
  final String? imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final List<IngredientBreakdown> ingredientsBreakdown;
  final String source; // "text" | "image"
  final DateTime createdAt;
  final bool isFromCache;

  const MealLogEntity({
    this.id,
    required this.restaurantName,
    required this.mealName,
    this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.ingredientsBreakdown,
    required this.source,
    required this.createdAt,
    this.isFromCache = false,
  });

  double get totalMacroCalories =>
      (protein * 4) + (carbs * 4) + (fats * 9);

  double get proteinPercent =>
      totalMacroCalories > 0 ? (protein * 4) / totalMacroCalories : 0;

  double get carbsPercent =>
      totalMacroCalories > 0 ? (carbs * 4) / totalMacroCalories : 0;

  double get fatsPercent =>
      totalMacroCalories > 0 ? (fats * 9) / totalMacroCalories : 0;

  @override
  List<Object?> get props => [
        id, restaurantName, mealName, calories,
        protein, carbs, fats, source, createdAt,
      ];
}
