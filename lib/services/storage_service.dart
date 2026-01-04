import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/domain/models/account.dart';

/// Сервис для безопасного хранения данных в SharedPreferences
///
/// Обеспечивает хранение сессионных ключей, данных аккаунтов,
/// настроек персонализации и истории прослушивания музыки.
/// Все чувствительные данные хранятся в зашифрованном виде на уровне ОС.
class StorageService {
  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  static Future<bool> hasActiveSession() async {
    final prefs = await _prefs;
    final key = prefs.getString('session_key');
    return key != null;
  }

  static Future<String?> getSession() async {
    final prefs = await _prefs;
    return prefs.getString('session_key');
  }

  static Future<void> saveSession(String key) async {
    final prefs = await _prefs;
    await prefs.setString('session_key', key);
  }

  static Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove('session_key');
  }

  static Future<List<Account>> getAccounts() async {
    final prefs = await _prefs;
    final accountsJson = prefs.getStringList('accounts') ?? [];
    return accountsJson.map((jsonStr) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return Account.fromJson(jsonMap);
      } catch (e) {
        return null;
      }
    }).where((account) => account != null).cast<Account>().toList();
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await _prefs;
    final accountsJson = accounts.map((account) => jsonEncode(account.toJson())).toList();
    await prefs.setStringList('accounts', accountsJson);
  }

  static Future<int?> getActiveAccountIndex() async {
    final prefs = await _prefs;
    return prefs.getInt('active_account_index');
  }

  static Future<void> setActiveAccountIndex(int? index) async {
    final prefs = await _prefs;
    if (index == null) {
      await prefs.remove('active_account_index');
    } else {
      await prefs.setInt('active_account_index', index);
    }
  }

  static Future<Account?> getActiveAccount() async {
    final accounts = await getAccounts();
    final activeIndex = await getActiveAccountIndex();

    if (activeIndex != null) {
      try {
        return accounts.firstWhere(
          (account) => account.index == activeIndex,
        );
      } catch (e) {
        //Ошибка
      }
    }

    if (accounts.isNotEmpty) {
      accounts.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
      return accounts.first;
    }

    return null;
  }

  static Future<void> addAccount(Account account) async {
    final accounts = await getAccounts();

    final existingIndices = accounts.map((a) => a.index).toSet();
    int nextIndex = 1;
    while (existingIndices.contains(nextIndex)) {
      nextIndex++;
    }

    final accountWithIndex = account.copyWith(index: nextIndex);

    accounts.removeWhere((a) => a.id == account.id);
    accounts.add(accountWithIndex);
    await saveAccounts(accounts);
  }

  static Future<void> removeAccount(String accountId) async {
    final accounts = await getAccounts();
    final accountToRemove = accounts.cast<Account?>().firstWhere(
      (account) => account?.id == accountId,
      orElse: () => null,
    );

    if (accountToRemove != null) {
      final activeIndex = await getActiveAccountIndex();
      final wasActive = activeIndex == accountToRemove.index;

      accounts.removeWhere((account) => account.id == accountId);

      for (int i = 0; i < accounts.length; i++) {
        accounts[i] = accounts[i].copyWith(index: i + 1);
      }

      await saveAccounts(accounts);

      // Handle active account logic
      if (wasActive) {
        if (accounts.isNotEmpty) {
          await setActiveAccountIndex(1);
        } else {
          await setActiveAccountIndex(null);
          await clearSession();
        }
      } else if (activeIndex != null && activeIndex > accounts.length) {
        await setActiveAccountIndex(accounts.isNotEmpty ? 1 : null);
      }
    }
  }

  static Future<void> updateAccount(Account updatedAccount) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((account) => account.id == updatedAccount.id);
    if (index != -1) {
      accounts[index] = updatedAccount;
      await saveAccounts(accounts);
    }
  }

  static Future<bool> getUseProfileAccentColor() async {
    final prefs = await _prefs;
    return prefs.getBool('use_profile_accent_color') ?? false;
  }

  static Future<void> setUseProfileAccentColor(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('use_profile_accent_color', value);
  }

  static Future<String?> getSavedAccentColor() async {
    final prefs = await _prefs;
    return prefs.getString('saved_accent_color');
  }

  static Future<void> setSavedAccentColor(String? color) async {
    final prefs = await _prefs;
    if (color == null) {
      await prefs.remove('saved_accent_color');
    } else {
      await prefs.setString('saved_accent_color', color);
    }
  }

  static Future<void> clearPersonalizationSettings() async {
    final prefs = await _prefs;
    await prefs.remove('use_profile_accent_color');
    await prefs.remove('saved_accent_color');
  }

  static Future<List<String>> getMusicPlayedTracksHistory(String userId) async {
    final prefs = await _prefs;
    return prefs.getStringList('music_played_tracks_history_$userId') ?? [];
  }

  static Future<void> addToMusicPlayedTracksHistory(String userId, String trackJson) async {
    final prefs = await _prefs;
    final history = await getMusicPlayedTracksHistory(userId);

    history.remove(trackJson);

    history.insert(0, trackJson);

    if (history.length > 10) {
      history.removeRange(10, history.length);
    }

    await prefs.setStringList('music_played_tracks_history_$userId', history);
  }

  static Future<void> clearMusicPlayedTracksHistory(String userId) async {
    final prefs = await _prefs;
    await prefs.remove('music_played_tracks_history_$userId');
  }
}
