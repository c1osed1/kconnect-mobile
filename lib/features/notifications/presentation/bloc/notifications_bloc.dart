/// BLoC для управления уведомлениями
///
/// Управляет загрузкой, обновлением и отметкой уведомлений как прочитанных.
/// Поддерживает автоматическое опрос уведомлений через заданные интервалы.
/// Интегрируется с репозиторием для работы с данными уведомлений.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/notification_model.dart';
import '../../domain/notifications_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// BLoC класс для управления уведомлениями
///
/// Обрабатывает все операции с уведомлениями: загрузка списка,
/// автоматическое обновление, отметка как прочитанное.
/// Поддерживает polling для обновления уведомлений в реальном времени.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository;
  Timer? _pollingTimer;
  bool _isRequestInFlight = false;

  NotificationsBloc(this._repository) : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsPolled>(_onPolled);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationReadRequested>(_onReadRequested);
  }

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    await _fetchNotifications(emit, statusOnStart: NotificationsStatus.loading);
    emit(state.copyWith(isPolling: true));
    _startPolling();
  }

  Future<void> _onPolled(
    NotificationsPolled event,
    Emitter<NotificationsState> emit,
  ) async {
    await _fetchNotifications(emit, keepStatus: true);
  }

  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    await _fetchNotifications(emit, isRefresh: true);
  }

  Future<void> _onReadRequested(
    NotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final notification = state.notifications.firstWhere(
      (item) => item.id == event.notificationId,
      orElse: () => NotificationItem(
        id: event.notificationId,
        contentType: '',
        message: '',
        createdAt: DateTime.now(),
        isRead: true,
        type: '',
      ),
    );

    if (notification.isRead) {
      return;
    }

    try {
      await _repository.markAsRead(event.notificationId);
      final updatedList = state.notifications
          .map((item) => item.id == event.notificationId ? item.copyWith(isRead: true) : item)
          .toList();
      final updatedUnread = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

      emit(state.copyWith(
        notifications: updatedList,
        unreadCount: updatedUnread,
      ));
    } catch (e, st) {
      debugPrint('NotificationsBloc: markAsRead failed: $e\n$st');
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _fetchNotifications(
    Emitter<NotificationsState> emit, {
    NotificationsStatus? statusOnStart,
    bool keepStatus = false,
    bool isRefresh = false,
  }) async {
    if (_isRequestInFlight) return;
    _isRequestInFlight = true;
    if (statusOnStart != null) {
      emit(state.copyWith(status: statusOnStart, error: null));
    } else if (isRefresh) {
      emit(state.copyWith(isRefreshing: true, error: null));
    }

    try {
      final response = await _repository.fetchNotifications();
      final sorted = [...response.notifications]
        ..sort((a, b) {
          // Unread first
          if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
          return b.createdAt.compareTo(a.createdAt);
        });
      emit(state.copyWith(
        notifications: sorted,
        unreadCount: response.unreadCount,
        status: keepStatus ? state.status : NotificationsStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e, st) {
      debugPrint('NotificationsBloc: fetch failed: $e\n$st');
      emit(state.copyWith(
        status: keepStatus ? state.status : NotificationsStatus.failure,
        error: e.toString(),
        isRefreshing: false,
      ));
    } finally {
      _isRequestInFlight = false;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      add(const NotificationsPolled());
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
