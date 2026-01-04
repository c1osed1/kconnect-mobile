/// События для управления состоянием аккаунтов в BLoC
///
/// Определяет все возможные события, которые могут происходить
/// с управлением аккаунтами пользователей (загрузка, переключение, добавление и т.д.).
library;

import 'package:equatable/equatable.dart';
import '../../domain/models/account.dart';

/// Базовый класс для всех событий управления аккаунтами
abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object> get props => [];
}

class LoadAccountsEvent extends AccountEvent {}

class SetActiveAccountEvent extends AccountEvent {
  final Account? account;

  const SetActiveAccountEvent(this.account);

  @override
  List<Object> get props => [account ?? ''];
}

class SwitchAccountEvent extends AccountEvent {
  final Account targetAccount;

  const SwitchAccountEvent(this.targetAccount);

  @override
  List<Object> get props => [targetAccount];
}

class AddAccountEvent extends AccountEvent {
  final Account account;

  const AddAccountEvent(this.account);

  @override
  List<Object> get props => [account];
}

class RemoveAccountEvent extends AccountEvent {
  final String accountId;

  const RemoveAccountEvent(this.accountId);

  @override
  List<Object> get props => [accountId];
}

class UpdateAccountEvent extends AccountEvent {
  final Account account;

  const UpdateAccountEvent(this.account);

  @override
  List<Object> get props => [account];
}
