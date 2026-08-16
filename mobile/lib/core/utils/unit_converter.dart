// lib/core/utils/unit_converter.dart
// Measurement units conversion and formatting utilities for Aura

enum UnitSystem {
  metric,   // kg, cm, ml
  imperial, // lbs, ft/in, fl oz
}

class UnitConverter {
  UnitConverter._();

  static const double _kgToLbsRatio = 2.20462262;
  static const double _inchToCmRatio = 2.54;
  static const double _flOzToMlRatio = 29.5735296;

  // ── Weight ───────────────────────────────────────────────────

  /// Converts kilograms to pounds
  static double kgToLbs(double kg) => kg * _kgToLbsRatio;

  /// Converts pounds to kilograms
  static double lbsToKg(double lbs) => lbs / _kgToLbsRatio;

  /// Formats weight according to the active unit system
  static String formatWeight(double? weightKg, UnitSystem system, {int decimals = 1}) {
    if (weightKg == null) return '--';
    if (system == UnitSystem.imperial) {
      final lbs = kgToLbs(weightKg);
      return '${lbs.toStringAsFixed(decimals)} lbs';
    }
    return '${weightKg.toStringAsFixed(decimals)} kg';
  }

  /// Formats weight value only (numeric string)
  static String formatWeightValue(double? weightKg, UnitSystem system, {int decimals = 1}) {
    if (weightKg == null) return '';
    if (system == UnitSystem.imperial) {
      return kgToLbs(weightKg).toStringAsFixed(decimals);
    }
    return weightKg.toStringAsFixed(decimals);
  }

  // ── Height ───────────────────────────────────────────────────

  /// Converts centimeters to feet and inches record
  static ({int feet, int inches}) cmToFeetInches(double cm) {
    if (cm <= 0) return (feet: 0, inches: 0);
    final totalInches = (cm / _inchToCmRatio).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet: feet, inches: inches);
  }

  /// Converts feet and inches to centimeters
  static double feetInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return totalInches * _inchToCmRatio;
  }

  /// Formats height according to the active unit system
  static String formatHeight(double? heightCm, UnitSystem system) {
    if (heightCm == null || heightCm <= 0) return '--';
    if (system == UnitSystem.imperial) {
      final ftIn = cmToFeetInches(heightCm);
      return '${ftIn.feet}\' ${ftIn.inches}"';
    }
    return '${heightCm.toStringAsFixed(0)} cm';
  }

  /// Formats height value for single input or summary
  static String formatHeightValue(double? heightCm, UnitSystem system) {
    if (heightCm == null || heightCm <= 0) return '';
    if (system == UnitSystem.imperial) {
      final ftIn = cmToFeetInches(heightCm);
      return '${ftIn.feet}\' ${ftIn.inches}"';
    }
    return heightCm.toStringAsFixed(0);
  }

  // ── Water ────────────────────────────────────────────────────

  /// Converts milliliters to fluid ounces
  static double mlToFlOz(int ml) => ml / _flOzToMlRatio;

  /// Converts fluid ounces to milliliters
  static int flOzToMl(double flOz) => (flOz * _flOzToMlRatio).round();

  /// Formats water amount according to the active unit system
  static String formatWater(int? ml, UnitSystem system) {
    if (ml == null) return '--';
    if (system == UnitSystem.imperial) {
      final flOz = mlToFlOz(ml);
      return '${flOz.toStringAsFixed(0)} fl oz';
    }
    return '$ml ml';
  }
}
