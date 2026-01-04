/// Репозиторий для работы с уведомлениями
///
/// Определяет интерфейс для работы с данными уведомлений.
/// Предоставляет абстракцию над источниками данных (локальными и удаленными).
library;

import '../data/models/notification_model.dart';

/// Абстрактный репозиторий для управления уведомлениями
///
/// Определяет контракт для работы с уведомлениями: загрузка списка
/// и управление статусом прочтения уведомлений.
abstract class NotificationsRepository {
  Future<NotificationsResponse> fetchNotifications();
  Future<void> markAsRead(int id);
}
