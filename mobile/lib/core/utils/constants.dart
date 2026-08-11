import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// lib/core/utils/constants.dart
// Aura — App-wide constants

class AppConstants {
  AppConstants._();

  // API
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kReleaseMode) {
      return 'https://aura-backend-m4jk.onrender.com';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
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

  // Egyptian restaurants (for autocomplete hints)
  static const List<String> popularRestaurants = [
    'Buffalo Burger',
    'Bazooka',
    'KFC Egypt',
    'McDonald\'s Egypt',
    'Pizza Hut Egypt',
    'Hardee\'s Egypt',
    'Koshary El Tahrir',
    'El Shabrawy',
    'Semiramis',
    'Hawawshi El Basha',
    'Felfela',
    'Abou El Sid',
    'Fish Market',
    'Kazouza',
    'Mince',
    'Cairo Kitchen',
    'Koshary Goha',
    'Nando\'s Egypt',
    'Cilantro',
    'Mandarine Koueider',
  ];
}
