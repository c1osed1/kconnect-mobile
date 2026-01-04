import 'package:equatable/equatable.dart';

/// Базовый класс для всех событий уведомлений
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

class NotificationsPolled extends NotificationsEvent {
  const NotificationsPolled();
}

class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

class NotificationReadRequested extends NotificationsEvent {
  final int notificationId;

  const NotificationReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}
