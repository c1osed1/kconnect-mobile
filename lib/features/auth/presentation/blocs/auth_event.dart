/// События для управления аутентификацией в BLoC
///
/// Определяет все возможные события, которые могут происходить
/// в процессе аутентификации пользователей (вход, регистрация, выход).
library;

import 'package:equatable/equatable.dart';

/// Базовый класс для всех событий аутентификации
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthEvent extends AuthEvent {}

class RefreshAuthEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final bool isAddingAccount;

  const LoginEvent(this.email, this.password, {this.isAddingAccount = false});

  @override
  List<Object> get props => [email, password, isAddingAccount];
}

class RegisterEvent extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String name;

  const RegisterEvent(this.username, this.email, this.password, this.name);

  @override
  List<Object> get props => [username, email, password, name];
}

class AutoLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AutoLoginEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class LogoutAccountEvent extends AuthEvent {
  final String accountId;
  final bool isCompleteLogout;

  const LogoutAccountEvent(this.accountId, {this.isCompleteLogout = false});

  @override
  List<Object> get props => [accountId, isCompleteLogout];
}
