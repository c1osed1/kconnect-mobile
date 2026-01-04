/// Компонент действий поста с лайками, репостами и комментариями
///
/// Отображает кнопки взаимодействия с постом: лайк, репост, комментарии.
/// Показывает статистику взаимодействий и обрабатывает нажатия.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/widgets/profile_accent_color_provider.dart';
import 'post_comments_preview.dart';
import 'post_constants.dart';

/// Компонент действий поста (лайк, репост, комментарии)
class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likesCount;
  final int originalLikesCount;
  final Map<String, dynamic>? lastComment;
  final int commentsCount;
  final Function()? onLikePressed;
  final Function()? onRepostPressed;
  final Function()? onCommentsPressed;
  final bool isLikeProcessing;

  const PostActions({
    super.key,
    this.isLiked = false,
    this.likesCount = 0,
    this.originalLikesCount = 0,
    this.lastComment,
    this.commentsCount = 0,
    this.onLikePressed,
    this.onRepostPressed,
    this.onCommentsPressed,
    this.isLikeProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            // Лайк
            Flexible(
              flex: 0,
              child: GestureDetector(
                onTap: isLikeProcessing ? null : onLikePressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLikeProcessing)
                      const CupertinoActivityIndicator(radius: 8)
                    else
                      Icon(
                        CupertinoIcons.heart,
                        size: PostConstants.actionIconSize,
                        color: isLiked ? context.profileAccentColor : AppColors.textSecondary,
                      ),
                    const SizedBox(width: 4),
                    Text('$likesCount', style: AppTextStyles.postStats.copyWith(fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Комментарии
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PostConstants.borderRadius),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha:0.23), width: 1),
                ),
                child: PostCommentsPreview(
                  lastComment: lastComment,
                  totalComments: commentsCount,
                  onTap: onCommentsPressed,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Репост
            Flexible(
              flex: 0,
              child: GestureDetector(
                onTap: onRepostPressed,
                child: Icon(
                  CupertinoIcons.arrow_counterclockwise,
                  size: PostConstants.actionIconSize,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
