import '../repositories/auth_repository.dart';
import '../models/auth_user.dart';

/// Use case для проверки текущей сессии аутентификации
///
/// Отправляет запрос к серверу для проверки валидности сессии пользователя.
/// Используется при запуске приложения и для обновления состояния аутентификации.
class CheckAuthUseCase {
  final AuthRepository _authRepository;

  CheckAuthUseCase(this._authRepository);

  /// Выполняет проверку аутентификации
  ///
  /// Returns: объект AuthUser если сессия активна, null если пользователь не авторизован
  Future<AuthUser?> execute() {
    return _authRepository.checkAuth();
  }
}
