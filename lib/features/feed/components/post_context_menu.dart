import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../features/feed/domain/models/post.dart';

/// Контекстное меню поста с опциями просмотров, копирования ссылки,
/// блокировки и жалобы
class PostContextMenu {
  /// Показать контекстное меню для поста
  static void show(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Информация о просмотрах
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.eye,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${post.viewsCount ?? 0} просмотров',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Разделитель
              Container(
                height: 1,
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),

              // Опции действий
              _buildMenuItem(
                context: context,
                icon: CupertinoIcons.link,
                title: 'Копировать ссылку',
                onTap: () => _copyLink(context, post),
              ),

              _buildMenuItem(
                context: context,
                icon: CupertinoIcons.nosign,
                title: 'Заблокировать',
                onTap: () => _blockUser(context),
                isDestructive: true,
              ),

              _buildMenuItem(
                context: context,
                icon: CupertinoIcons.exclamationmark_triangle,
                title: 'Пожаловаться',
                onTap: () => _reportPost(context),
                isDestructive: true,
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Создает элемент меню
  static Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: isDestructive ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Копирует ссылку на пост в буфер обмена
  static Future<void> _copyLink(BuildContext context, Post post) async {
    final link = 'https://k-connect.ru/post/${post.id}';
    await Clipboard.setData(ClipboardData(text: link));

    // Показать уведомление об успешном копировании
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ссылка скопирована',
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.bgCard,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Mock функция блокировки пользователя
  static void _blockUser(BuildContext context) {
    // TODO: Реализовать блокировку пользователя
  }

  /// Mock функция жалобы на пост
  static void _reportPost(BuildContext context) {
    // TODO: Реализовать жалобу на пост
  }
}
