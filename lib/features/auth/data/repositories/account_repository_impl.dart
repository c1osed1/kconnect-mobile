import '../../domain/repositories/account_repository.dart';
import '../../domain/models/account.dart';
import '../../../../services/storage_service.dart';

class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async {
    return StorageService.getAccounts();
  }

  @override
  Future<void> saveAccounts(List<Account> accounts) async {
    await StorageService.saveAccounts(accounts);
  }

  @override
  Future<Account?> getActiveAccount() async {
    return StorageService.getActiveAccount();
  }

  @override
  Future<void> setActiveAccount(Account? account) async {
    await StorageService.setActiveAccountIndex(account?.index);
  }

  @override
  Future<void> addAccount(Account account) async {
    await StorageService.addAccount(account);
  }

  @override
  Future<void> removeAccount(String accountId) async {
    await StorageService.removeAccount(accountId);
  }

  @override
  Future<void> updateAccount(Account account) async {
    await StorageService.updateAccount(account);
  }
}
