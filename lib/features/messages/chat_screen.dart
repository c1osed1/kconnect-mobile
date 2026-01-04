import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/core/utils/theme_extensions.dart';
import 'package:kconnect_mobile/core/widgets/authorized_cached_network_image.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';
import 'package:kconnect_mobile/features/messages/domain/models/chat.dart';
import 'package:kconnect_mobile/features/messages/domain/models/message.dart';
import 'package:kconnect_mobile/features/messages/presentation/blocs/messages_bloc.dart';
import 'package:kconnect_mobile/features/messages/presentation/blocs/messages_event.dart';
import 'package:kconnect_mobile/features/messages/presentation/blocs/messages_state.dart';
import 'package:kconnect_mobile/injection.dart';
import 'package:kconnect_mobile/services/messenger_websocket_service.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';

/// Экран чата для отображения и отправки сообщений
///
/// Позволяет просматривать историю сообщений, отправлять новые сообщения,
/// отображать статус доставки и поддерживает групповые чаты.
/// Включает жесты для быстрого возврата к списку чатов.
class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double _dragStartX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Load messages for this chat
    context.read<MessagesBloc>().add(LoadChatMessagesEvent(widget.chat.id));

    // Mark messages as read after loading (only if there are unread messages)
    if (widget.chat.unreadCount > 0) {
      _markMessagesAsReadAfterLoad();
    }
  }

  void _markMessagesAsReadAfterLoad() {
    // Capture current state before async gap
    final chatId = widget.chat.id;

    // Wait a bit for messages to load, then send read receipts
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final messagesBloc = locator<MessagesBloc>();
        final state = messagesBloc.state;
        final messages = state.chatMessages[chatId] ?? [];

        if (messages.isNotEmpty) {
          final wsService = locator<MessengerWebSocketService>();
          if (wsService.currentConnectionState == WebSocketConnectionState.connected) {
            // Send read receipt for each message in the chat
            for (final message in messages) {
              if (message.id != null) {
                wsService.sendReadReceipt(
                  messageId: message.id!,
                  chatId: chatId,
                );
              }
            }
            debugPrint('📖 ChatScreen: Sent read receipts for ${messages.length} messages');
          }
        }
      } catch (e) {
        debugPrint('❌ ChatScreen: Failed to mark messages as read: $e');
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<MessagesBloc>().add(SendMessageEvent(
        chatId: widget.chat.id,
        content: content,
      ));
      _messageController.clear();

      // Scroll to new messages after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNewMessages();
      });
    }
  }

  void _scrollToNewMessages() {
    if (_scrollController.hasClients) {
      // With reverse: true, new messages are at the top (minScrollExtent = 0)
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final currentX = details.globalPosition.dx;
    final deltaX = currentX - _dragStartX;

    // If dragging right with sufficient distance, dismiss
    if (deltaX > 70) { // 70px threshold - easier to trigger
      _isDragging = false;
      Navigator.of(context).pop();
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagesBloc, MessagesState>(
      builder: (context, state) {
        final messages = state.chatMessages[widget.chat.id] ?? [];
        final isLoading = state.chatMessageStatuses[widget.chat.id] == MessagesStatus.loading;

        return GestureDetector(
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: CupertinoPageScaffold(
          backgroundColor: AppColors.bgDark,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppColors.bgDark.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: AppColors.bgWhite.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoNavigationBarBackButton(
                  color: context.dynamicPrimaryColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.dynamicPrimaryColor.withValues(alpha: 0.2),
                  ),
                  child: widget.chat.avatar != null && widget.chat.avatar!.isNotEmpty
                      ? ClipOval(
                          child: AuthorizedCachedNetworkImage(
                            imageUrl: widget.chat.avatar!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              CupertinoIcons.person_fill,
                              color: context.dynamicPrimaryColor,
                              size: 20,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              CupertinoIcons.person_fill,
                              color: context.dynamicPrimaryColor,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          CupertinoIcons.person_fill,
                          color: context.dynamicPrimaryColor,
                          size: 20,
                        ),
                ),
              ],
            ),
            middle: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                children: [
                  Text(
                    widget.chat.title,
                    style: AppTextStyles.h2.copyWith(color: AppColors.bgWhite),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.chat.isGroup == true
                        ? '${widget.chat.members.length} участников'
                        : 'был(а) в сети недавно', // TODO: Реализовать реальный статус онлайн - показывать время последнего посещения
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: Показать меню опций чата - добавить диалог с настройками чата, блокировкой, поиском
                debugPrint('Chat options tapped');
              },
              child: Icon(
                CupertinoIcons.ellipsis_vertical,
                color: context.dynamicPrimaryColor,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: isLoading && messages.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            color: context.dynamicPrimaryColor,
                          ),
                        )
                      : messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.chat_bubble_2,
                                    size: 64,
                                    color: AppColors.bgWhite.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Нет сообщений',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.bgWhite.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              reverse: true,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                // Get current user ID from AuthBloc
                                final authState = context.read<AuthBloc>().state;
                                final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;

                                // Compare senderId as strings to handle type mismatches
                                final isCurrentUser = message.senderId?.toString() == currentUserId?.toString();

                                return MessageBubble(
                                  message: message,
                                  isCurrentUser: isCurrentUser,
                                  showSenderName: widget.chat.isGroup == true,
                                );
                              },
                            ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withValues(alpha: 0.9),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.bgWhite.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _messageController,
                          placeholder: 'Введите сообщение...',
                          placeholderStyle: TextStyle(
                            color: AppColors.bgWhite.withValues(alpha: 0.5),
                          ),
                          style: TextStyle(color: AppColors.bgWhite),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.bgWhite.withValues(alpha: 0.1),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.dynamicPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.showSenderName,
  });

  @override
  Widget build(BuildContext context) {
    // Time and status row/column
    final timeWidget = isCurrentUser
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status icon first for current user
              _buildDeliveryStatus(context, message.deliveryStatus),
              const SizedBox(width: 4),
              // Then time
              Text(
                _formatTime(message.createdAt),
                style: AppTextStyles.postTime.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          )
        : Text(
            _formatTime(message.createdAt),
            style: AppTextStyles.postTime.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          );

    // Message bubble
    final messageBubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? context.dynamicPrimaryColor.withValues(alpha: 0.3) // Lighter for own messages
            : context.dynamicPrimaryColor.withValues(alpha: 0.1), // Very transparent for others
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.bgWhite.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show sender name for group chats (not for current user)
          if (showSenderName && !isCurrentUser && message.senderName != null) ...[
            Text(
              message.senderName!,
              style: AppTextStyles.body.copyWith(
                color: context.dynamicPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
          // Message content
          Text(
            message.content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.bgWhite,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isCurrentUser ? [
          // For current user: time/status first, then message bubble
          timeWidget,
          const SizedBox(width: 8),
          messageBubble,
        ] : [
          // For others: message bubble first, then time
          messageBubble,
          const SizedBox(width: 8),
          timeWidget,
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else {
      return '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildDeliveryStatus(BuildContext context, MessageDeliveryStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageDeliveryStatus.sending:
        icon = CupertinoIcons.clock;
        color = AppColors.bgWhite.withValues(alpha: 0.5);
        break;
      case MessageDeliveryStatus.sent:
        icon = CupertinoIcons.check_mark;
        color = AppColors.bgWhite.withValues(alpha: 0.7);
        break;
      case MessageDeliveryStatus.delivered:
        icon = CupertinoIcons.check_mark_circled;
        color = context.dynamicPrimaryColor;
        break;
      case MessageDeliveryStatus.failed:
        icon = CupertinoIcons.exclamationmark_triangle;
        color = Colors.red;
        break;
      case MessageDeliveryStatus.read:
        icon = CupertinoIcons.check_mark_circled_solid;
        color = context.dynamicPrimaryColor;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }
}
