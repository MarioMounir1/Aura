import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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
    final results = await Future.wait<bool>([
      _authRepository.checkAuthStatus(),
      _authRepository.isUserPremium(),
    ]);
    final isAuthenticated = results[0];
    final isPremium = results[1];

    if (isAuthenticated) {
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
      GoogleSignInAccount? account;
      String? lastError;

      // 1. Primary: Standard native device Google Sign-In
      try {
        final stdGoogleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        account = await stdGoogleSignIn.signIn();
      } catch (stdErr) {
        debugPrint('⚠️ Standard Google Sign-In error: $stdErr');
        lastError = stdErr.toString();
      }

      // 2. Fallback: Server Client ID configuration
      if (account == null) {
        try {
          final serverGoogleSignIn = GoogleSignIn(
            serverClientId: '1033397128754-5pem7d2oqj1h9e6ds8ifdmf91m6mt426.apps.googleusercontent.com',
            scopes: ['email', 'profile'],
          );
          account = await serverGoogleSignIn.signIn();
        } catch (serverErr) {
          debugPrint('⚠️ Server Google Sign-In error: $serverErr');
          lastError ??= serverErr.toString();
        }
      }

      if (account == null) {
        if (lastError != null &&
            !lastError.contains('canceled') &&
            !lastError.contains('cancelled') &&
            !lastError.contains('CLOSED')) {
          emit(AuthFailure('Google sign-in error: $lastError'));
        } else {
          emit(Unauthenticated());
        }
        return;
      }

      GoogleSignInAuthentication? authentication;
      try {
        authentication = await account.authentication;
      } catch (e) {
        debugPrint('⚠️ Could not get Google authentication tokens: $e');
      }

      final idToken = authentication?.idToken;

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
      debugPrint('❌ Google sign-in exception: $e');
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
