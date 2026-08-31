// lib/core/error/failures.dart
// Aura — Failure types for clean architecture

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Network or API errors
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Unable to connect to server. Please try again.',
    super.code = 'SERVER_ERROR',
  });
}

/// No internet / connection issues
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
  });
}

/// Local cache / Hive errors
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Unable to access offline data. Please try again.',
    super.code = 'CACHE_ERROR',
  });
}

/// Auth token missing/expired
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication required. Please log in.',
    super.code = 'AUTH_ERROR',
  });
}

/// Validation failure (client-side)
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Please check your inputs and try again.',
    super.code = 'VALIDATION_ERROR',
  });
}

/// Rate limit exceeded
class RateLimitFailure extends Failure {
  final int? retryAfterSeconds;
  const RateLimitFailure({
    super.message = 'Too many requests. Please wait before trying again.',
    super.code = 'RATE_LIMIT_EXCEEDED',
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [...super.props, retryAfterSeconds];
}
