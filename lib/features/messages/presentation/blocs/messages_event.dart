/// События для управления сообщениями в BLoC
///
/// Определяет все возможные события, которые могут происходить
/// в системе сообщений: загрузка чатов, отправка сообщений,
/// WebSocket события, управление статусом прочтения.
library;

import '../../../../services/messenger_websocket_service.dart';
import '../../domain/models/message.dart';

/// Базовый класс для всех событий сообщений
abstract class MessagesEvent {}

class LoadChatsEvent extends MessagesEvent {}

class RefreshChatsEvent extends MessagesEvent {}

class SearchChatsEvent extends MessagesEvent {
  final String query;

  SearchChatsEvent(this.query);
}

class InitMessagesEvent extends MessagesEvent {}

class ConnectWebSocketEvent extends MessagesEvent {}

class DisconnectWebSocketEvent extends MessagesEvent {}

class WebSocketMessageReceivedEvent extends MessagesEvent {
  final Map<String, dynamic> message;

  WebSocketMessageReceivedEvent(this.message);
}

class WebSocketConnectionChangedEvent extends MessagesEvent {
  final WebSocketConnectionState state;

  WebSocketConnectionChangedEvent(this.state);
}

class LoadChatMessagesEvent extends MessagesEvent {
  final int chatId;

  LoadChatMessagesEvent(this.chatId);
}

class SendMessageEvent extends MessagesEvent {
  final int chatId;
  final String content;
  final String messageType;

  SendMessageEvent({
    required this.chatId,
    required this.content,
    this.messageType = 'text',
  });
}

class CreateChatEvent extends MessagesEvent {
  final int userId;
  final bool encrypted;

  CreateChatEvent({
    required this.userId,
    this.encrypted = false,
  });
}

class UpdateMessageStatusEvent extends MessagesEvent {
  final String clientMessageId;
  final MessageDeliveryStatus status;

  UpdateMessageStatusEvent({
    required this.clientMessageId,
    required this.status,
  });
}

class MarkChatAsReadEvent extends MessagesEvent {
  final int chatId;

  MarkChatAsReadEvent({
    required this.chatId,
  });
}
