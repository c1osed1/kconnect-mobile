/// Заголовок экрана чужого профиля с кнопкой назад
///
/// Отображает кнопку возврата и имя пользователя для экранов
/// просмотра профилей других пользователей.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_colors.dart';

/// Виджет заголовка экрана чужого профиля
///
/// Показывает кнопку назад и имя пользователя в верхней части экрана
/// для навигации при просмотре профилей других пользователей.
class ProfileScreenHeader extends StatelessWidget {
  final String username;
  final Color accentColor;
  final VoidCallback onBackPressed;

  const ProfileScreenHeader({
    super.key,
    required this.username,
    required this.accentColor,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha:0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button with accent color
          GestureDetector(
            onTap: onBackPressed,
            child: Icon(
              CupertinoIcons.arrow_left,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Username
          Text(
            '@$username',
            style: AppTextStyles.postAuthor.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
