/// Use case для регистрации нового пользователя
///
/// Отвечает за бизнес-логику создания новой учетной записи.
/// Инкапсулирует процесс регистрации и валидацию входных данных.
library;

import '../repositories/auth_repository.dart';

/// Use case для выполнения регистрации нового пользователя
///
/// Принимает данные пользователя (имя пользователя, email, пароль, имя),
/// выполняет валидацию и регистрацию через репозиторий.
/// Возвращает результат с информацией об успешности регистрации.
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Map<String, dynamic>> call(String username, String email, String password, String name) {
    return _repository.register(username, email, password, name);
  }
}
