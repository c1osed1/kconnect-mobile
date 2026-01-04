/// Состояния BLoC для управления аккаунтами
///
/// Определяет все возможные состояния управления аккаунтами пользователей,
/// включая состояния загрузки, переключения и ошибок.
library;

import 'package:equatable/equatable.dart';
import '../../domain/models/account.dart';

/// Базовый класс для всех состояний управления аккаунтами
abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object> get props => [];
}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountSwitching extends AccountState {
  final Account? fromAccount;
  final Account toAccount;

  const AccountSwitching(this.fromAccount, this.toAccount);

  @override
  List<Object> get props => [fromAccount ?? '', toAccount];
}

class AccountLoaded extends AccountState {
  final List<Account> accounts;
  final Account? activeAccount;

  const AccountLoaded(this.accounts, this.activeAccount);

  @override
  List<Object> get props => [accounts, activeAccount ?? ''];
}



class AccountSwitched extends AccountState {
  final Account activeAccount;

  const AccountSwitched(this.activeAccount);

  @override
  List<Object> get props => [activeAccount];
}

class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object> get props => [message];
}
