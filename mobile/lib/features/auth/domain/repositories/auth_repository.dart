// lib/features/auth/domain/repositories/auth_repository.dart
// Aura — Auth Repository Interface

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

  /// Login with Google
  Future<Either<Failure, String>> loginWithGoogle({
    required String googleId,
    required String email,
    required String name,
    String? idToken,
  });

  /// Login with Apple
  Future<Either<Failure, String>> loginWithApple({
    required String appleId,
    required String email,
    required String name,
    String? identityToken,
  });

  /// Request a 6-digit OTP code for password reset
  Future<Either<Failure, String>> requestPasswordResetOtp(String email);

  /// Reset password using OTP code and new password
  Future<Either<Failure, String>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  });
}
