/// Валидаторы для форм ввода
///
/// Предоставляет статические методы для валидации различных полей ввода,
/// таких как имя пользователя, email, пароль и имя.
class Validators {
  /// Валидирует имя пользователя
  ///
  /// [value] - значение для валидации
  /// Returns: строку с ошибкой или null если валидно
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Имя пользователя обязательное';
    }
    if (value.length < 3 || value.length > 30) {
      return 'Имя пользователя должно быть от 3 до 30 символов';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Имя пользователя может содержать только буквы, цифры и подчеркивание';
    }
    return null;
  }

  /// Валидирует адрес электронной почты
  ///
  /// [value] - значение для валидации
  /// Returns: строку с ошибкой или null если валидно
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email обязательный';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  /// Валидирует пароль
  ///
  /// [value] - значение для валидации
  /// Returns: строку с ошибкой или null если валидно
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязательный';
    }
    if (value.length < 8) {
      return 'Пароль должен быть минимум 8 символов';
    }
    return null;
  }

  /// Валидирует имя пользователя (опционально)
  ///
  /// [value] - значение для валидации (может быть null)
  /// Returns: строку с ошибкой или null если валидно
  static String? validateName(String? value) {
    // Name is optional, only validate if provided
    if (value != null && value.isNotEmpty && value.length > 50) {
      return 'Имя не может быть длиннее 50 символов';
    }
    return null;
  }
}
