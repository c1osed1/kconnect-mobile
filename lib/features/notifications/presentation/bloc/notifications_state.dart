/// Состояния BLoC для уведомлений
///
/// Определяет все возможные состояния управления уведомлениями:
/// статусы загрузки, список уведомлений, счетчик непрочитанных.
library;

import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

/// Статусы загрузки уведомлений
enum NotificationsStatus { initial, loading, success, failure }

/// Состояние уведомлений
///
/// Хранит текущее состояние системы уведомлений: список уведомлений,
/// статусы загрузки, счетчик непрочитанных, ошибки и т.д.
class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationItem> notifications;
  final int unreadCount;
  final String? error;
  final bool isRefreshing;
  final bool isPolling;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
    this.isRefreshing = false,
    this.isPolling = false,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItem>? notifications,
    int? unreadCount,
    String? error,
    bool? isRefreshing,
    bool? isPolling,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPolling: isPolling ?? this.isPolling,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        error,
        isRefreshing,
        isPolling,
      ];
}
