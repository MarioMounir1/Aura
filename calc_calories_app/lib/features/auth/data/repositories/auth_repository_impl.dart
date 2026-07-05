// lib/features/auth/data/repositories/auth_repository_impl.dart
// Calc-Calories — Auth Repository Implementation

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';

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
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final token = response.data['data']['token'] as String;
      await _apiClient.saveToken(token);

      return Right(token);
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
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['data']['token'] as String;
      await _apiClient.saveToken(token);

      return Right(token);
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
