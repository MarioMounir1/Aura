// lib/features/calorie_tracker/data/services/local_llama_service.dart
// Aura — Local Llama Dio Network Service
//
// Handles the multipart/form-data image upload to:
//   POST http://10.0.2.2:3000/api/v1/meals/scan-local
//
// Uses the authenticated ApiClient (injects JWT Bearer token automatically).
// Returns a parsed LlamaMealResponse or throws a typed LlamaApiException.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/constants.dart';
import '../models/llama_meal_response.dart';
import '../models/ai_usage_quota.dart';

class LocalLlamaService {
  final Dio _dio;

  // Endpoint path — relative to the ApiClient base URL (/api/v1)
  static const String _endpoint = '/meals/scan-local';

  // Timeout durations — local inference can be slow on CPU
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(minutes: 3); // llava on CPU
  static const Duration _sendTimeout    = Duration(seconds: 30);

  LocalLlamaService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? _buildDio(secureStorage ?? const FlutterSecureStorage());

  // ── Build a dedicated Dio instance ────────────────────────
  // We create a separate instance (not the shared ApiClient singleton)
  // so we can set generous timeouts for local LLM inference without
  // affecting the rest of the app's network calls.

  static Dio _buildDio(FlutterSecureStorage secureStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl:        AppConstants.apiV1,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout:    _sendTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Inject JWT token from secure storage on every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = AppConstants.apiV1;
          final token = await secureStorage.read(key: AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }

  // ── Fetch Usage Limits ──────────────────────────────────────

  Future<AiUsageQuota> fetchAiUsage() async {
    try {
      final url = '${AppConstants.apiV1}/meals/usage';
      debugPrint('🚀 [GeminiScan] GET $url');
      final response = await _dio.get<dynamic>(url);
      final body = response.data;
      if (body != null && body['success'] == true) {
        return AiUsageQuota.fromJson(body['data']);
      }
      throw const LlamaApiException('Failed to fetch AI usage quota.');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (_) {
      throw const LlamaApiException('Unable to retrieve daily scan limits. Please try again.');
    }
  }

  // ── Core Upload Method ────────────────────────────────────

  /// Uploads [imageFile] to the local Llama scan endpoint.
  ///
  /// Throws:
  ///   [LlamaApiException]    — on API-level errors (bad payload, model failure)
  ///   [LlamaNetworkException] — on connectivity / timeout issues
  Future<LlamaMealResponse> scanMealImage(File imageFile, String scanType) async {
    // Validate file exists before sending
    if (!imageFile.existsSync()) {
      throw const LlamaNetworkException('Selected image could not be found on your device.');
    }

    final fileSize = await imageFile.length();
    if (fileSize > 15 * 1024 * 1024) {
      throw const LlamaNetworkException(
        'Image is too large (max 15 MB). Please choose a smaller photo.',
      );
    }

    // Build multipart form data with the "image" field key
    // (matches the backend's upload.middleware field name)
    late final FormData formData;
    try {
      formData = FormData.fromMap({
        'scanType': scanType,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'meal_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
    } catch (_) {
      throw const LlamaNetworkException('Unable to process the photo. Please select another image.');
    }

    // ── POST request with strict error handling ─────────────
    late final Response<dynamic> response;
    final url = '${AppConstants.apiV1}$_endpoint';
    debugPrint('🚀 [GeminiScan] POST $url (size: ${(fileSize / 1024).toStringAsFixed(1)} KB)');
    try {
      response = await _dio.post<dynamic>(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          // Explicit per-request timeout override (belt + suspenders)
          receiveTimeout: _receiveTimeout,
          sendTimeout:    _sendTimeout,
        ),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (_) {
      throw const LlamaNetworkException('Unable to upload image. Please try again.');
    }

    // ── Parse the JSON response ─────────────────────────────
    final body = response.data;
    if (body == null || body is! Map<String, dynamic>) {
      throw const LlamaApiException(
        'Server returned an invalid response. Please try again.',
      );
    }

    try {
      return LlamaMealResponse.fromJson(body);
    } on LlamaApiException {
      rethrow; // Already typed — pass through
    } catch (_) {
      throw const LlamaApiException('Could not parse meal analysis response.');
    }
  }

  // ── DioException → Typed Exception Mapper ─────────────────

  LlamaNetworkException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return const LlamaNetworkException(
          'Connection timed out. Please check your network and try again.',
          isTimeout: true,
        );
      case DioExceptionType.receiveTimeout:
        return const LlamaNetworkException(
          'Meal analysis is taking longer than expected. Please try again.',
          isTimeout: true,
        );
      case DioExceptionType.sendTimeout:
        return const LlamaNetworkException(
          'Image upload timed out. Please check your internet connection.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const LlamaNetworkException(
          'Unable to reach server. Please check your internet connection.',
          isConnectionError: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final errBody    = e.response?.data;
        debugPrint('❌ [GeminiScan] Server error $statusCode: $errBody');
        final errMsg     = errBody is Map ? (errBody['details'] as String? ?? errBody['error'] as String? ?? errBody['message'] as String?) : null;

        if (statusCode == 401) {
          return const LlamaNetworkException(
            'Session expired. Please log in again.',
          );
        }
        if (statusCode == 402 || statusCode == 429) {
          return LlamaNetworkException(
            errMsg ??
                (statusCode == 402
                    ? 'Daily free scan limit reached. Upgrade to Premium for 10 daily scans!'
                    : 'Daily scan limit reached. Scans reset at midnight UTC.'),
          );
        }
        if (statusCode == 422) {
          return LlamaNetworkException(
            errMsg ?? 'No food or beverage was detected in the photo. Please try a clear photo of your meal.',
          );
        }
        if (statusCode == 502 || statusCode == 504) {
          return LlamaNetworkException(
            errMsg ?? 'Meal analysis service is temporarily unavailable. Please try again shortly.',
            isTimeout: statusCode == 504,
          );
        }
        return LlamaNetworkException(
          errMsg ?? 'Unable to analyze image. Please try again.',
        );
      default:
        return const LlamaNetworkException(
          'Network connection error. Please check your internet connection.',
        );
    }
  }
}

// ── Network-Layer Exception ───────────────────────────────────

class LlamaNetworkException implements Exception {
  final String message;
  final bool isTimeout;
  final bool isConnectionError;

  const LlamaNetworkException(
    this.message, {
    this.isTimeout        = false,
    this.isConnectionError = false,
  });

  @override
  String toString() => 'LlamaNetworkException: $message';
}
