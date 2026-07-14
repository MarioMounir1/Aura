// lib/features/calorie_tracker/data/models/meal_log_model.dart
// Calc-Calories — Data model with Hive + JSON serialization

import 'package:hive/hive.dart';
import '../../domain/entities/meal_log_entity.dart';

part 'meal_log_model.g.dart';

@HiveType(typeId: 0)
class IngredientBreakdownModel extends HiveObject {
  @HiveField(0)
  final String ingredient;

  @HiveField(1)
  final double estimatedWeightGrams;

  IngredientBreakdownModel({
    required this.ingredient,
    required this.estimatedWeightGrams,
  });

  factory IngredientBreakdownModel.fromJson(Map<String, dynamic> json) {
    return IngredientBreakdownModel(
      ingredient: json['ingredient'] as String? ?? '',
      estimatedWeightGrams: (json['estimatedWeightGrams'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient': ingredient,
        'estimatedWeightGrams': estimatedWeightGrams,
      };

  IngredientBreakdown toEntity() => IngredientBreakdown(
        ingredient: ingredient,
        estimatedWeightGrams: estimatedWeightGrams,
      );

  factory IngredientBreakdownModel.fromEntity(IngredientBreakdown entity) {
    return IngredientBreakdownModel(
      ingredient: entity.ingredient,
      estimatedWeightGrams: entity.estimatedWeightGrams,
    );
  }
}

@HiveType(typeId: 1)
class MealLogModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String restaurantName;

  @HiveField(2)
  final String mealName;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final double calories;

  @HiveField(5)
  final double protein;

  @HiveField(6)
  final double carbs;

  @HiveField(7)
  final double fats;

  @HiveField(8)
  final List<IngredientBreakdownModel> ingredientsBreakdown;

  @HiveField(9)
  final String source;

  @HiveField(10)
  final DateTime createdAt;

  MealLogModel({
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
  });

  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredientsBreakdown'];
    List<IngredientBreakdownModel> ingredients = [];

    if (rawIngredients is List) {
      ingredients = rawIngredients
          .whereType<Map<String, dynamic>>()
          .map((e) => IngredientBreakdownModel.fromJson(e))
          .toList();
    }

    return MealLogModel(
      id: json['id'] as String?,
      restaurantName: json['restaurantName'] as String? ?? '',
      mealName: json['mealName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
      ingredientsBreakdown: ingredients,
      source: json['source'] as String? ?? 'text',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantName': restaurantName,
        'mealName': mealName,
        'imageUrl': imageUrl,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'ingredientsBreakdown':
            ingredientsBreakdown.map((e) => e.toJson()).toList(),
        'source': source,
        'createdAt': createdAt.toIso8601String(),
      };

  MealLogEntity toEntity() => MealLogEntity(
        id: id,
        restaurantName: restaurantName,
        mealName: mealName,
        imageUrl: imageUrl,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
        ingredientsBreakdown:
            ingredientsBreakdown.map((e) => e.toEntity()).toList(),
        source: source,
        createdAt: createdAt,
      );

  factory MealLogModel.fromEntity(MealLogEntity entity) {
    return MealLogModel(
      id: entity.id,
      restaurantName: entity.restaurantName,
      mealName: entity.mealName,
      imageUrl: entity.imageUrl,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fats: entity.fats,
      ingredientsBreakdown: entity.ingredientsBreakdown
          .map(IngredientBreakdownModel.fromEntity)
          .toList(),
      source: entity.source,
      createdAt: entity.createdAt,
    );
  }
}
