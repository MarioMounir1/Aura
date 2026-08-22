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
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
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
            final token = await _secureStorage.read(key: AppConstants.tokenKey);
            _cachedToken = token;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired — clear in-memory and secure storage
            _cachedToken = null;
            _cachedUserId = null;
            await _secureStorage.delete(key: AppConstants.tokenKey);
            await _secureStorage.delete(key: AppConstants.userIdKey);
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
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Clear all auth data
  Future<void> clearAuth() async {
    _cachedToken = null;
    _cachedUserId = null;
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.userIdKey);
    await _secureStorage.delete(key: 'is_premium');
    
    // Clear onboarding flag and cached user profile from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('cached_user_profile');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return true;
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    _cachedToken = token;
    return token != null && token.isNotEmpty;
  }

  /// Save isPremium to secure storage
  Future<void> saveIsPremium(bool isPremium) async {
    await _secureStorage.write(key: 'is_premium', value: isPremium ? 'true' : 'false');
  }

  /// Get isPremium status from secure storage
  Future<bool> getIsPremium() async {
    final val = await _secureStorage.read(key: 'is_premium');
    return val == 'true';
  }

  /// Save active userId to secure storage and in-memory cache
  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _secureStorage.write(key: AppConstants.userIdKey, value: userId);
  }

  /// Get active userId from in-memory cache or secure storage
  Future<String?> getUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) return _cachedUserId;
    _cachedUserId = await _secureStorage.read(key: AppConstants.userIdKey);
    return _cachedUserId;
  }
}
