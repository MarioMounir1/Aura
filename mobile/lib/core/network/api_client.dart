// lib/core/network/api_client.dart
// Aura — Dio HTTP Client with Auth Interceptor

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../utils/constants.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  String? _cachedToken;
  String? _cachedUserId;
  static void Function()? onUnauthorized;

  ApiClient._internal(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiV1,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_cachedToken != null && _cachedToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_cachedToken';
          } else {
            try {
              final token = await _secureStorage.read(key: AppConstants.tokenKey);
              _cachedToken = token;
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {}
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.contains('/auth/');
          final hadAuthHeader = error.requestOptions.headers['Authorization'] != null;

          if (error.response?.statusCode == 401 && !isAuthEndpoint && hadAuthHeader) {
            // Token confirmed expired by backend on an authenticated call
            _cachedToken = null;
            _cachedUserId = null;
            try {
              await _secureStorage.delete(key: AppConstants.tokenKey);
              await _secureStorage.delete(key: AppConstants.userIdKey);
            } catch (_) {}
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );

    // Request/response logger (debug builds only - error and compact summaries)
    assert(() {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          compact: true,
        ),
      );
      return true;
    }());
  }

  factory ApiClient({FlutterSecureStorage? secureStorage}) {
    _instance ??= ApiClient._internal(
      secureStorage ?? const FlutterSecureStorage(),
    );
    return _instance!;
  }

  Dio get dio => _dio;

  /// Save auth token to secure storage and in-memory cache
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {}
  }

  /// Clear all auth data
  Future<void> clearAuth() async {
    _cachedToken = null;
    _cachedUserId = null;
    try {
      await _secureStorage.delete(key: AppConstants.tokenKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);
      await _secureStorage.delete(key: 'is_premium');
    } catch (_) {}
    
    // Clear onboarding flag and cached user profile from shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('cached_user_profile');
    } catch (_) {}
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return true;
    try {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      _cachedToken = token;
      return token != null && token.isNotEmpty;
    } catch (_) {
      return _cachedToken != null && _cachedToken!.isNotEmpty;
    }
  }

  /// Save isPremium to secure storage
  Future<void> saveIsPremium(bool isPremium) async {
    try {
      await _secureStorage.write(key: 'is_premium', value: isPremium ? 'true' : 'false');
    } catch (_) {}
  }

  /// Get isPremium status from secure storage
  Future<bool> getIsPremium() async {
    try {
      final val = await _secureStorage.read(key: 'is_premium');
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Save active userId to secure storage and in-memory cache
  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    try {
      await _secureStorage.write(key: AppConstants.userIdKey, value: userId);
    } catch (_) {}
  }

  /// Get active userId from in-memory cache or secure storage
  Future<String?> getUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) return _cachedUserId;
    try {
      _cachedUserId = await _secureStorage.read(key: AppConstants.userIdKey);
    } catch (_) {}
    return _cachedUserId;
  }
}
