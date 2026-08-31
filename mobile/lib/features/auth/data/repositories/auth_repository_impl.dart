import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final FirebaseAuthService _firebaseAuthService;

  AuthRepositoryImpl(
    this._apiClient, {
    FirebaseAuthService? firebaseAuthService,
  }) : _firebaseAuthService =
           firebaseAuthService ?? FirebaseAuthService.instance;

  Future<void> _cacheUser(Map<String, dynamic>? userJson) async {
    if (userJson == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = userJson['id'] as String? ?? '';
      if (userId.isNotEmpty) {
        await prefs.setString('cached_user_profile_$userId', jsonEncode(userJson));
      }
      await prefs.setString('cached_user_profile', jsonEncode(userJson));

      final age = userJson['age'];
      final weight = userJson['weightKg'];
      final height = userJson['heightCm'];
      final isCompleted = (age != null && weight != null && height != null);
      if (userId.isNotEmpty) {
        await prefs.setBool('onboarding_completed_$userId', isCompleted);
      }
      await prefs.setBool('onboarding_completed', isCompleted);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, String>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final authRequest = AuthRequest(name: name, email: email, password: password);
      final response = await _apiClient.dio.post(
        '/auth/signup',
        data: authRequest.toJson(),
      );

      final responseData = response.data['data'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(responseData);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveUserId(authResponse.user.id);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);
      await _cacheUser(responseData['user'] as Map<String, dynamic>?);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: AppErrorHandler.getUserMessage(e, 'Unable to create account. Please try again.')));
    }
  }

  @override
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authRequest = AuthRequest(email: email, password: password);
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: authRequest.toJson(),
      );

      final responseData = response.data['data'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(responseData);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveUserId(authResponse.user.id);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);
      await _cacheUser(responseData['user'] as Map<String, dynamic>?);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: AppErrorHandler.getUserMessage(e, 'Unable to sign in. Please try again.')));
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuthService.signOut();
    await _apiClient.clearAuth();
  }

  @override
  Future<bool> checkAuthStatus() async {
    return await _apiClient.isAuthenticated();
  }

  @override
  Future<bool> isUserPremium() async {
    return await _apiClient.getIsPremium();
  }

  @override
  Future<Either<Failure, String>> loginWithGoogle({
    required String googleId,
    required String email,
    required String name,
    String? idToken,
  }) async {
    try {
      // Step 1: Sign in through Firebase to get a verified ID token
      final result = await _firebaseAuthService.signInWithGoogle();
      if (result == null) {
        return const Left(ServerFailure(message: 'Google Sign-In was cancelled.'));
      }

      // Step 2: Send Firebase-verified token + user info to our backend
      final response = await _apiClient.dio.post(
        '/auth/google',
        data: {
          'googleId': result.googleId,
          'email': result.email,
          'name': result.name,
          'idToken': result.idToken,
          'firebaseUid': result.firebaseUid,
        },
      );

      final responseData = response.data['data'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(responseData);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveUserId(authResponse.user.id);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);
      await _cacheUser(responseData['user'] as Map<String, dynamic>?);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(
        message: AppErrorHandler.getUserMessage(e, 'Google sign in could not be completed.'),
        code: 'GOOGLE_SIGN_IN_ERROR',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> loginWithApple({
    required String appleId,
    required String email,
    required String name,
    String? identityToken,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/apple',
        data: {
          'appleId': appleId,
          'email': email,
          'name': name,
          'identityToken': identityToken,
        },
      );

      final responseData = response.data['data'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(responseData);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveUserId(authResponse.user.id);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);
      await _cacheUser(responseData['user'] as Map<String, dynamic>?);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: AppErrorHandler.getUserMessage(e, 'Apple sign in could not be completed.')));
    }
  }

  @override
  Future<Either<Failure, String>> requestPasswordResetOtp(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
      );
      final message = (response.data is Map ? response.data['message'] : null) as String? ??
          'A verification code has been sent to your email.';
      return Right(message);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: AppErrorHandler.getUserMessage(e, 'Unable to request password reset code.')));
    }
  }

  @override
  Future<Either<Failure, String>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/reset-password',
        data: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        },
      );
      final message = (response.data is Map ? response.data['message'] : null) as String? ??
          'Password has been successfully reset.';
      return Right(message);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: AppErrorHandler.getUserMessage(e, 'Unable to reset password.')));
    }
  }

  Failure _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final cleanMessage = AppErrorHandler.getUserMessage(e);

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }

    if (statusCode == 409) {
      return ValidationFailure(message: cleanMessage.contains('conflict') ? 'An account with this email already exists.' : cleanMessage);
    }

    if (statusCode == 401) {
      return ValidationFailure(message: cleanMessage.contains('expired') ? 'Invalid email or password.' : cleanMessage);
    }

    return ServerFailure(
      message: cleanMessage,
      code: statusCode?.toString(),
    );
  }
}
