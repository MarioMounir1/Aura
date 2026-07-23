// lib/features/calorie_tracker/presentation/bloc/weight_event.dart
// The Teneen — Weight Tracking Events

import 'package:equatable/equatable.dart';

abstract class WeightEvent extends Equatable {
  const WeightEvent();

  @override
  List<Object?> get props => [];
}

class LoadWeightHistory extends WeightEvent {
  final int days;
  const LoadWeightHistory({this.days = 30});

  @override
  List<Object?> get props => [days];
}

class LogWeightMeasurement extends WeightEvent {
  final double weightKg;
  const LogWeightMeasurement(this.weightKg);

  @override
  List<Object?> get props => [weightKg];
}

class DeleteWeightLogEvent extends WeightEvent {
  final String logId;
  const DeleteWeightLogEvent(this.logId);

  @override
  List<Object?> get props => [logId];
}

class ResetWeightEvent extends WeightEvent {
  const ResetWeightEvent();
}
