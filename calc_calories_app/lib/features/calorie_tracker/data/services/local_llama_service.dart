// lib/features/calorie_tracker/data/services/local_llama_service.dart
// Calc-Calories — Local Llama Dio Network Service
//
// Handles the multipart/form-data image upload to:
//   POST http://10.0.2.2:3000/api/v1/meals/scan-local
//
// Uses the authenticated ApiClient (injects JWT Bearer token automatically).
// Returns a parsed LlamaMealResponse or throws a typed LlamaApiException.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/constants.dart';
import '../models/llama_meal_response.dart';

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

  // ── Core Upload Method ────────────────────────────────────

  /// Uploads [imageFile] to the local Llama scan endpoint.
  ///
  /// Throws:
  ///   [LlamaApiException]    — on API-level errors (bad payload, model failure)
  ///   [LlamaNetworkException] — on connectivity / timeout issues
  Future<LlamaMealResponse> scanMealImage(File imageFile) async {
    // Validate file exists before sending
    if (!imageFile.existsSync()) {
      throw const LlamaNetworkException('Image file does not exist on device.');
    }

    final fileSize = await imageFile.length();
    if (fileSize > 15 * 1024 * 1024) {
      // 15 MB guard — Ollama vision struggles with very large images
      throw const LlamaNetworkException(
        'Image is too large (max 15 MB). Please use a compressed photo.',
      );
    }

    // Build multipart form data with the "image" field key
    // (matches the backend's upload.middleware field name)
    late final FormData formData;
    try {
      formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'meal_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
    } catch (e) {
      throw LlamaNetworkException('Failed to prepare image for upload: $e');
    }

    // ── POST request with strict error handling ─────────────
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        _endpoint,
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
    } catch (e) {
      throw LlamaNetworkException('Unexpected upload error: $e');
    }

    // ── Parse the JSON response ─────────────────────────────
    final body = response.data;
    if (body == null || body is! Map<String, dynamic>) {
      throw const LlamaApiException(
        'Server returned an empty or non-JSON response.',
      );
    }

    try {
      return LlamaMealResponse.fromJson(body);
    } on LlamaApiException {
      rethrow; // Already typed — pass through
    } catch (e) {
      throw LlamaApiException('Failed to parse Llama response: $e');
    }
  }

  // ── DioException → Typed Exception Mapper ─────────────────

  LlamaNetworkException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return const LlamaNetworkException(
          'Connection to local server timed out. Is the Node.js backend running?',
          isTimeout: true,
        );
      case DioExceptionType.receiveTimeout:
        return const LlamaNetworkException(
          'Local Llama model is taking too long. Try a simpler image or check Ollama.',
          isTimeout: true,
        );
      case DioExceptionType.sendTimeout:
        return const LlamaNetworkException(
          'Image upload timed out. Check your connection to the local server.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const LlamaNetworkException(
          'Cannot reach local server. Make sure the Node.js backend is running on port 3000.',
          isConnectionError: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final errBody    = e.response?.data;
        final errMsg     = errBody is Map ? (errBody['error'] as String?) : null;

        if (statusCode == 401) {
          return const LlamaNetworkException(
            'Authentication failed. Please log in again.',
          );
        }
        if (statusCode == 429) {
          return const LlamaNetworkException(
            'Too many requests. Please wait a moment before scanning again.',
          );
        }
        if (statusCode == 502 || statusCode == 504) {
          return LlamaNetworkException(
            errMsg ?? 'Local Llama model failed to respond. Is Ollama running?',
            isTimeout: statusCode == 504,
          );
        }
        return LlamaNetworkException(
          errMsg ?? 'Server error ($statusCode). Please try again.',
        );
      default:
        return LlamaNetworkException(
          'Network error: ${e.message ?? e.type.name}',
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
