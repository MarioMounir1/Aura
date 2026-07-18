// lib/features/auth/presentation/bloc/auth_bloc.dart
// Calc-Calories — Auth BLoC

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    on<GoogleSignInSubmitted>(_onGoogleSignInSubmitted);
    on<AppleSignInSubmitted>(_onAppleSignInSubmitted);
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

  Future<void> _onGoogleSignInSubmitted(
    GoogleSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        emit(const AuthFailure('Google sign in was cancelled.'));
        return;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      final result = await _authRepository.loginWithGoogle(
        googleId: account.id,
        email: account.email,
        name: account.displayName ?? 'Google User',
        idToken: idToken,
      );

      await result.fold(
        (failure) async => emit(AuthFailure(failure.message)),
        (token) async {
          final isPremium = await _authRepository.isUserPremium();
          emit(Authenticated(token: token, isPremium: isPremium));
        },
      );
    } catch (e) {
      emit(AuthFailure('Google sign in error: ${e.toString()}'));
    }
  }

  Future<void> _onAppleSignInSubmitted(
    AppleSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final email = credential.email ?? '';
      final givenName = credential.givenName ?? '';
      final familyName = credential.familyName ?? '';
      final name = givenName.isNotEmpty ? '$givenName $familyName'.trim() : 'Apple User';

      final result = await _authRepository.loginWithApple(
        appleId: credential.userIdentifier ?? '',
        email: email,
        name: name,
        identityToken: credential.identityToken,
      );

      await result.fold(
        (failure) async => emit(AuthFailure(failure.message)),
        (token) async {
          final isPremium = await _authRepository.isUserPremium();
          emit(Authenticated(token: token, isPremium: isPremium));
        },
      );
    } catch (e) {
      emit(AuthFailure('Apple sign in error: ${e.toString()}'));
    }
  }
}
