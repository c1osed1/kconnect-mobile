/// Состояния BLoC для системы сообщений
///
/// Определяет все возможные состояния управления сообщениями и чатами,
/// включая статусы загрузки, WebSocket соединение, счетчики непрочитанных сообщений.
library;

import 'package:equatable/equatable.dart';
import '../../../../services/messenger_websocket_service.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/message.dart';

/// Статусы загрузки для операций с сообщениями
enum MessagesStatus { initial, loading, success, failure }

/// Состояние системы сообщений
///
/// Хранит текущее состояние чатов, сообщений, статусов загрузки
/// и информацию о WebSocket соединении.
class MessagesState extends Equatable {
  final MessagesStatus status;
  final List<Chat> chats;
  final List<Chat> filteredChats;
  final String? error;
  final WebSocketConnectionState wsConnectionState;
  final Map<int, List<Message>> chatMessages; // chatId -> messages
  final Map<int, MessagesStatus> chatMessageStatuses; // chatId -> loading status
  final int totalUnreadCount; // Total unread messages across all chats

  const MessagesState({
    this.status = MessagesStatus.initial,
    this.chats = const [],
    this.filteredChats = const [],
    this.error,
    this.wsConnectionState = WebSocketConnectionState.disconnected,
    this.chatMessages = const {},
    this.chatMessageStatuses = const {},
    this.totalUnreadCount = 0,
  });

  MessagesState copyWith({
    MessagesStatus? status,
    List<Chat>? chats,
    List<Chat>? filteredChats,
    String? error,
    WebSocketConnectionState? wsConnectionState,
    Map<int, List<Message>>? chatMessages,
    Map<int, MessagesStatus>? chatMessageStatuses,
    int? totalUnreadCount,
  }) {
    return MessagesState(
      status: status ?? this.status,
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
      error: error ?? this.error,
      wsConnectionState: wsConnectionState ?? this.wsConnectionState,
      chatMessages: chatMessages ?? this.chatMessages,
      chatMessageStatuses: chatMessageStatuses ?? this.chatMessageStatuses,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    chats,
    filteredChats,
    error,
    wsConnectionState,
    chatMessages,
    chatMessageStatuses,
    totalUnreadCount,
  ];
}
