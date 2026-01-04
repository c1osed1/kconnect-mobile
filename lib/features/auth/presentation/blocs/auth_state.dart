/// Состояния BLoC для аутентификации
///
/// Определяет все возможные состояния процесса аутентификации,
/// включая состояния загрузки, успеха и ошибок.
library ;

import 'package:equatable/equatable.dart';
import '../../domain/models/auth_user.dart';

/// Базовый класс для всех состояний аутентификации
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthRegistrationCompleted extends AuthState {
  final String message;

  const AuthRegistrationCompleted(this.message);

  @override
  List<Object> get props => [message];
}
