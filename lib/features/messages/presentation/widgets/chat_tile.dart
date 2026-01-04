/// Виджет плитки чата для списка чатов
///
/// Отображает информацию о чате: аватар, название, последнее сообщение,
/// время и количество непрочитанных сообщений.
/// Поддерживает навигацию к экрану чата при нажатии.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/authorized_cached_network_image.dart';
import '../../domain/models/chat.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../chat_screen.dart';

/// Виджет плитки чата
class ChatTile extends StatelessWidget {
  final Chat chat;

  const ChatTile({
    super.key,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
        ),
        child: chat.avatar != null && chat.avatar!.isNotEmpty
            ? ClipOval(
                child: AuthorizedCachedNetworkImage(
                  imageUrl: chat.avatar!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    CupertinoIcons.person_fill,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    CupertinoIcons.person_fill,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ),
              )
            : Icon(
                CupertinoIcons.person_fill,
                color: AppColors.primaryPurple,
                size: 24,
              ),
      ),
      title: SizedBox(
        height: 54, // User-set height
        child: Stack(
          children: [
            // Main content row - only name and last message
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: name and last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Name at top left - aligned to baseline
                      Baseline(
                        baseline: 16.0,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          chat.title,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.bgWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Last message at bottom left - with proper width constraint
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 160, // Leave space for badge
                        child: chat.lastMessage != null
                            ? Text(
                                chat.lastMessage!.content,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                'Нет сообщений',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Time positioned at top right of entire container
            if (chat.lastMessage != null)
              Positioned(
                top: 0,
                right: 0,
                child: Baseline(
                  baseline: 16.0,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(
                    _formatChatTime(chat.lastMessage!.createdAt),
                    style: AppTextStyles.postTime.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            // Badge positioned at bottom right of entire container
            if (chat.unreadCount > 0)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: AppTextStyles.postTime.copyWith(
                      color: AppColors.bgWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      },
    );
  }

  String _formatChatTime(DateTime messageTime) {
    final now = DateTime.now();
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
    final today = DateTime(now.year, now.month, now.day);

    // If message is from today, show time (HH:MM)
    if (messageDate == today) {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
    // If message is older than 1 day, show date (DD.MM or DD.MM.YY)
    else {
      final yearsDiff = now.year - messageTime.year;
      if (yearsDiff == 0) {
        // Same year - show DD.MM
        return '${messageTime.day.toString().padLeft(2, '0')}.${messageTime.month.toString().padLeft(2, '0')}';
      } else {
        // Different year - show DD.MM.YY
        return '${messageTime.day.toString().padLeft(2, '0')}.${messageTime.month.toString().padLeft(2, '0')}.${(messageTime.year % 100).toString().padLeft(2, '0')}';
      }
    }
  }
}
