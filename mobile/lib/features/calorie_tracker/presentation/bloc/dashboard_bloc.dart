// lib/features/calorie_tracker/presentation/bloc/dashboard_bloc.dart
// The Teneen — Dashboard BLoC

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/tracker_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TrackerRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _fetchData(event.date, emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchData(event.date, emit);
  }

  Future<void> _fetchData(String? date, Emitter<DashboardState> emit) async {
    final dateStr = date ?? DateTime.now().toIso8601String().split('T')[0];

    final results = await Future.wait([
      repository.getTodayFoodSummary(date: dateStr),
      repository.getTodayWater(date: dateStr),
      repository.getWeightHistory(days: 7),
      repository.getTodayMealPlan(),
    ]);

    final foodRes = results[0] as dynamic;
    final waterRes = results[1] as dynamic;
    final weightRes = results[2] as dynamic;
    final mealPlanRes = results[3] as dynamic;

    String? errorMsg;
    Map<String, dynamic>? foodData;
    Map<String, dynamic>? waterData;
    Map<String, dynamic>? weightData;
    Map<String, dynamic>? mealPlanData;

    foodRes.fold(
      (failure) => errorMsg = failure.message,
      (data) => foodData = data,
    );

    waterRes.fold(
      (failure) => errorMsg ??= failure.message,
      (data) => waterData = data,
    );

    weightRes.fold(
      (failure) => errorMsg ??= failure.message,
      (data) => weightData = data,
    );

    mealPlanRes.fold(
      (failure) => errorMsg ??= failure.message,
      (data) => mealPlanData = data,
    );

    if (foodData != null && waterData != null && weightData != null && mealPlanData != null) {
      emit(DashboardLoaded(
        foodSummary: foodData!,
        waterSummary: waterData!,
        weightSummary: weightData!,
        mealPlanSummary: mealPlanData!,
        date: dateStr,
      ));
    } else {
      emit(DashboardFailure(errorMsg ?? 'Failed to load dashboard data'));
    }
  }
}
