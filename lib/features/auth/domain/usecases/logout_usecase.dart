/// Use case для выхода из системы
///
/// Отвечает за бизнес-логику завершения сессии пользователя.
/// Инкапсулирует процесс выхода и очистку данных сессии.
library;

import '../repositories/auth_repository.dart';

/// Use case для выполнения выхода пользователя из системы
///
/// Выполняет логаут через репозиторий, очищает сессионные данные.
/// Возвращает результат операции выхода.
class LogoutUseCase {
  final AuthRepository _authRepository;

  LogoutUseCase(this._authRepository);

  Future<void> execute() {
    return _authRepository.logout();
  }
}
