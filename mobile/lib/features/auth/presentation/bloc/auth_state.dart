// lib/features/auth/presentation/bloc/auth_state.dart
// Aura — Auth States

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String token;
  final bool isPremium;

  const Authenticated({required this.token, required this.isPremium});

  @override
  List<Object?> get props => [token, isPremium];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  final String? code;
  final String? details;

  const AuthFailure(this.message, {this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];
}

