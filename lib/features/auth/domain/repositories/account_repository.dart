/// Репозиторий для управления аккаунтами пользователей
///
/// Определяет интерфейс для работы с локальным хранилищем аккаунтов.
/// Обеспечивает сохранение и загрузку данных о множественных аккаунтах.
library;

import '../models/account.dart';

/// Абстрактный репозиторий для управления аккаунтами пользователей
///
/// Предоставляет методы для CRUD операций с аккаунтами, включая
/// установку активного аккаунта и управление списком сохраненных аккаунтов.
abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<void> saveAccounts(List<Account> accounts);
  Future<Account?> getActiveAccount();
  Future<void> setActiveAccount(Account? account);
  Future<void> addAccount(Account account);
  Future<void> removeAccount(String accountId);
  Future<void> updateAccount(Account account);
}
