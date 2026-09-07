// lib/core/utils/constants.dart
// Aura — App-wide constants

class AppConstants {
  AppConstants._();

  // API
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    // Default to production cloud backend for both debug and release,
    // ensuring emulator/device testing always connects out of the box.
    return 'https://aura-backend-m4jk.onrender.com';
  }

  static String get apiV1 => '$baseUrl/api/v1';

  // Hive box names
  static const String mealLogsBox = 'meal_logs';
  static const String userBox = 'user_data';

  // Secure storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  // UI
  static const double borderRadius = 16.0;
  static const double cardElevation = 0.0;
  static const Duration animationDuration = Duration(milliseconds: 350);
  static const Duration shortAnimation = Duration(milliseconds: 200);

  // Popular Western restaurant chains (for autocomplete hints)
  static const List<String> popularRestaurants = [
    'Chipotle',
    'Sweetgreen',
    'Subway',
    'Panera Bread',
    'McDonald\'s',
    'Starbucks',
    'Chick-fil-A',
    'Wendy\'s',
    'Taco Bell',
    'Panda Express',
    'In-N-Out Burger',
    'Shake Shack',
    'Five Guys',
    'CAVA',
    'Jersey Mike\'s',
    'Popeyes',
    'KFC',
    'Domino\'s',
    'Dunkin\'',
    'Nando\'s',
  ];
}
