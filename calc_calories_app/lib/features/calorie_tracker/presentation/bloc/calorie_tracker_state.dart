// lib/features/calorie_tracker/presentation/bloc/calorie_tracker_state.dart
// Calc-Calories — BLoC States

import 'package:equatable/equatable.dart';
import '../../domain/entities/meal_log_entity.dart';

abstract class CalorieTrackerState extends Equatable {
  const CalorieTrackerState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state
class CalorieTrackerInitial extends CalorieTrackerState {
  const CalorieTrackerInitial();
}

/// AI analysis in progress
class CalorieTrackerAnalyzing extends CalorieTrackerState {
  final bool isImageMode;

  const CalorieTrackerAnalyzing({this.isImageMode = false});

  @override
  List<Object?> get props => [isImageMode];
}

/// History is loading
class CalorieTrackerHistoryLoading extends CalorieTrackerState {
  const CalorieTrackerHistoryLoading();
}

/// Analysis succeeded — meal result ready
class CalorieTrackerAnalysisSuccess extends CalorieTrackerState {
  final MealLogEntity mealLog;
  final String source; // "ai" | "cache"

  const CalorieTrackerAnalysisSuccess({
    required this.mealLog,
    required this.source,
  });

  @override
  List<Object?> get props => [mealLog, source];
}

/// History loaded successfully
class CalorieTrackerHistoryLoaded extends CalorieTrackerState {
  final List<MealLogEntity> logs;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isOffline;

  const CalorieTrackerHistoryLoaded({
    required this.logs,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [logs, currentPage, totalPages, hasMore, isOffline];
}

/// A meal log was deleted
class CalorieTrackerDeleteSuccess extends CalorieTrackerState {
  final String deletedId;

  const CalorieTrackerDeleteSuccess(this.deletedId);

  @override
  List<Object?> get props => [deletedId];
}

/// Operation failed with a typed failure
class CalorieTrackerFailure extends CalorieTrackerState {
  final String message;
  final String? code;
  final bool isRateLimit;
  final int? retryAfterSeconds;

  const CalorieTrackerFailure({
    required this.message,
    this.code,
    this.isRateLimit = false,
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [message, code, isRateLimit, retryAfterSeconds];
}
