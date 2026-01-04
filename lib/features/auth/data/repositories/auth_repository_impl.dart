import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../../../services/api_client/dio_client.dart';
import '../../../../services/data_clear_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../core/utils/cache_utils.dart';

/// Реализация репозитория аутентификации
///
/// Обрабатывает все операции связанные с аутентификацией пользователей:
/// вход, регистрация, проверка сессии, выход из системы.
/// Обеспечивает безопасность хранения и передачи учетных данных.
class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final DataClearService _dataClearService;

  AuthRepositoryImpl(this._dioClient, this._dataClearService);

  /// Проверяет текущую сессию аутентификации
  ///
  /// Отправляет запрос к API для проверки валидности сессии.
  /// Returns: объект пользователя если сессия активна, null в противном случае
  @override
  Future<AuthUser?> checkAuth() async {
    try {
      final response = await _dioClient.get('/api/auth/check');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['isAuthenticated'] == true && data['user'] != null) {
          return AuthUser.fromJson(data['user']);
        }
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  /// Выполняет вход пользователя в систему
  ///
  /// [email] - email или имя пользователя
  /// [password] - пароль пользователя
  /// Returns: результат операции с данными сессии или ошибкой
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dioClient.post('/api/auth/login', {
        'usernameOrEmail': email,
        'password': password,
        'remember': true,
      }, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });

      final data = res.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final sessionKey = data['sessionKey'] as String?;
        if (sessionKey != null) {
          await _dioClient.saveSession(sessionKey);
        }
        return data; // Return full response data
      } else {
        // Normalize error to string
        String errorMessage = 'Login failed';
        if (data['error'] is String) {
          errorMessage = data['error'];
        } else if (data['error'] is Map) {
          errorMessage = (data['error'] as Map)['message'] ?? 'Login failed';
        }
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}'
      };
    }
  }

  /// Регистрирует нового пользователя в системе
  ///
  /// [username] - уникальное имя пользователя
  /// [email] - email адрес
  /// [password] - пароль пользователя
  /// [name] - отображаемое имя (опционально)
  /// Returns: результат регистрации с сообщением об успехе или ошибке
  @override
  Future<Map<String, dynamic>> register(String username, String email, String password, String name) async {
    try {
      final requestData = {
        'username': username,
        'email': email,
        'password': password,
        if (name.isNotEmpty) 'name': name,
      };

      final response = await _dioClient.post('/api/auth/register', requestData, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        // Проверяем предоставлен ли сессионный ключ (некоторые API автоматически аутентифицируют при регистрации)
        final sessionKey = responseData['sessionKey'] as String?;
        if (sessionKey != null) {
          await _dioClient.saveSession(sessionKey);
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Регистрация успешна',
          'isAuthenticated': sessionKey != null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] as String? ?? 'Неизвестная ошибка регистрация',
        };
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Активирует профиль пользователя после регистрации
  ///
  /// Отправляет пустой POST запрос с сессионным ключом для завершения настройки профиля.
  /// Returns: true если активация успешна, false в противном случае
  @override
  Future<bool> registerProfile() async {
    try {
      // POST /api/auth/register-profile - пустой запрос с куками/session key для активации профиля
      final response = await _dioClient.post('/api/auth/register-profile', {}, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });

      // Ожидаем 201 Created статус
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Выполняет вход с дополнительными деталями
  ///
  /// Аналогично login(), но возвращает расширенную информацию включая
  /// необходимость настройки профиля и chat ID.
  ///
  /// [email] - email или имя пользователя
  /// [password] - пароль пользователя
  /// Returns: расширенный результат входа с дополнительными полями
  @override
  Future<Map<String, dynamic>> loginWithDetails(String email, String password) async {
    try {
      final res = await _dioClient.post('/api/auth/login', {
        'usernameOrEmail': email,
        'password': password,
        'remember': true,
      }, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });

      final data = res.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final sessionKey = data['session_key'] as String?;
        if (sessionKey != null) {
          await _dioClient.saveSession(sessionKey);
        }

        // Return full response including needsProfileSetup
        return {
          'success': true,
          'sessionKey': sessionKey,
          'needsProfileSetup': data['needsProfileSetup'] ?? false,
          'chatId': data['chat_id'],
          ...data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Выполняет выход пользователя из системы
  ///
  /// Очищает все сессионные данные, настройки персонализации,
  /// кэш изображений и данные BLoC состояний для полной очистки.
  @override
  Future<void> logout() async {
    // Очищаем сессионные данные
    await _dioClient.clearSession();

    // Очищаем настройки персонализации для сброса темы к умолчанию
    await StorageService.clearPersonalizationSettings();

    // Очищаем кэш изображений для полной очистки
    CacheUtils.clearImageCache();

    // Очищаем кэшированные данные пользователя из BLoC состояний
    _dataClearService.clearAllUserData();

    // Примечание: Здесь можно добавить дополнительный API вызов к серверному эндпоинту logout
    // Например: await _dioClient.post('/api/auth/logout', {});
  }
}
