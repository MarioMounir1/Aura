// lib/core/error/error_handler.dart
// Aura — Centralized User-Friendly Error Handling & Messaging

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'failures.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Converts any exception, Dio error, failure, or raw error into a concise,
  /// reassuring, and clear 1-sentence user-facing message.
  static String getUserMessage(dynamic error, [String? fallback]) {
    if (error == null) {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    // 1. Clean Failure objects
    if (error is Failure) {
      return _cleanMessage(error.message, fallback);
    }

    // 2. Dio / Network Errors
    if (error is DioException) {
      return _handleDioError(error, fallback);
    }

    // 3. Socket / Offline Connection
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    // 4. Timeout Exception
    if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    }

    // 5. Platform Exception (Purchases, camera, sensors)
    if (error is PlatformException) {
      return _handlePlatformError(error, fallback);
    }

    // 6. Generic string or Exception
    final rawString = error.toString().trim();
    return _interpretRawMessage(rawString, fallback);
  }

  /// Domain-aware message interpreter for string/exception representations
  static String _interpretRawMessage(String raw, String? fallback) {
    final lower = raw.toLowerCase();

    // Specific domain errors (scanning, food detection, barcode)
    if (lower.contains('no_food_detected') || lower.contains('no food or beverage')) {
      return 'No food or beverage was detected. Please make sure the meal is clearly visible and try again.';
    }

    if (lower.contains('barcode_not_found') || lower.contains('product not found')) {
      return 'Product not found in the barcode database. You can enter the name to estimate nutrition.';
    }

    if (lower.contains('quota_exceeded') || lower.contains('free limit reached') || lower.contains('premium limit reached')) {
      if (lower.contains('free')) {
        return 'Daily free scan limit reached. Upgrade to Premium for 10 daily scans!';
      }
      return 'Daily scan limit reached. Scans reset at midnight UTC.';
    }

    if (lower.contains('port 3000') || lower.contains('node.js') || lower.contains('is the backend running') || lower.contains('cannot reach local server')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    if (lower.contains('socketexception') || lower.contains('failed host lookup') || lower.contains('connection refused')) {
      return 'Network connection error. Please check your internet connection.';
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    return _cleanMessage(raw, fallback);
  }

  /// Internal Dio error interpreter
  static String _handleDioError(DioException error, String? fallback) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        // Extract server-provided message if clean
        if (responseData is Map<String, dynamic>) {
          final serverMsg = responseData['message'] ?? responseData['error'];
          if (serverMsg is String && serverMsg.isNotEmpty && !_isTechnicalNoise(serverMsg)) {
            return _interpretRawMessage(serverMsg, fallback);
          }
        }

        if (statusCode != null) {
          if (statusCode == 400) {
            return 'Invalid request. Please verify your details.';
          } else if (statusCode == 401) {
            return 'Session expired. Please log in again.';
          } else if (statusCode == 402 || statusCode == 429) {
            return 'Daily scan limit reached. Please upgrade or try again tomorrow.';
          } else if (statusCode == 403) {
            return 'You do not have permission to perform this action.';
          } else if (statusCode == 404) {
            return 'The requested information could not be found.';
          } else if (statusCode == 422) {
            return 'No food or beverage was detected. Please scan a clear photo of your meal.';
          } else if (statusCode >= 500) {
            return 'Service is temporarily busy. Please try again shortly.';
          }
        }
        return fallback ?? 'Something went wrong. Please try again.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badCertificate:
        return 'Secure connection could not be established.';

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return 'No internet connection. Please check your network.';
        }
        return fallback ?? 'Something went wrong. Please try again.';
    }
  }

  /// Internal Platform error interpreter
  static String _handlePlatformError(PlatformException error, String? fallback) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code.contains('purchase') || message.contains('purchase') || message.contains('offerings')) {
      if (message.contains('cancel') || code.contains('cancel')) {
        return 'Purchase cancelled.';
      }
      return 'Unable to complete purchase. Please try again.';
    }

    if (code.contains('camera') || message.contains('camera') || message.contains('permission')) {
      return 'Camera permission is required to scan meals and barcodes.';
    }

    if (code.contains('network') || message.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    return fallback ?? 'Something went wrong. Please try again.';
  }

  /// Filters out technical stack traces, JSON blobs, or "Exception:" prefixes
  static String _cleanMessage(String raw, String? fallback) {
    var msg = raw.trim();

    // Strip common Dart prefixes
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length).trim();
    }
    if (msg.startsWith('Error: ')) {
      msg = msg.substring('Error: '.length).trim();
    }
    if (msg.startsWith('DioException: ')) {
      msg = msg.substring('DioException: '.length).trim();
    }

    // If it looks like a stack trace or raw JSON/backend status dump, return friendly fallback
    if (_isTechnicalNoise(msg)) {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    // Capitalize first letter and ensure ending punctuation
    if (msg.isNotEmpty) {
      msg = msg[0].toUpperCase() + msg.substring(1);
      if (!msg.endsWith('.') && !msg.endsWith('!') && !msg.endsWith('?')) {
        msg = '$msg.';
      }
      return msg;
    }

    return fallback ?? 'Something went wrong. Please try again.';
  }

  static bool _isTechnicalNoise(String text) {
    final lower = text.toLowerCase();
    return lower.contains('stack trace') ||
        lower.contains('status code') ||
        lower.contains('syntaxerror') ||
        lower.contains('dioexception') ||
        lower.contains('http/1.1') ||
        lower.contains('unhandled exception') ||
        lower.contains('nullcheckoperator') ||
        lower.contains('rangeerror') ||
        lower.contains('node.js') ||
        lower.contains('port 3000') ||
        lower.contains('10.0.2.2') ||
        lower.contains('localhost') ||
        lower.contains('prisma') ||
        lower.contains('{') && lower.contains('}') ||
        text.length > 200;
  }

  /// Shows a clean, polished, floating SnackBar with Aura design tokens
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? fallback,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    final message = getUserMessage(error, fallback);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2620),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF35453A), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: const Color(0xFF4CAF50),
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
