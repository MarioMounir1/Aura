// lib/core/cubit/unit_cubit.dart
// Holds and persists app measurement unit system (Metric vs Imperial)

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/unit_converter.dart';

class UnitCubit extends Cubit<UnitSystem> {
  static const _prefKey = 'app_unit_system';

  UnitCubit(UnitSystem initialSystem) : super(initialSystem);

  Future<void> setUnitSystem(UnitSystem system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, system.name);
    emit(system);
  }

  Future<void> toggleUnitSystem() async {
    final next = state == UnitSystem.metric ? UnitSystem.imperial : UnitSystem.metric;
    await setUnitSystem(next);
  }

  static Future<UnitSystem> getSavedUnitSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? 'metric';
    switch (saved) {
      case 'imperial':
        return UnitSystem.imperial;
      case 'metric':
      default:
        return UnitSystem.metric;
    }
  }
}
