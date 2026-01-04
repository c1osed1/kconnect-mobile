/// BLoC для управления сообщениями и чатами
///
/// Управляет состоянием системы сообщений, включая загрузку чатов,
/// отправку сообщений, WebSocket соединение и обработку входящих сообщений.
/// Интегрируется с WebSocket сервисом для реального времени.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/messenger_websocket_service.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../domain/usecases/fetch_chats_usecase.dart';
import '../../domain/models/message.dart';
import '../../domain/models/chat.dart';
import 'messages_event.dart';
import 'messages_state.dart';

/// BLoC класс для управления сообщениями и чатами
///
/// Обрабатывает все операции с сообщениями: загрузка чатов, отправка сообщений,
/// получение новых сообщений через WebSocket, управление статусом прочтения.
/// Поддерживает оффлайн режим с локальным хранением.
class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  // ignore: unused_field
  final FetchChatsUseCase _fetchChatsUseCase;
  // ignore: unused_field
  final AuthBloc _authBloc;
  final MessagesRepository _messagesRepository;
  final MessengerWebSocketService _webSocketService;

  StreamSubscription<WebSocketMessage>? _wsMessageSubscription;
  StreamSubscription<WebSocketConnectionState>? _wsConnectionSubscription;

  MessagesBloc(
    this._fetchChatsUseCase,
    this._authBloc,
    this._messagesRepository,
    this._webSocketService,
  ) : super(const MessagesState()) {
    on<LoadChatsEvent>(_onLoadChats);
    on<RefreshChatsEvent>(_onRefreshChats);
    on<SearchChatsEvent>(_onSearchChats);
    on<InitMessagesEvent>(_onInitMessages);
    on<ConnectWebSocketEvent>(_onConnectWebSocket);
    on<DisconnectWebSocketEvent>(_onDisconnectWebSocket);
    on<WebSocketMessageReceivedEvent>(_onWebSocketMessageReceived);
    on<WebSocketConnectionChangedEvent>(_onWebSocketConnectionChanged);
    on<LoadChatMessagesEvent>(_onLoadChatMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<CreateChatEvent>(_onCreateChat);
    on<UpdateMessageStatusEvent>(_onUpdateMessageStatus);
    on<MarkChatAsReadEvent>(_onMarkChatAsRead);

    // Listen to auth changes to reload chats when user changes
    // _authBloc.stream.listen(_onAuthStateChanged);
  }



  @override
  Future<void> close() {
    _wsMessageSubscription?.cancel();
    _wsConnectionSubscription?.cancel();
    _webSocketService.disconnect();
    return super.close();
  }

  Future<void> _onLoadChats(
    LoadChatsEvent event,
    Emitter<MessagesState> emit,
  ) async {
    emit(state.copyWith(status: MessagesStatus.loading));

    try {
      // Send WebSocket request to get chats instead of HTTP API
      _webSocketService.sendGetChatsMessage();
      // The response will be handled by _onWebSocketMessageReceived -> _handleChatsReceived
    } catch (e) {
      emit(state.copyWith(
        status: MessagesStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshChats(
    RefreshChatsEvent event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MessagesStatus.loading));
      // Send WebSocket request to refresh chats
      _webSocketService.sendGetChatsMessage();
      // The response will be handled by _onWebSocketMessageReceived -> _handleChatsReceived
    } catch (e) {
      emit(state.copyWith(
        status: MessagesStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void _onSearchChats(
    SearchChatsEvent event,
    Emitter<MessagesState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredChats: state.chats));
    } else {
      final filtered = state.chats
          .where((chat) =>
              chat.title.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(state.copyWith(filteredChats: filtered));
    }
  }

  Future<void> _onInitMessages(
    InitMessagesEvent event,
    Emitter<MessagesState> emit,
  ) async {
    emit(const MessagesState());
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocketEvent event,
    Emitter<MessagesState> emit,
  ) async {
    debugPrint('MessagesBloc: ConnectWebSocketEvent received');
    if (_wsConnectionSubscription != null) {
      debugPrint('MessagesBloc: WebSocket already connected, skipping');
      return;
    }

    debugPrint('MessagesBloc: Connecting to WebSocket...');
    await _webSocketService.connect();

    debugPrint('MessagesBloc: Setting up message subscriptions...');
    _wsMessageSubscription = _webSocketService.messages.listen(
      (wsMessage) {
        debugPrint('MessagesBloc: WebSocket message received: ${wsMessage.type}');
        add(WebSocketMessageReceivedEvent(wsMessage.data));
      },
    );

    _wsConnectionSubscription = _webSocketService.connectionState.listen(
      (connectionState) {
        debugPrint('MessagesBloc: WebSocket state changed: $connectionState');
        add(WebSocketConnectionChangedEvent(connectionState));
      },
    );
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocketEvent event,
    Emitter<MessagesState> emit,
  ) async {
    _wsMessageSubscription?.cancel();
    _wsConnectionSubscription?.cancel();
    _wsMessageSubscription = null;
    _wsConnectionSubscription = null;
    _webSocketService.disconnect();
  }

  void _onWebSocketMessageReceived(
    WebSocketMessageReceivedEvent event,
    Emitter<MessagesState> emit,
  ) {
    final messageType = event.message['type'];

    switch (messageType) {
      case 'connected':
        _handleConnected(event.message, emit);
        break;
      case 'chats':
        _handleChatsReceived(event.message, emit);
        break;
      case 'user_status':
        _handleUserStatusUpdate(event.message, emit);
        break;
      case 'message_sent':
        _handleMessageSent(event.message, emit);
        break;
      case 'new_message':
        _handleNewMessage(event.message, emit);
        break;
      case 'message_read':
        _handleMessageRead(event.message, emit);
        break;
      case 'read_receipt':
        _handleReadReceipt(event.message, emit);
        break;

      case 'pong':
        // Handle pong if needed
        break;
    }
  }

  void _onWebSocketConnectionChanged(
    WebSocketConnectionChangedEvent event,
    Emitter<MessagesState> emit,
  ) {
    emit(state.copyWith(wsConnectionState: event.state));
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessagesEvent event,
    Emitter<MessagesState> emit,
  ) async {
    final chatId = event.chatId;

    emit(state.copyWith(
      chatMessageStatuses: {
        ...state.chatMessageStatuses,
        chatId: MessagesStatus.loading,
      },
    ));

    try {
      final messages = await _messagesRepository.fetchMessages(chatId);
      emit(state.copyWith(
        chatMessages: {
          ...state.chatMessages,
          chatId: messages,
        },
        chatMessageStatuses: {
          ...state.chatMessageStatuses,
          chatId: MessagesStatus.success,
        },
      ));
    } catch (e) {
      emit(state.copyWith(
        chatMessageStatuses: {
          ...state.chatMessageStatuses,
          chatId: MessagesStatus.failure,
        },
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagesState> emit,
  ) async {
    final clientMessageId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = Message(
      messageType: MessageType.text,
      content: event.content,
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
      deliveryStatus: MessageDeliveryStatus.sending,
    );

    // Add temporary message to UI (at the beginning since sorted newest first)
    final currentMessages = state.chatMessages[event.chatId] ?? [];
    final updatedMessages = [tempMessage, ...currentMessages];

    emit(state.copyWith(
      chatMessages: {
        ...state.chatMessages,
        event.chatId: updatedMessages,
      },
    ));

    try {
      // Send via WebSocket
      _webSocketService.sendMessage(
        content: event.content,
        chatId: event.chatId,
        clientMessageId: clientMessageId,
      );

      // Update status to sent (will be updated via WebSocket response)
      add(UpdateMessageStatusEvent(
        clientMessageId: clientMessageId,
        status: MessageDeliveryStatus.sent,
      ));
    } catch (e) {
      // Update status to failed
      add(UpdateMessageStatusEvent(
        clientMessageId: clientMessageId,
        status: MessageDeliveryStatus.failed,
      ));
    }
  }

  Future<void> _onCreateChat(
    CreateChatEvent event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      await _messagesRepository.createChat(event.userId, encrypted: event.encrypted);
      // Reload chats to include the new chat
      add(LoadChatsEvent());
    } catch (e) {
      emit(state.copyWith(
        status: MessagesStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void _onUpdateMessageStatus(
    UpdateMessageStatusEvent event,
    Emitter<MessagesState> emit,
  ) {
    // Update message status in all chat messages
    final updatedChatMessages = <int, List<Message>>{};

    state.chatMessages.forEach((chatId, messages) {
      final updatedMessages = messages.map((message) {
        if (message.clientMessageId == event.clientMessageId) {
          return message.copyWith(deliveryStatus: event.status);
        }
        return message;
      }).toList();

      updatedChatMessages[chatId] = updatedMessages;
    });

    emit(state.copyWith(chatMessages: updatedChatMessages));
  }

  Future<void> _onMarkChatAsRead(
    MarkChatAsReadEvent event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      debugPrint('MessagesBloc: Marking chat ${event.chatId} as read');
      final markedCount = await _messagesRepository.markChatAsRead(event.chatId);

      debugPrint('MessagesBloc: Marked $markedCount messages as read');

      // Update chat unread count to 0
      final updatedChats = state.chats.map((chat) {
        if (chat.id == event.chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();

      final updatedFilteredChats = state.filteredChats.map((chat) {
        if (chat.id == event.chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();

      // Recalculate total unread count
      final newTotalUnread = updatedChats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);

      debugPrint('MessagesBloc: Updated totalUnreadCount after marking read: $newTotalUnread');

      emit(state.copyWith(
        chats: updatedChats,
        filteredChats: updatedFilteredChats,
        totalUnreadCount: newTotalUnread,
      ));
    } catch (e) {
      debugPrint('MessagesBloc: Failed to mark chat as read: $e');
      // Don't emit error state, just log it
    }
  }

  void _handleUserStatusUpdate(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    // Handle user online/offline status updates
    // This could update chat member statuses
  }

  void _handleConnected(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    // Authentication successful - update connection state to connected
    debugPrint('MessagesBloc: WebSocket authenticated successfully');
    emit(state.copyWith(wsConnectionState: WebSocketConnectionState.connected));

    // Automatically load chats to show unread badge immediately
    debugPrint('MessagesBloc: Auto-loading chats after WebSocket connection');
    _webSocketService.sendGetChatsMessage();
  }

  void _handleChatsReceived(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    final chatsData = data['chats'] as List<dynamic>? ?? [];
    final chats = chatsData.map((chatJson) => Chat.fromJson(chatJson as Map<String, dynamic>)).toList();

    // Calculate total unread count
    final totalUnread = chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);

    debugPrint('MessagesBloc: Received ${chats.length} chats, totalUnreadCount: $totalUnread');
    for (var chat in chats) {
      if (chat.unreadCount > 0) {
        debugPrint('Chat "${chat.title}" has ${chat.unreadCount} unread messages');
      }
    }

    emit(state.copyWith(
      chats: chats,
      filteredChats: chats,
      status: MessagesStatus.success,
      totalUnreadCount: totalUnread,
    ));
  }

  void _handleMessageSent(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    final clientMessageId = data['clientMessageId'] as String?;
    if (clientMessageId != null) {
      // Update message status and add server message
      final serverMessage = Message.fromWebSocketMessage(data);

      // Update status of temporary message and replace with server message
      final updatedChatMessages = <int, List<Message>>{};

      state.chatMessages.forEach((chatId, messages) {
        final updatedMessages = messages.map((message) {
          if (message.clientMessageId == clientMessageId && message.deliveryStatus == MessageDeliveryStatus.sending) {
            return serverMessage;
          }
          return message;
        }).toList();

        // If server message wasn't a replacement, add it at the beginning (newest first)
        if (!updatedMessages.any((m) => m.id == serverMessage.id)) {
          updatedMessages.insert(0, serverMessage);
        }

        updatedChatMessages[chatId] = updatedMessages;
      });

      emit(state.copyWith(chatMessages: updatedChatMessages));
    }
  }

  void _handleNewMessage(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    final chatId = data['chatId'] as int?;
    if (chatId == null) return;

    // Extract message data from the WebSocket payload
    final messageData = data['message'] as Map<String, dynamic>?;
    if (messageData == null) return;

    // Create message from WebSocket message data
    final newMessage = Message.fromWebSocketMessage(messageData);

    debugPrint('MessagesBloc: New message in chat $chatId: ${newMessage.content}');

    // Update chat's last message and increment unread count
    final updatedChats = state.chats.map((chat) {
      if (chat.id == chatId) {
        final newUnreadCount = chat.unreadCount + 1;
        return chat.copyWith(
          lastMessage: newMessage,
          unreadCount: newUnreadCount,
          updatedAt: newMessage.createdAt,
        );
      }
      return chat;
    }).toList();

    // Update filtered chats too
    final updatedFilteredChats = state.filteredChats.map((chat) {
      if (chat.id == chatId) {
        final newUnreadCount = chat.unreadCount + 1;
        return chat.copyWith(
          lastMessage: newMessage,
          unreadCount: newUnreadCount,
          updatedAt: newMessage.createdAt,
        );
      }
      return chat;
    }).toList();

    // Add message to chat messages if chat is loaded (at the beginning since sorted newest first)
    final currentMessages = state.chatMessages[chatId] ?? [];
    final updatedMessages = [newMessage, ...currentMessages];

    // Recalculate total unread count
    final newTotalUnread = updatedChats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);

    debugPrint('MessagesBloc: Updated totalUnreadCount: $newTotalUnread');
    debugPrint('MessagesBloc: Emitting new state with totalUnreadCount: $newTotalUnread');

    emit(state.copyWith(
      chats: updatedChats,
      filteredChats: updatedFilteredChats,
      chatMessages: {
        ...state.chatMessages,
        chatId: updatedMessages,
      },
      totalUnreadCount: newTotalUnread,
    ));

    debugPrint('MessagesBloc: State emitted successfully');
  }

  void _handleMessageRead(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    final chatId = data['chatId'] as int?;
    final messageId = data['messageId'] as int?;
    final userId = data['userId'] as int?;
    if (chatId == null || messageId == null || userId == null) return;

    debugPrint('MessagesBloc: Message $messageId in chat $chatId was read by user $userId');

    // This event indicates that someone read our message
    // Update delivery status to read for our own messages
    final updatedChatMessages = <int, List<Message>>{};

    state.chatMessages.forEach((currentChatId, messages) {
      if (currentChatId == chatId) {
        final updatedMessages = messages.map((message) {
          // Only update status for our own messages that are delivered but not read yet
          if (message.id == messageId &&
              message.deliveryStatus == MessageDeliveryStatus.delivered) {
            return message.copyWith(deliveryStatus: MessageDeliveryStatus.read);
          }
          return message;
        }).toList();
        updatedChatMessages[currentChatId] = updatedMessages;
      } else {
        updatedChatMessages[currentChatId] = messages;
      }
    });

    emit(state.copyWith(chatMessages: updatedChatMessages));
  }

  void _handleReadReceipt(Map<String, dynamic> data, Emitter<MessagesState> emit) {
    final chatId = data['chat_id'] as int?;
    final messageId = data['message_id'] as int?;
    if (chatId == null || messageId == null) return;

    debugPrint('MessagesBloc: Read receipt for message $messageId in chat $chatId');

    // This event indicates that someone read our message
    // Could be used to update delivery status or show read receipts
  }
}
