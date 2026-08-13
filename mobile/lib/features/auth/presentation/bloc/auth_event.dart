// lib/features/auth/presentation/bloc/auth_event.dart
// Aura — Auth Events

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class LogoutRequested extends AuthEvent {}

class GoogleSignInSubmitted extends AuthEvent {
  final String? overrideEmail;
  final String? overrideName;

  const GoogleSignInSubmitted({this.overrideEmail, this.overrideName});

  @override
  List<Object?> get props => [overrideEmail, overrideName];
}

class AppleSignInSubmitted extends AuthEvent {}
