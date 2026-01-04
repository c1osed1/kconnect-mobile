///// Утилиты для обработки преобразований логических значений из различных источников
///
/// Предоставляет функции для безопасного преобразования различных типов данных
/// в логические значения Dart, обрабатывая разные форматы представления.
class BooleanUtils {
  /// Преобразует различные представления логических значений в Dart bool
  ///
  /// Обрабатывает: bool, int, String (включая 'true', 'false', '1', '0', 'yes', 'no', etc.)
  /// [value] - значение для преобразования
  /// Returns: логическое значение (false по умолчанию для неизвестных значений)
  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') return true;
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off' || lower.isEmpty) return false;
    }
    return false;
  }
}
