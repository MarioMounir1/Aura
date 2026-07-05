// lib/core/error/failures.dart
// Calc-Calories — Failure types for clean architecture

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
  const ServerFailure({required super.message, super.code});
}

/// No internet / connection issues
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection. Please check your network.', super.code = 'NETWORK_ERROR'});
}

/// Local cache / Hive errors
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code = 'CACHE_ERROR'});
}

/// Auth token missing/expired
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication required. Please log in.', super.code = 'AUTH_ERROR'});
}

/// Validation failure (client-side)
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'VALIDATION_ERROR'});
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
