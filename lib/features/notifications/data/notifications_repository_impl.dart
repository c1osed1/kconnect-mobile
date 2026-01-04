/// Реализация репозитория уведомлений
///
/// Предоставляет конкретную реализацию интерфейса NotificationsRepository.
/// Делегирует вызовы удаленному источнику данных для работы с API.
library;

import '../domain/notifications_repository.dart';
import 'models/notification_model.dart';
import 'notifications_remote_data_source.dart';

/// Конкретная реализация репозитория уведомлений
///
/// Реализует интерфейс NotificationsRepository, используя
/// NotificationsRemoteDataSource для работы с API сервера.
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<NotificationsResponse> fetchNotifications() {
    return _remoteDataSource.fetchNotifications();
  }

  @override
  Future<void> markAsRead(int id) {
    return _remoteDataSource.markAsRead(id);
  }
}
