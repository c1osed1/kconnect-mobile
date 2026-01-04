/// Use case для входа в систему
///
/// Отвечает за бизнес-логику аутентификации пользователя.
/// Инкапсулирует процесс входа и возвращает результат с данными сессии.
library;

import '../repositories/auth_repository.dart';

/// Use case для выполнения входа пользователя в систему
///
/// Принимает email и пароль, выполняет аутентификацию через репозиторий.
/// Возвращает результат с информацией об успешности входа и данными сессии.
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Map<String, dynamic>> call(String email, String password) {
    return _repository.login(email, password);
  }
}
