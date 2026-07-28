// lib/features/calorie_tracker/presentation/bloc/nutrition_progress_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/tracker_repository.dart';
import '../../data/models/nutrition_history_model.dart';

// ── Events ──
abstract class NutritionProgressEvent extends Equatable {
  const NutritionProgressEvent();
  @override
  List<Object?> get props => [];
}

class LoadNutritionHistory extends NutritionProgressEvent {
  final int days;
  const LoadNutritionHistory({this.days = 7});
  @override
  List<Object?> get props => [days];
}

// ── States ──
abstract class NutritionProgressState extends Equatable {
  const NutritionProgressState();
  @override
  List<Object?> get props => [];
}

class NutritionProgressInitial extends NutritionProgressState {}
class NutritionProgressLoading extends NutritionProgressState {}
class NutritionProgressLoaded extends NutritionProgressState {
  final NutritionHistoryModel history;
  final int selectedDays;
  const NutritionProgressLoaded(this.history, this.selectedDays);
  @override
  List<Object?> get props => [history, selectedDays];
}
class NutritionProgressError extends NutritionProgressState {
  final String message;
  const NutritionProgressError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──
class NutritionProgressBloc extends Bloc<NutritionProgressEvent, NutritionProgressState> {
  final TrackerRepository repository;

  NutritionProgressBloc(this.repository) : super(NutritionProgressInitial()) {
    on<LoadNutritionHistory>((event, emit) async {
      emit(NutritionProgressLoading());
      final result = await repository.getNutritionHistory(days: event.days);
      result.fold(
        (failure) => emit(NutritionProgressError(failure.message)),
        (data) {
          try {
            final model = NutritionHistoryModel.fromJson(data);
            emit(NutritionProgressLoaded(model, event.days));
          } catch (e) {
            emit(NutritionProgressError('Failed to parse nutrition history'));
          }
        },
      );
    });
  }
}
