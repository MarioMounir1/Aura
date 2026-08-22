import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    ApiClient.onUnauthorized = () {
      if (!isClosed) {
        add(LogoutRequested());
      }
    };

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
      String? googleId;
      String? idToken;
      String? email = event.overrideEmail;
      String? name = event.overrideName;

      if (email == null || email.trim().isEmpty) {
        GoogleSignInAccount? account;

        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        try {
          await googleSignIn.signOut();
        } catch (_) {}

        try {
          account = await googleSignIn.signIn();
        } catch (signInErr) {
          debugPrint('⚠️ Google Sign-In error: $signInErr');
          emit(AuthFailure('Google Sign-In error: ${signInErr.toString()}'));
          return;
        }

        if (account != null) {
          googleId = account.id;
          email = account.email;
          name = (account.displayName != null && account.displayName!.trim().isNotEmpty)
              ? account.displayName!.trim()
              : 'Google User';
          try {
            final auth = await account.authentication;
            idToken = auth.idToken;
            debugPrint('✅ Google Sign-In account: $email (has idToken: ${idToken != null})');
          } catch (authErr) {
            debugPrint('⚠️ Google Auth token extraction warning: $authErr');
          }
        }
      }

      if (email == null || email.trim().isEmpty) {
        debugPrint('⚠️ Google Sign-In was cancelled by user.');
        emit(Unauthenticated());
        return;
      }

      googleId ??= 'google_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      name ??= 'Google User';

      debugPrint('🚀 Sending Google login request to backend: $email');

      final result = await _authRepository.loginWithGoogle(
        googleId: googleId,
        email: email.trim().toLowerCase(),
        name: name,
        idToken: idToken,
      );

      await result.fold(
        (failure) async {
          debugPrint('❌ Google login backend failed: ${failure.message}');
          emit(AuthFailure(failure.message));
        },
        (token) async {
          debugPrint('🎉 Google login authenticated successfully!');
          final isPremium = await _authRepository.isUserPremium();
          emit(Authenticated(token: token, isPremium: isPremium));
        },
      );
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
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
