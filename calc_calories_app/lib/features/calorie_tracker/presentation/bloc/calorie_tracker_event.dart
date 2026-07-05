// lib/features/calorie_tracker/presentation/bloc/calorie_tracker_event.dart
// Calc-Calories — BLoC Events

import 'package:equatable/equatable.dart';

abstract class CalorieTrackerEvent extends Equatable {
  const CalorieTrackerEvent();

  @override
  List<Object?> get props => [];
}

/// User typed/updated the meal text description
class MealTextChanged extends CalorieTrackerEvent {
  final String restaurantName;
  final String mealDescription;

  const MealTextChanged({
    required this.restaurantName,
    required this.mealDescription,
  });

  @override
  List<Object?> get props => [restaurantName, mealDescription];
}

/// User submitted text-based meal for analysis
class AnalyzeTextMealSubmitted extends CalorieTrackerEvent {
  final String restaurantName;
  final String mealDescription;

  const AnalyzeTextMealSubmitted({
    required this.restaurantName,
    required this.mealDescription,
  });

  @override
  List<Object?> get props => [restaurantName, mealDescription];
}

/// User selected an image for screenshot analysis
class ImageSelected extends CalorieTrackerEvent {
  final String imagePath;
  final String? restaurantName;

  const ImageSelected({
    required this.imagePath,
    this.restaurantName,
  });

  @override
  List<Object?> get props => [imagePath, restaurantName];
}

/// User triggered meal history load
class FetchMealHistory extends CalorieTrackerEvent {
  final int page;
  final String? dateFilter;

  const FetchMealHistory({this.page = 1, this.dateFilter});

  @override
  List<Object?> get props => [page, dateFilter];
}

/// User deleted a meal log entry
class DeleteMealLog extends CalorieTrackerEvent {
  final String mealLogId;

  const DeleteMealLog(this.mealLogId);

  @override
  List<Object?> get props => [mealLogId];
}

/// Reset to initial state (e.g., after navigating away)
class ResetCalorieTracker extends CalorieTrackerEvent {
  const ResetCalorieTracker();
}

/// Initialize Google Mobile Ads AdMob Banner layout
class InitializeAds extends CalorieTrackerEvent {
  const InitializeAds();
}
