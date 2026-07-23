// lib/features/calorie_tracker/presentation/bloc/dashboard_state.dart
// The Teneen — Dashboard States

import 'package:equatable/equatable.dart';
import '../../domain/entities/meal_log_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> foodSummary;
  final Map<String, dynamic> waterSummary;
  final Map<String, dynamic> weightSummary;
  final Map<String, dynamic> mealPlanSummary;
  final List<MealLogEntity> todayMealLogs;
  final String date;

  const DashboardLoaded({
    required this.foodSummary,
    required this.waterSummary,
    required this.weightSummary,
    required this.mealPlanSummary,
    this.todayMealLogs = const [],
    required this.date,
  });

  @override
  List<Object?> get props => [
        foodSummary,
        waterSummary,
        weightSummary,
        mealPlanSummary,
        todayMealLogs,
        date,
      ];
}

class DashboardFailure extends DashboardState {
  final String message;

  const DashboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
