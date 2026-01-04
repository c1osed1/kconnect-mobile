/// Упрощенный обработчик регистрации
///
/// Выполняет только регистрацию и показывает диалог.
/// Автоматический вход обрабатывается отдельно через AutoLoginEvent.
library;

import 'auth_state.dart';
import 'auth_event.dart';
import '../../domain/usecases/register_usecase.dart';

/// Класс для обработки логики регистрации
///
/// Инкапсулирует процесс регистрации пользователя и возвращает
/// соответствующее состояние в зависимости от результата.
class AuthRegisterHandler {
  final RegisterUseCase _registerUseCase;

  AuthRegisterHandler(this._registerUseCase);

  Future<AuthState> handleRegister(RegisterEvent event) async {
    try {
      final registerResult = await _registerUseCase.call(
        event.username,
        event.email,
        event.password,
        event.name,
      );

      if (registerResult['success'] == true) {
        return AuthRegistrationCompleted(
          'Регистрация успешна! Проверьте почту для подтверждения email и нажмите "Продолжить" для входа в систему. (Возможно письмо в спаме)'
        );
      } else {
        return AuthError(registerResult['message'] ?? 'Ошибка регистрации');
      }

    } catch (e) {
      return AuthError('Произошла ошибка: ${e.toString()}');
    }
  }
}
