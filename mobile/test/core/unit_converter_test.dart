// test/core/unit_converter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('Weight conversion kg <-> lbs', () {
      const kg = 70.0;
      final lbs = UnitConverter.kgToLbs(kg);
      expect((lbs - 154.32).abs() < 0.1, isTrue);

      final backToKg = UnitConverter.lbsToKg(lbs);
      expect((backToKg - kg).abs() < 0.001, isTrue);
    });

    test('Height conversion cm <-> ft & in', () {
      // 175 cm ~= 5 ft 9 in (68.9 inches -> 69 inches)
      final ftIn = UnitConverter.cmToFeetInches(175.0);
      expect(ftIn.feet, equals(5));
      expect(ftIn.inches, equals(9));

      // 6 ft 0 in = 72 in = 182.88 cm
      final cm = UnitConverter.feetInchesToCm(6, 0);
      expect((cm - 182.88).abs() < 0.01, isTrue);
    });

    test('Formatting helpers output expected strings', () {
      expect(UnitConverter.formatWeight(75.0, UnitSystem.metric), equals('75.0 kg'));
      expect(UnitConverter.formatWeight(75.0, UnitSystem.imperial), equals('165.3 lbs'));

      expect(UnitConverter.formatHeight(175.0, UnitSystem.metric), equals('175 cm'));
      expect(UnitConverter.formatHeight(175.0, UnitSystem.imperial), equals('5\' 9"'));
    });
  });
}
