import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_client/dio_client.dart';
import '../services/data_clear_service.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/repositories/account_repository_impl.dart';
import '../features/auth/domain/usecases/check_auth_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/register_profile_usecase.dart';
import '../features/auth/presentation/blocs/auth_bloc.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../core/theme/presentation/blocs/theme_bloc.dart';
import '../core/theme/presentation/blocs/theme_event.dart';

/// Провайдеры BLoC для модуля аутентификации
///
/// Предоставляет фабричные методы для создания всех зависимостей
/// модуля аутентификации с соблюдением принципов Clean Architecture.
class AuthBlocProviders {
  // Фабричные методы - каждый вызов создает новый экземпляр
  // Нет статических переменных кэширования - чистая архитектура

  /// Создает экземпляр DioClient для HTTP запросов
  static DioClient createDioClient() {
    return DioClient();
  }

  /// Создает сервис для очистки данных
  static DataClearService createDataClearService() {
    return const DataClearService();
  }

  /// Создает репозиторий аутентификации
  static AuthRepositoryImpl createAuthRepository() {
    return AuthRepositoryImpl(createDioClient(), createDataClearService());
  }

  /// Создает use case для проверки аутентификации
  static CheckAuthUseCase createCheckAuthUseCase() {
    return CheckAuthUseCase(createAuthRepository());
  }

  /// Создает use case для выхода из системы
  static LogoutUseCase createLogoutUseCase() {
    return LogoutUseCase(createAuthRepository());
  }

  /// Создает use case для входа в систему
  static LoginUseCase createLoginUseCase() {
    return LoginUseCase(createAuthRepository());
  }

  /// Создает use case для регистрации пользователя
  static RegisterUseCase createRegisterUseCase() {
    return RegisterUseCase(createAuthRepository());
  }

  /// Создает use case для активации профиля после регистрации
  static RegisterProfileUseCase createRegisterProfileUseCase() {
    return RegisterProfileUseCase(createAuthRepository());
  }

  /// Создает репозиторий профилей
  static ProfileRepositoryImpl createProfileRepository() {
    return ProfileRepositoryImpl();
  }

  /// Создает основной BLoC для аутентификации
  ///
  /// Собирает все зависимости для работы модуля аутентификации
  static AuthBloc createAuthBloc() {
    return AuthBloc(
      createCheckAuthUseCase(),
      createLogoutUseCase(),
      createLoginUseCase(),
      createRegisterUseCase(),
      createRegisterProfileUseCase(),
      AccountRepositoryImpl(),
      createProfileRepository(),
      createDataClearService(),
      createDioClient(),
      ThemeBloc()..add(LoadThemeEvent()),
    );
  }

  /// Список провайдеров BLoC для аутентификации
  static List<BlocProvider> get providers => [
    BlocProvider<AuthBloc>(
      create: (_) => createAuthBloc(),
      lazy: false,
    ),
  ];
}
