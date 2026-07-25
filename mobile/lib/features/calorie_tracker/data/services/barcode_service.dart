// lib/features/calorie_tracker/data/services/barcode_service.dart
// Aura — Barcode Dio Network Service
//
// Wraps two endpoints:
//   POST /api/v1/meals/scan-barcode  — lookup by barcode
//   POST /api/v1/meals/log-barcode   — persist confirmed meal
//
// Mirrors LocalLlamaService pattern:
//   • Dedicated Dio instance with JWT interceptor
//   • Standard timeouts (barcode API is fast — 10 s receive)
//   • Typed exceptions: BarcodeNotFoundException, BarcodeNetworkException

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/constants.dart';
import '../models/barcode_product.dart';

class BarcodeService {
  final Dio _dio;

  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);
  static const Duration _sendTimeout    = Duration(seconds: 10);

  BarcodeService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? _buildDio(secureStorage ?? const FlutterSecureStorage());

  static Dio _buildDio(FlutterSecureStorage secureStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl:        AppConstants.apiV1,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout:    _sendTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

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

  // ── Lookup ─────────────────────────────────────────────────

  /// Look up a barcode in Open Food Facts (via backend proxy + cache).
  ///
  /// Throws [BarcodeNotFoundException] if the barcode isn't in the database.
  /// Throws [BarcodeNetworkException] on connectivity / server errors.
  Future<BarcodeProduct> lookupBarcode(String barcode) async {
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/meals/scan-barcode',
        data: {'barcode': barcode},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw BarcodeNetworkException('Unexpected error: $e');
    }

    final body = response.data;
    if (body == null || body is! Map<String, dynamic>) {
      throw const BarcodeNetworkException('Server returned an invalid response.');
    }

    if (body['success'] != true) {
      final code = body['code'] as String?;
      final msg  = body['error'] as String? ?? 'Unknown error';
      if (code == 'BARCODE_NOT_FOUND') {
        throw BarcodeNotFoundException(msg);
      }
      throw BarcodeNetworkException(msg);
    }

    final dataJson = body['data'];
    if (dataJson == null || dataJson is! Map<String, dynamic>) {
      throw const BarcodeNetworkException('Server returned malformed data.');
    }

    return BarcodeProduct.fromJson(dataJson);
  }

  // ── Log ────────────────────────────────────────────────────

  /// Persist a confirmed barcode meal to the backend MealLog.
  ///
  /// Returns the new `logId` string.
  /// Throws [BarcodeNetworkException] on failure.
  Future<String> logBarcodeProduct({
    required BarcodeProduct product,
    required double servingGrams,
  }) async {
    final serving = product.forServing(servingGrams);

    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/meals/log-barcode',
        data: {
          'barcode':     product.barcode,
          'productName': product.productName,
          'calories':    serving.calories,
          'protein':     serving.protein,
          'carbs':       serving.carbs,
          'fats':        serving.fats,
          'servingGrams': servingGrams,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw BarcodeNetworkException('Unexpected error: $e');
    }

    final body = response.data;
    if (body == null || body is! Map<String, dynamic> || body['success'] != true) {
      throw BarcodeNetworkException(
        (body is Map ? body['error'] as String? : null) ?? 'Failed to log meal.',
      );
    }

    return (body['data']?['logId'] as String?) ?? '';
  }

  // ── DioException mapper ────────────────────────────────────

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      final errBody    = e.response?.data;
      final code       = errBody is Map ? errBody['code'] as String? : null;
      final msg        = errBody is Map ? errBody['error'] as String? : null;

      if (statusCode == 404 || code == 'BARCODE_NOT_FOUND') {
        return BarcodeNotFoundException(
          msg ?? 'Product not found in barcode database.',
        );
      }
      if (statusCode == 401) {
        return const BarcodeNetworkException('Authentication failed. Please log in again.');
      }
      if (statusCode == 429) {
        return const BarcodeNetworkException('Too many requests. Please wait a moment.');
      }
      return BarcodeNetworkException(msg ?? 'Server error ($statusCode). Please try again.');
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return const BarcodeNetworkException(
          'Connection timed out. Is the backend running?',
          isTimeout: true,
        );
      case DioExceptionType.receiveTimeout:
        return const BarcodeNetworkException(
          'Barcode lookup timed out. Please try again.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return const BarcodeNetworkException(
          'Cannot reach server. Check your internet connection.',
        );
      default:
        return BarcodeNetworkException('Network error: ${e.message ?? e.type.name}');
    }
  }
}
