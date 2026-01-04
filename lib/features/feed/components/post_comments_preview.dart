/// Компонент для отображения превью последнего комментария поста
///
/// Показывает аватар, имя и текст последнего комментария.
/// Поддерживает индикацию количества комментариев и обработку нажатий.
library;

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Компонент превью комментариев поста
class PostCommentsPreview extends StatelessWidget {
  final Map<String, dynamic>? lastComment;
  final int totalComments;
  final VoidCallback? onTap;

  const PostCommentsPreview({
    super.key,
    this.lastComment,
    this.totalComments = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: lastComment == null
          ? Text(
              'Комментариев нет',
              style: AppTextStyles.postStats.copyWith(fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            )
          : Row(
              children: [
                // Аватарка комментария
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgCard,
                  ),
                  child: ClipOval(
                    child: _getCommentAvatar().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _getCommentAvatar(),
                            fit: BoxFit.cover,
                            memCacheWidth: 50,
                            memCacheHeight: 50,
                            placeholder: (context, url) => const CupertinoActivityIndicator(radius: 6),
                            errorWidget: (context, url, error) => const Icon(
                              CupertinoIcons.person,
                              size: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.person,
                            size: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                // Текст комментария
                Expanded(
                  child: Text(
                    _getCommentText(),
                    style: AppTextStyles.postStats.copyWith(fontWeight: FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Бейджик если >1 комментария
                if (totalComments > 1)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalComments',
                      style: AppTextStyles.postStats.copyWith(
                        color: AppColors.primaryPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _getCommentAvatar() {
    final user = lastComment?['user'] as Map<String, dynamic>?;
    return user?['avatar_url'] as String? ??
           user?['photo'] as String? ??
           '';
  }

  String _getCommentText() {
    final content = lastComment?['content'] as String?;
    final hasImage = lastComment?['image'] != null && (lastComment?['image'] as String?)?.isNotEmpty == true;

    if (content == null || content.isEmpty) {
      return hasImage ? 'Изображение' : '';
    }

    return content;
  }
}
