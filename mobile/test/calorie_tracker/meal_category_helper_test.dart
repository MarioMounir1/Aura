import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/calorie_tracker/presentation/meals_dashboard_screen.dart';

void main() {
  group('MealCategoryHelper Tests', () {
    test('Correctly detects coffee and coffee variations', () {
      expect(MealCategoryHelper.isCoffee('Second Cup Iced Coffee with Milk'), isTrue);
      expect(MealCategoryHelper.isCoffee('Iced latte with oat milk'), isTrue);
      expect(MealCategoryHelper.isCoffee('Espresso macchiato'), isTrue);
      expect(MealCategoryHelper.isCoffee('Caramel Frappuccino'), isTrue);
      expect(MealCategoryHelper.isCoffee('Chicken breast with rice'), isFalse);
    });

    test('Correctly detects beverages', () {
      expect(MealCategoryHelper.isBeverageOrCoffee('Green Matcha Tea'), isTrue);
      expect(MealCategoryHelper.isBeverageOrCoffee('Mango Protein Smoothie'), isTrue);
      expect(MealCategoryHelper.isBeverageOrCoffee('Fresh Orange Juice'), isTrue);
      expect(MealCategoryHelper.isBeverageOrCoffee('Diet Coke'), isTrue);
      expect(MealCategoryHelper.isBeverageOrCoffee('Beef Burger'), isFalse);
    });

    test('Detects category as Coffee or Beverage regardless of lunchtime hour', () {
      // 12:00 PM (Lunch time)
      final noon = DateTime(2026, 10, 29, 12, 0);
      expect(
        MealCategoryHelper.detectCategory('Second Cup Iced Coffee with Milk', noon),
        equals('Coffee'),
      );
      expect(
        MealCategoryHelper.detectBadgeText('Second Cup Iced Coffee with Milk', noon),
        equals('COFFEE'),
      );
      expect(
        MealCategoryHelper.detectCategory('Green Tea Latte', noon),
        equals('Coffee'),
      );
      expect(
        MealCategoryHelper.detectCategory('Strawberry Smoothie', noon),
        equals('Beverage'),
      );

      // Normal food at noon defaults to Lunch
      expect(
        MealCategoryHelper.detectCategory('Grilled Chicken Bowl', noon),
        equals('Lunch'),
      );
      expect(
        MealCategoryHelper.detectBadgeText('Grilled Chicken Bowl', noon),
        equals('LUNCH'),
      );
    });

    test('Returns appropriate contextual emoji', () {
      expect(
        MealCategoryHelper.getPlaceholderEmoji('Second Cup Iced Coffee with Milk'),
        equals('☕'),
      );
      expect(
        MealCategoryHelper.getPlaceholderEmoji('Iced Green Tea'),
        equals('🥤'),
      );
      expect(
        MealCategoryHelper.getPlaceholderEmoji('Cheeseburger'),
        equals('🍔'),
      );
      expect(
        MealCategoryHelper.getPlaceholderEmoji('Grilled Ribeye Steak'),
        equals('🥩'),
      );
      expect(
        MealCategoryHelper.getPlaceholderEmoji('Caesar Salad'),
        equals('🥗'),
      );
    });

    test('MealEntry copyWith preserves and updates category and imagePath', () {
      final original = MealEntry(
        id: '123',
        foodName: 'Second Cup Iced Coffee with Milk',
        restaurantName: 'Second Cup',
        protein: 4,
        carbs: 25,
        fat: 7,
        calories: 180,
        warnings: const [],
        isHighlyNutritious: false,
        createdAt: DateTime(2026, 10, 29, 11, 57),
        source: 'image',
        imagePath: '/path/to/scan.jpg',
        ingredientsBreakdown: const [],
        mealCategory: 'Coffee',
      );

      final updated = original.copyWith(
        mealCategory: 'Snack',
      );

      expect(updated.id, equals('123'));
      expect(updated.foodName, equals('Second Cup Iced Coffee with Milk'));
      expect(updated.mealCategory, equals('Snack'));
      expect(updated.imagePath, equals('/path/to/scan.jpg'));
    });
  });
}
