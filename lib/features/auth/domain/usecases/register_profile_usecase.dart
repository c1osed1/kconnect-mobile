/// Use case для регистрации профиля пользователя
///
/// Отвечает за бизнес-логику завершения регистрации нового пользователя.
/// Выполняет дополнительные шаги настройки профиля после базовой регистрации.
library;

import '../repositories/auth_repository.dart';

/// Use case для выполнения регистрации профиля пользователя
///
/// Выполняет дополнительные шаги настройки профиля после успешной базовой регистрации.
/// Возвращает результат операции настройки профиля.
class RegisterProfileUseCase {
  final AuthRepository _repository;

  RegisterProfileUseCase(this._repository);

  Future<bool> call() {
    return _repository.registerProfile();
  }
}
