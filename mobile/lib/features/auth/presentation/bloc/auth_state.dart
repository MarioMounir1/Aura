// lib/features/auth/presentation/bloc/auth_state.dart
// Calc-Calories — Auth States

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

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
