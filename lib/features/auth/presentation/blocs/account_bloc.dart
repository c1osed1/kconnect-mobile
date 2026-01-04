/// BLoC для управления аккаунтами пользователей
///
/// Управляет состоянием множественных аккаунтов, переключением между ними,
/// добавлением и удалением аккаунтов. Включает сложную логику аутентификации
/// и синхронизации данных при переключении аккаунтов.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/models/account.dart';
import '../../../../services/data_clear_service.dart';
import '../../../../services/api_client/dio_client.dart';
import '../../../../services/storage_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../injection.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/route_names.dart';
import '../../../../core/theme/presentation/blocs/theme_bloc.dart';
import '../../../../core/theme/presentation/blocs/theme_event.dart';
import 'account_event.dart';
import 'account_state.dart';

/// BLoC класс для управления аккаунтами пользователей
///
/// Обрабатывает все операции с аккаунтами: загрузка, переключение,
/// добавление, удаление и обновление. Включает сложную логику
/// переключения аккаунтов с сохранением сессий и тем.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;
  final DataClearService _dataClearService;
  final DioClient _dioClient;
  final ThemeBloc _themeBloc;
  final LogoutUseCase _logoutUseCase;

  AccountBloc(this._accountRepository, this._dataClearService, this._dioClient, this._themeBloc, this._logoutUseCase) : super(AccountInitial()) {
    debugPrint('AccountBloc: Initialized successfully');
    on<LoadAccountsEvent>(_onLoadAccounts);
    on<SetActiveAccountEvent>(_onSetActiveAccount);
    on<SwitchAccountEvent>(_onSwitchAccount);
    on<AddAccountEvent>(_onAddAccount);
    on<RemoveAccountEvent>(_onRemoveAccount);
    on<UpdateAccountEvent>(_onUpdateAccount);
  }

  @override
  void onChange(Change<AccountState> change) {
    super.onChange(change);
    debugPrint('AccountBloc: State change from ${change.currentState} to ${change.nextState}');
  }

  Future<void> _onLoadAccounts(LoadAccountsEvent event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    try {
      final accounts = await _accountRepository.getAccounts();
      Account? activeAccount = await _accountRepository.getActiveAccount();

      final currentSession = await StorageService.getSession();
      if (activeAccount != null && currentSession != null && activeAccount.sessionKey != currentSession) {
        try {
          final sessionAccount = accounts.firstWhere(
            (account) => account.sessionKey == currentSession,
          );
          await _accountRepository.setActiveAccount(sessionAccount);
          activeAccount = sessionAccount;
          debugPrint('AccountBloc: Updated active account to match current session: ${activeAccount.username}');
        } catch (e) {
          //Нет активной сессии
        }
      }

      emit(AccountLoaded(accounts, activeAccount));
      debugPrint('AccountBloc: Loaded ${accounts.length} accounts, active: ${activeAccount?.username}');
    } catch (e) {
      emit(AccountError('Failed to load accounts: ${e.toString()}'));
      debugPrint('AccountBloc: Error loading accounts: $e');
    }
  }

  Future<void> _onSetActiveAccount(SetActiveAccountEvent event, Emitter<AccountState> emit) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    try {
      await _accountRepository.setActiveAccount(event.account);
      emit(AccountLoaded(currentState.accounts, event.account));
      debugPrint('AccountBloc: Set active account to ${event.account?.username ?? 'null'}');
    } catch (e) {
      emit(AccountError('Failed to set active account: ${e.toString()}'));
      debugPrint('AccountBloc: Error setting active account: $e');
    }
  }

  Future<void> _onSwitchAccount(SwitchAccountEvent event, Emitter<AccountState> emit) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    final fromAccount = currentState.activeAccount;
    if (fromAccount == null) {
      emit(AccountError('No active account to switch from'));
      return;
    }

    emit(AccountSwitching(fromAccount, event.targetAccount));
    debugPrint('AccountBloc: Switching from ${fromAccount.username} (id: ${fromAccount.id}) to ${event.targetAccount.username} (id: ${event.targetAccount.id})');

    final success = await _performAccountSwitch(event.targetAccount, emit);
    if (!success) {
      emit(AccountLoaded(currentState.accounts, fromAccount));
    }
  }

  /// Предоставляет функционал смены аккаунта
  Future<bool> _performAccountSwitch(Account targetAccount, Emitter<AccountState> emit) async {

    debugPrint(' AccountBloc: Target account has login: ${targetAccount.login != null}, password: ${targetAccount.password != null}');

    try {
      // Отчистка кэша текущей сессии
      debugPrint('AccountBloc: Clearing user data for account switch');
      _dataClearService.clearUserDataForAccountSwitch();

      if (targetAccount.login == null || targetAccount.password == null) {
        debugPrint('AccountBloc: Cannot switch to account without login credentials');
        emit(AccountError('У аккаунта нет сохраненных учетных данных для входа'));
        return false;
      }

      debugPrint('AccountBloc: Performing autologin for ${targetAccount.username}...');

      final authRepository = locator<AuthRepository>();
      final loginResult = await authRepository.login(targetAccount.login!, targetAccount.password!);

      if (loginResult['success'] == true) {
        String newSessionKey = '';
        if (loginResult['sessionKey'] is String) {
          newSessionKey = loginResult['sessionKey'] as String;
        } else if (loginResult['session_key'] is String) {
          newSessionKey = loginResult['session_key'] as String;
        }

        if (newSessionKey.isNotEmpty) {
          final updatedAccount = targetAccount.copyWith(
            sessionKey: newSessionKey,
            lastLogin: DateTime.now(),
          );
          await _accountRepository.updateAccount(updatedAccount);

          await _dioClient.saveSession(newSessionKey);

          // Получение цвета аккаунта
          debugPrint('AccountBloc: Fetching profile color for ${updatedAccount.username}...');

          final useProfileAccent = await StorageService.getUseProfileAccentColor();
          debugPrint('AccountBloc: Personalization enabled: $useProfileAccent');

          if (useProfileAccent) {
            try {
              final profileResponse = await _dioClient.get('/api/profile/${updatedAccount.username}');
              debugPrint('AccountBloc: Profile API response status: ${profileResponse.statusCode}');

              if (profileResponse.statusCode == 200) {
                final profileData = profileResponse.data;
                debugPrint('AccountBloc: Profile data received: ${profileData['user'] != null ? 'has user data' : 'no user data'}');

                if (profileData['user'] != null) {
                  final profileColor = profileData['user']['profile_color'];
                  debugPrint('AccountBloc: Raw profile_color from API: $profileColor');

                  if (profileColor != null && profileColor.toString().isNotEmpty) {
                    final colorString = profileColor.toString();
                    await StorageService.setSavedAccentColor(colorString);

                    try {
                      final materialColor = _createMaterialColor(colorString);
                      AppColors.updateFromMaterialColor(materialColor);
                      debugPrint('AccountBloc: Updated AppColors with profile color $colorString for ${updatedAccount.username}');
                    } catch (e) {
                      debugPrint('AccountBloc: Failed to create MaterialColor from $colorString');
                    }

                    _themeBloc.add(UpdateAccentColorStateEvent(colorString));
                    debugPrint('AccountBloc: Triggered ThemeBloc state update with profile color $colorString for ${updatedAccount.username}');

                    debugPrint('AccountBloc: Saved profile color $colorString for ${updatedAccount.username}');
                  } else {
                    await StorageService.setSavedAccentColor(null);
                    _themeBloc.add(UpdateAccentColorStateEvent(null));
                    debugPrint('AccountBloc: Profile has no color, cleared saved color and updated ThemeBloc');
                  }
                } else {
                  debugPrint('AccountBloc: Profile response missing user data');
                }
              } else {
                debugPrint('AccountBloc: Failed to fetch profile for color, status: ${profileResponse.statusCode}');
              }
            } catch (e) {
              debugPrint('AccountBloc: Error fetching profile color: $e');
            }
          }

          final updatedAccounts = await _accountRepository.getAccounts();
          emit(AccountLoaded(updatedAccounts, updatedAccount));
          debugPrint('AccountBloc: Successfully switched to ${updatedAccount.username} with fresh session key');

          debugPrint('AccountBloc: Triggering data reload for all features...');
          _dataClearService.clearUserDataForAccountSwitch();

          // Ресет ui
          debugPrint('AccountBloc: Restarting app to fully reload UI with new account data...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                RouteNames.splash, (route) => false);
          });

          return true;
        } else {
          debugPrint('AccountBloc: Login successful but no session key received');
          emit(AccountError('Вход выполнен, но не получен ключ сессии'));
          return false;
        }
      } else {
        debugPrint('AccountBloc: Autologin failed');
        final error = loginResult['error'] ?? 'Неизвестная ошибка входа';
        emit(AccountError('Не удалось войти в аккаунт: $error'));
        return false;
      }
    } catch (e) {
      debugPrint('AccountBloc: Error switching account: $e');
      emit(AccountError('Failed to switch account: ${e.toString()}'));
      return false;
    }
  }

  Future<void> _onAddAccount(AddAccountEvent event, Emitter<AccountState> emit) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    try {
      await _accountRepository.addAccount(event.account);
      await _accountRepository.setActiveAccount(event.account);

      debugPrint('AccountBloc: Added account ${event.account.username}, auto-activating...');
      emit(AccountSwitching(currentState.activeAccount, event.account));

      final switchSuccess = await _performAccountSwitch(event.account, emit);

      if (!switchSuccess) {
        emit(AccountLoaded(currentState.accounts, currentState.activeAccount));
        debugPrint('AccountBloc: Account added but auto-activation failed');
      } else {
        debugPrint('AccountBloc: Account added and successfully activated');
      }
    } catch (e) {
      emit(AccountError('Failed to add account: ${e.toString()}'));
      debugPrint('AccountBloc: Error adding account: $e');
    }
  }

  Future<void> _onRemoveAccount(RemoveAccountEvent event, Emitter<AccountState> emit) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    try {
      final isRemovingActiveAccount = currentState.activeAccount?.id == event.accountId;

      await _accountRepository.removeAccount(event.accountId);
      final updatedAccounts = currentState.accounts.where((account) => account.id != event.accountId).toList();

      debugPrint('AccountBloc: Removed account ${event.accountId}, was active: $isRemovingActiveAccount');

      if (isRemovingActiveAccount) {
        if (updatedAccounts.isNotEmpty) {
          final targetAccount = _selectBestAccountToSwitch(updatedAccounts);
          debugPrint('AccountBloc: Switching to account ${targetAccount.username} after removal');

          emit(AccountSwitching(currentState.activeAccount!, targetAccount));
          final switchSuccess = await _performAccountSwitch(targetAccount, emit);

          if (!switchSuccess) {
            emit(AccountLoaded(updatedAccounts, null));
          }
        } else {
          // Если не осталось аккаунтов вернуть на окно входа
          debugPrint('AccountBloc: No accounts left, performing complete logout');

          try {
            await _logoutUseCase.execute();

            // Ресет темы к дефолт значениям
            _themeBloc.add(ResetThemeEvent());
            debugPrint('AccountBloc: Logout completed and theme reset to factory defaults');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  RouteNames.login, (route) => false);
            });

            emit(AccountLoaded([], null));
          } catch (e) {
            debugPrint('AccountBloc: Logout failed: $e');
            emit(AccountError('Failed to logout: ${e.toString()}'));
          }
        }
      } else {
        emit(AccountLoaded(updatedAccounts, currentState.activeAccount));
      }

      debugPrint('AccountBloc: Account removal completed');
    } catch (e) {
      emit(AccountError('Failed to remove account: ${e.toString()}'));
      debugPrint('AccountBloc: Error removing account: $e');
    }
  }

  /// Выбирает аккаунт для перехода
  Account _selectBestAccountToSwitch(List<Account> accounts) {
    // Prefer account with most recent login date
    final sortedAccounts = List<Account>.from(accounts)
      ..sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
    return sortedAccounts.first;
  }

  Future<void> _onUpdateAccount(UpdateAccountEvent event, Emitter<AccountState> emit) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    try {
      await _accountRepository.updateAccount(event.account);
      final updatedAccounts = currentState.accounts.map((account) =>
        account.id == event.account.id ? event.account : account
      ).toList();
      final newActiveAccount = currentState.activeAccount?.id == event.account.id ? event.account : currentState.activeAccount;
      emit(AccountLoaded(updatedAccounts, newActiveAccount));
      debugPrint('AccountBloc: Updated account ${event.account.username}');
    } catch (e) {
      emit(AccountError('Failed to update account: ${e.toString()}'));
      debugPrint('AccountBloc: Error updating account: $e');
    }
  }

  static MaterialColor _createMaterialColor(String hexColor) {
    final hexColorSanitized = hexColor.replaceFirst('#', '');
    final colorInt = int.parse(hexColorSanitized, radix: 16);
    final color = Color(colorInt | 0xFF000000);
    final Map<int, Color> swatch = {};
    final hslColor = HSLColor.fromColor(color);

    for (int i = 1; i <= 9; i++) {
      final lightness = 1.0 - (i * 0.1);
      final shade = hslColor.withLightness(lightness.clamp(0.0, 1.0)).toColor();
      swatch[i * 100] = shade;
    }
    swatch[500] = color;
    final materialColor = MaterialColor(color.toARGB32(), swatch);
    return materialColor;
  }
}
