// lib/features/auth/presentation/bloc/auth_bloc.dart
// Calc-Calories — Auth BLoC

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    final isAuthenticated = await _authRepository.checkAuthStatus();
    if (isAuthenticated) {
      final isPremium = await _authRepository.isUserPremium();
      emit(Authenticated(token: '', isPremium: isPremium));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.login(
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async => emit(AuthFailure(failure.message)),
      (token) async {
        final isPremium = await _authRepository.isUserPremium();
        emit(Authenticated(token: token, isPremium: isPremium));
      },
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.register(
      name: event.name,
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async => emit(AuthFailure(failure.message)),
      (token) async {
        final isPremium = await _authRepository.isUserPremium();
        emit(Authenticated(token: token, isPremium: isPremium));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
