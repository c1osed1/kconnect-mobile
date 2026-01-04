// Утилиты для форматирования относительного времени
//
// Преобразует ISO строки дат в человеко-читаемый формат
// для отображения времени постов и другой активности.

/// Форматирует время в относительный формат из ISO строки
///
/// [isoString] - ISO 8601 строка даты
/// Returns: Относительное время (например: "только что", "5 мин назад")
String formatRelativeTime(String isoString) {
  final dateTime = DateTime.parse(isoString).toLocal();
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        return 'только что';
      }
      return '${difference.inMinutes} мин назад';
    }
    return '${difference.inHours} ч назад';
  } else if (difference.inDays < 30) {
    return '${difference.inDays} д назад';
  } else {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}

/// Форматирует время в относительный формат из миллисекунд с эпохи
///
/// [milliseconds] - количество миллисекунд с 1970-01-01
/// Returns: Относительное время (например: "только что", "5 мин назад")
String formatRelativeTimeFromMillis(int milliseconds) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        return 'только что';
      }
      return '${difference.inMinutes} мин назад';
    }
    return '${difference.inHours} ч назад';
  } else if (difference.inDays < 30) {
    return '${difference.inDays} д назад';
  } else {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}
