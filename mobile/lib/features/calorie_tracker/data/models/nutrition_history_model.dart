// lib/features/calorie_tracker/data/models/nutrition_history_model.dart

class NutritionHistoryDay {
  final String date;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  NutritionHistoryDay({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory NutritionHistoryDay.fromJson(Map<String, dynamic> json) {
    return NutritionHistoryDay(
      date: json['date'] as String? ?? '',
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fats: json['fats'] as int? ?? 0,
    );
  }
}

class NutritionHistoryStats {
  final int averageCalories;
  final int averageProtein;
  final int daysGoalMet;

  NutritionHistoryStats({
    required this.averageCalories,
    required this.averageProtein,
    required this.daysGoalMet,
  });

  factory NutritionHistoryStats.fromJson(Map<String, dynamic> json) {
    return NutritionHistoryStats(
      averageCalories: json['averageCalories'] as int? ?? 0,
      averageProtein: json['averageProtein'] as int? ?? 0,
      daysGoalMet: json['daysGoalMet'] as int? ?? 0,
    );
  }
}

class NutritionHistoryGoals {
  final int calories;
  final int protein;

  NutritionHistoryGoals({
    required this.calories,
    required this.protein,
  });

  factory NutritionHistoryGoals.fromJson(Map<String, dynamic> json) {
    return NutritionHistoryGoals(
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
    );
  }
}

class NutritionHistoryModel {
  final List<NutritionHistoryDay> days;
  final NutritionHistoryStats stats;
  final NutritionHistoryGoals goals;

  NutritionHistoryModel({
    required this.days,
    required this.stats,
    required this.goals,
  });

  factory NutritionHistoryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final daysList = (data['days'] as List<dynamic>?)?.map((e) => NutritionHistoryDay.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    
    return NutritionHistoryModel(
      days: daysList,
      stats: NutritionHistoryStats.fromJson(data['stats'] as Map<String, dynamic>? ?? {}),
      goals: NutritionHistoryGoals.fromJson(data['goals'] as Map<String, dynamic>? ?? {}),
    );
  }
}
