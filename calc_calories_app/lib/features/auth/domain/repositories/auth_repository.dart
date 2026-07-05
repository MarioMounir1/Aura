// lib/features/auth/domain/repositories/auth_repository.dart
// Calc-Calories — Auth Repository Interface

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  /// Register a new user
  Future<Either<Failure, String>> register({
    required String name,
    required String email,
    required String password,
  });

  /// Login with email and password
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  });

  /// Logout and clear tokens
  Future<void> logout();

  /// Check if user is currently logged in
  Future<bool> checkAuthStatus();

  /// Check if the authenticated user is premium
  Future<bool> isUserPremium();
}
