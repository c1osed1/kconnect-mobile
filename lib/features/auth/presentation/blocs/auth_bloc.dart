import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/core/theme/presentation/blocs/theme_bloc.dart';
import 'package:kconnect_mobile/core/theme/presentation/blocs/theme_event.dart';
import 'package:kconnect_mobile/features/auth/domain/models/account.dart';
import 'package:kconnect_mobile/features/auth/domain/models/auth_user.dart';
import 'package:kconnect_mobile/features/auth/domain/repositories/account_repository.dart';
import 'package:kconnect_mobile/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:kconnect_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kconnect_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kconnect_mobile/features/auth/domain/usecases/register_profile_usecase.dart';
import 'package:kconnect_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_event.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_register_handler.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';
import 'package:kconnect_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:kconnect_mobile/routes/app_router.dart';
import 'package:kconnect_mobile/routes/route_names.dart';
import 'package:kconnect_mobile/services/api_client/dio_client.dart';
import 'package:kconnect_mobile/services/data_clear_service.dart';
import 'package:kconnect_mobile/services/storage_service.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';

/// BLoC для управления состоянием аутентификации пользователя
///
/// Отвечает за все операции аутентификации: вход, регистрация, выход,
/// управление множественными аккаунтами и автоматическую синхронизацию данных.
/// Обеспечивает безопасность хранения учетных данных и сессионных ключей.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthUseCase _checkAuthUseCase;
  final LogoutUseCase _logoutUseCase;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final RegisterProfileUseCase _registerProfileUseCase;
  final AccountRepository _accountRepository;
  final ProfileRepository _profileRepository;
  final DataClearService _dataClearService;
  final DioClient _dioClient;
  final ThemeBloc _themeBloc;

  AuthBloc(this._checkAuthUseCase, this._logoutUseCase, this._loginUseCase, this._registerUseCase, this._registerProfileUseCase, this._accountRepository, this._profileRepository, this._dataClearService, this._dioClient, this._themeBloc) : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<RefreshAuthEvent>(_onRefreshAuth);
    on<LogoutEvent>(_onLogout);
    on<LogoutAccountEvent>(_onLogoutAccount);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<AutoLoginEvent>(_onAutoLogin);
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    debugPrint('AuthBloc: State change from ${change.currentState} to ${change.nextState}');
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    debugPrint('AuthBloc: _onCheckAuth called');
    emit(AuthLoading());
    try {
    final user = await _checkAuthUseCase.execute();
    debugPrint('AuthBloc: check auth returned user: $user');
    if (user != null && user.id.isNotEmpty && user.username.isNotEmpty) {
      emit(AuthAuthenticated(user));
      debugPrint('AuthBloc: Emitted AuthAuthenticated with id=${user.id}, username=${user.username}');
    } else if (user != null) {
      emit(AuthError('Некорректные данные пользователя'));
      debugPrint('AuthBloc: Emitted AuthError due to invalid user data');
    } else {
      emit(AuthUnauthenticated());
      debugPrint('AuthBloc: Emitted AuthUnauthenticated');
    }
    } catch (e) {
      emit(AuthError(e.toString()));
      debugPrint('AuthBloc: Emitted AuthError: $e');
    }
  }

  Future<void> _onRefreshAuth(RefreshAuthEvent event, Emitter<AuthState> emit) async {
    debugPrint('AuthBloc: _onRefreshAuth called');
    final currentState = state;
    // Only emit loading if not already authenticated
    if (currentState is! AuthAuthenticated) {
      emit(AuthLoading());
    }
    await _onCheckAuth(CheckAuthEvent(), emit);
    debugPrint('AuthBloc: _onRefreshAuth completed');
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _logoutUseCase.execute();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutAccount(LogoutAccountEvent event, Emitter<AuthState> emit) async {
    try {
      await _accountRepository.removeAccount(event.accountId);

      if (event.isCompleteLogout) {
        await _logoutUseCase.execute();
        emit(AuthUnauthenticated());
      } else {
        final remainingAccounts = await _accountRepository.getAccounts();
        if (remainingAccounts.isEmpty) {
          await _logoutUseCase.execute();
          emit(AuthUnauthenticated());
        } else {
          final activeAccount = await _accountRepository.getActiveAccount();
          if (activeAccount == null && remainingAccounts.isNotEmpty) {
            // Set first remaining account as active
            await _accountRepository.setActiveAccount(remainingAccounts.first);
          }
        }
      }
    } catch (e) {
      emit(AuthError('Failed to logout account: ${e.toString()}'));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final loginResult = await _loginUseCase.call(event.email, event.password);
      if (loginResult['success'] == true) {
        String sessionKey = '';
        if (loginResult['sessionKey'] is String) {
          sessionKey = loginResult['sessionKey'] as String;
        } else if (loginResult['session_key'] is String) {
          sessionKey = loginResult['session_key'] as String;
        }

        if (sessionKey.isNotEmpty) {
          final user = await _checkAuthUseCase.execute();
          if (user != null && user.id.isNotEmpty && user.username.isNotEmpty) {
            final profile = await _profileRepository.fetchCurrentUserProfile(forceRefresh: true);

            final account = Account(
              index: 0,
              id: user.id,
              username: profile.username,
              avatarUrl: profile.avatarUrl ?? user.avatarUrl,
              sessionKey: sessionKey,
              login: event.email,
              password: event.password,
              lastLogin: DateTime.now(),
            );

            debugPrint('AuthBloc: Saving account ${account.username} with session key: ${sessionKey.substring(0, 10)}..., login: ${event.email}');
            await _accountRepository.addAccount(account);

            final accounts = await _accountRepository.getAccounts();
            final savedAccount = accounts.firstWhere(
              (acc) => acc.id == account.id,
              orElse: () => account,
            );

            // Всегда устанавливаем аккаунт как активный (и при первом логине, и при добавлении)
            await _accountRepository.setActiveAccount(savedAccount);

            final completeUser = AuthUser(
              id: user.id,
              username: profile.username,
              email: user.email,
              avatarUrl: profile.avatarUrl ?? user.avatarUrl,
            );

            emit(AuthAuthenticated(completeUser));

            // Полная перезагрузка UI при добавлении нового аккаунта (как при переключении)
            if (event.isAddingAccount) {
              await _performFullUIReload(savedAccount);
            }
          } else {
            emit(AuthError('Failed to get user profile after login'));
          }
        } else {
          emit(AuthError('No session key received from login'));
        }
      } else {
        String errorMsg = 'Login failed';
        final error = loginResult['error'];
        if (error is String) {
          errorMsg = error;
        } else if (error is Map) {
          errorMsg = error['message'] ?? error.toString();
        } else if (error != null) {
          errorMsg = error.toString();
        }
        emit(AuthError(errorMsg));
      }
    } catch (e) {
      emit(AuthError('Network error: ${e.toString()}'));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    final registerHandler = AuthRegisterHandler(_registerUseCase);

    emit(AuthLoading());

    try {
      final newState = await registerHandler.handleRegister(event);
      emit(newState);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAutoLogin(AutoLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final loginResult = await _loginUseCase.call(event.email, event.password);

      if (loginResult['success'] != true) {
        emit(AuthError('Не удалось автоматически войти. Подтвердите email или попробуйте войти вручную.'));
        return;
      }

      final needsProfileSetup = loginResult['needsProfileSetup'] == true;

      if (needsProfileSetup) {
        final profileActivated = await _registerProfileUseCase.call();

        if (!profileActivated) {
          emit(AuthError('Регистрация успешна, но не удалось активировать профиль. Войдите повторно.'));
          return;
        }
      }

      final user = await _checkAuthUseCase.execute();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Ошибка получения данных пользователя'));
      }

    } catch (e) {
      emit(AuthError('Произошла ошибка при автоматическом входе: ${e.toString()}'));
    }
  }

  /// Полная перезагрузка ui
  Future<void> _performFullUIReload(Account newAccount) async {
    debugPrint('AuthBloc: Performing full UI reload for new account ${newAccount.username}...');

    try {
      debugPrint('AuthBloc: Clearing user data for new account');
      _dataClearService.clearUserDataForAccountSwitch();

      if (newAccount.sessionKey != null) {
        await _dioClient.saveSession(newAccount.sessionKey!);
        debugPrint('AuthBloc: Saved session for ${newAccount.username}');
      }

      debugPrint('AuthBloc: Fetching profile color for ${newAccount.username}...');
      await _updateProfileColor(newAccount);

      debugPrint('AuthBloc: Triggering data reload for all features...');
      _dataClearService.clearUserDataForAccountSwitch();

      debugPrint('AuthBloc: Restarting app to fully reload UI with new account data...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            RouteNames.splash, (route) => false);
      });

    } catch (e) {
      debugPrint('AuthBloc: Error during full UI reload: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            RouteNames.splash, (route) => false);
      });
    }
  }

  Future<void> _updateProfileColor(Account account) async {
    final useProfileAccent = await StorageService.getUseProfileAccentColor();
    debugPrint('AuthBloc: Personalization enabled: $useProfileAccent');

    if (useProfileAccent) {
      try {
        final profileResponse = await _dioClient.get('/api/profile/${account.username}');
        debugPrint('AuthBloc: Profile API response status: ${profileResponse.statusCode}');

        if (profileResponse.statusCode == 200) {
          final profileData = profileResponse.data;
          debugPrint('AuthBloc: Profile data received: ${profileData['user'] != null ? 'has user data' : 'no user data'}');

          if (profileData['user'] != null) {
            final profileColor = profileData['user']['profile_color'];
            debugPrint('AuthBloc: Raw profile_color from API: $profileColor');

            if (profileColor != null && profileColor.toString().isNotEmpty) {
              final colorString = profileColor.toString();
              await StorageService.setSavedAccentColor(colorString);

              try {
                final materialColor = _createMaterialColor(colorString);
                AppColors.updateFromMaterialColor(materialColor);
                debugPrint('AuthBloc: Updated AppColors with profile color $colorString for ${account.username}');
              } catch (e) {
                debugPrint('AuthBloc: Failed to create MaterialColor from $colorString');
              }

              _themeBloc.add(UpdateAccentColorStateEvent(colorString));
              debugPrint('AuthBloc: Triggered ThemeBloc state update with profile color $colorString for ${account.username}');

              debugPrint('AuthBloc: Saved profile color $colorString for ${account.username}');
            } else {
              await StorageService.setSavedAccentColor(null);
              _themeBloc.add(UpdateAccentColorStateEvent(null));
              debugPrint('ℹAuthBloc: Profile has no color, cleared saved color and updated ThemeBloc');
            }
          } else {
            debugPrint('AuthBloc: Profile response missing user data');
          }
        } else {
          debugPrint('AuthBloc: Failed to fetch profile for color, status: ${profileResponse.statusCode}');
        }
      } catch (e) {
        debugPrint('AuthBloc: Error fetching profile color: $e');
      }
    }
  }

  static MaterialColor _createMaterialColor(String hexColor) {
    final hexColorSanitized = hexColor.replaceFirst('#', '');

    final colorInt = int.parse(hexColorSanitized, radix: 16);

    final color = Color(colorInt | 0xFF000000);

    // Генерация оттенков для Material color
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
