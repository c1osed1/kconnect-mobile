// Утилиты для форматирования дат в уведомлениях
//
// Преобразует дату в человеко-читаемый формат для отображения
// времени уведомлений (только что, X мин назад и т.д.).
import 'package:intl/intl.dart';

/// Форматирует дату уведомления в относительный формат времени
///
/// Returns: Строка с относительным временем (например: "только что", "5 мин назад")
String formatNotificationDate(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'только что';
  if (difference.inHours < 1) return '${difference.inMinutes} мин назад';
  if (difference.inHours < 24) return '${difference.inHours} ч назад';
  if (difference.inDays == 1) return 'вчера';

  return DateFormat('dd.MM.yyyy, HH:mm').format(dateTime);
}
