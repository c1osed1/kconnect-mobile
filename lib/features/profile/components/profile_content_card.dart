/// Основная карточка контента профиля
///
/// Содержит информацию "О себе", аватар со статистикой и статус пользователя.
/// Объединяет все основные компоненты профиля в единую карточку.
library;

import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_colors.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/following_info.dart';
import '../presentation/blocs/profile_state.dart';
import 'profile_avatar_stats.dart';
import 'profile_status_display.dart';

/// Виджет основной карточки контента профиля
///
/// Комплексный компонент, объединяющий все ключевые элементы профиля:
/// описание, аватар со статистикой, статус пользователя в единой карточке.
class ProfileContentCard extends StatelessWidget {
  final UserProfile profile;
  final FollowingInfo? followingInfo;
  final ProfileLoaded profileState;
  final Color accentColor;
  final VoidCallback? onEditPressed;
  final VoidCallback onFollowPressed;
  final VoidCallback onUnfollowPressed;

  const ProfileContentCard({
    super.key,
    required this.profile,
    required this.followingInfo,
    required this.profileState,
    required this.accentColor,
    required this.onEditPressed,
    required this.onFollowPressed,
    required this.onUnfollowPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDark.withValues(alpha:0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0).copyWith(top: 10, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // About section
              if (profile.about?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                Text(
                  profile.about!,
                  style: AppTextStyles.body,
                ),
              ],
              // Avatar and Stats in row
              const SizedBox(height: 12),
              ProfileAvatarStats(
                profile: profile,
                followingInfo: followingInfo,
                isOwnProfile: profileState.isOwnProfile,
                isSkeleton: profileState.isSkeleton,
                accentColor: accentColor,
                onEditPressed: onEditPressed,
                onFollowPressed: onFollowPressed,
                onUnfollowPressed: onUnfollowPressed,
              ),
              // Status below profile, above feed
              if (profile.statusText?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                ProfileStatusDisplay(statusText: profile.statusText!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
