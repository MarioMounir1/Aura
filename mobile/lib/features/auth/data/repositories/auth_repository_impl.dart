// lib/features/auth/data/repositories/auth_repository_impl.dart
// Calc-Calories — Auth Repository Implementation

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';

import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

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

      final authResponse = AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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

      final authResponse = AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> logout() async {
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
      final response = await _apiClient.dio.post(
        '/auth/google',
        data: {
          'googleId': googleId,
          'email': email,
          'name': name,
          'idToken': idToken,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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

      final authResponse = AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      await _apiClient.saveToken(authResponse.token);
      await _apiClient.saveIsPremium(authResponse.user.isPremium);

      return Right(authResponse.token);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final serverMessage =
        responseData is Map ? responseData['error'] as String? : null;

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }

    if (statusCode == 409) {
      return ValidationFailure(message: serverMessage ?? 'Email already registered.');
    }

    if (statusCode == 401) {
      return ValidationFailure(message: serverMessage ?? 'Invalid email or password.');
    }

    return ServerFailure(
      message: serverMessage ?? 'An authentication error occurred.',
      code: statusCode?.toString(),
    );
  }
}
