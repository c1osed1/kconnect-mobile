/// Удаленный источник данных для уведомлений
///
/// Предоставляет методы для загрузки уведомлений и отметки их как прочитанные.
/// Использует DioClient для выполнения HTTP запросов к API уведомлений.
library;

import 'package:dio/dio.dart';
import 'models/notification_model.dart';
import '../../../services/api_client/dio_client.dart';

/// Источник данных для работы с уведомлениями через API
///
/// Реализует загрузку списка уведомлений и управление статусом прочтения.
/// Поддерживает отмену запросов через CancelToken.
class NotificationsRemoteDataSource {
  final DioClient _client;

  NotificationsRemoteDataSource(this._client);

  Future<NotificationsResponse> fetchNotifications({CancelToken? cancelToken}) async {
    final response = await _client.get(
      '/api/notifications/',
      cancelToken: cancelToken,
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return NotificationsResponse.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Failed to load notifications (${response.statusCode})');
  }

  Future<void> markAsRead(int id) async {
    final response = await _client.post('/api/notifications/$id/read', null);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }
}
