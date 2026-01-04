/// Компонент аватара и статистики профиля пользователя
///
/// Отображает аватар пользователя, статистику (подписки/подписчики/посты)
/// и кнопку действия (редактировать/подписаться/отписаться).
/// Поддерживает различные состояния взаимоотношений между пользователями.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/constants.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/widgets/authorized_cached_network_image.dart';
import '../../../core/media_item.dart';
import '../../../routes/route_names.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/following_info.dart';

/// Виджет аватара и статистики профиля
///
/// Комплексный компонент для отображения основной информации о профиле:
/// аватар, статистика подписок, кнопка действия в зависимости от отношений.
class ProfileAvatarStats extends StatefulWidget {
  final UserProfile profile;
  final FollowingInfo? followingInfo;
  final bool isOwnProfile;
  final bool isSkeleton;
  final Color accentColor;
  final VoidCallback? onEditPressed;
  final Function()? onFollowPressed;
  final Function()? onUnfollowPressed;

  const ProfileAvatarStats({
    super.key,
    required this.profile,
    this.followingInfo,
    this.isOwnProfile = false,
    this.isSkeleton = false,
    required this.accentColor,
    this.onEditPressed,
    this.onFollowPressed,
    this.onUnfollowPressed,
  });

  @override
  State<ProfileAvatarStats> createState() => _ProfileAvatarStatsState();
}

class _ProfileAvatarStatsState extends State<ProfileAvatarStats> {
  bool get _isAccentWhite => widget.accentColor.computeLuminance() > 0.85;

  String get _buttonText {
    if (widget.followingInfo == null) {
      return 'Загрузка...';
    }

    final isFriend = widget.followingInfo!.currentUserIsFriend;
    final isFollowing = widget.followingInfo!.currentUserFollows;
    final followsBack = widget.followingInfo!.followsBack;

    if (followsBack && isFollowing) {
      return 'Вы друзья';
    } else if (isFriend) {
      return 'Вы друзья';
    } else if (followsBack && !isFollowing) {
      return 'Подписан на вас';
    } else if (isFollowing) {
      return 'Вы подписаны';
    } else {
      return 'Подписаться';
    }
  }

  Color get _buttonColor {
    if (widget.followingInfo == null) {
      return CupertinoColors.systemGrey;
    }

    final isFollowing = widget.followingInfo!.currentUserFollows;
    final followsBack = widget.followingInfo!.followsBack;

    if ((followsBack && isFollowing) || widget.followingInfo!.currentUserIsFriend) {
      return CupertinoColors.systemGreen;
    } else if (followsBack && !isFollowing) {
      return CupertinoColors.systemGrey;
    } else if (isFollowing) {
      return CupertinoColors.systemGrey;
    } else {
      return widget.accentColor;
    }
  }

  VoidCallback? get _buttonAction {
    if (widget.followingInfo == null) {
      return null;
    }

    final isFollowing = widget.followingInfo!.currentUserFollows;
    final followsBack = widget.followingInfo!.followsBack;

    if ((followsBack && isFollowing) || widget.followingInfo!.currentUserIsFriend) {
      return null; // No action for friends
    } else if (isFollowing) {
      return widget.onUnfollowPressed;
    } else {
      return widget.onFollowPressed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        _buildAvatar(),

        const SizedBox(width: 16),

        // Action Button and Stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action button (Edit/Follow)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: _buttonColor,
                  onPressed: widget.isOwnProfile ? widget.onEditPressed : _buttonAction,
                  child: Text(
                    widget.isOwnProfile ? 'Редактировать' : _buttonText,
                    style: TextStyle(
                      color: _buttonColor == widget.accentColor && _isAccentWhite
                          ? Colors.black
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: 'Подписки',
                    value: widget.profile.followingCount.toString(),
                    accentColor: widget.accentColor
                  ),
                  _StatItem(
                    label: 'Подписчики',
                    value: widget.profile.followersCount.toString(),
                    accentColor: widget.accentColor
                  ),
                  _StatItem(
                    label: 'Посты',
                    value: widget.profile.postsCount.toString(),
                    accentColor: widget.accentColor
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onAvatarTap() {
    if (widget.profile.avatarUrl != null &&
        widget.profile.avatarUrl!.isNotEmpty &&
        widget.profile.avatarUrl != AppConstants.userAvatarPlaceholder) {
      final mediaItem = MediaItem.image(widget.profile.avatarUrl!);
      Navigator.of(context).pushNamed(
        RouteNames.mediaViewer,
        arguments: {
          'items': [mediaItem],
          'initialIndex': 0,
        },
      );
    }
  }

  Widget _buildAvatar() {
    final String avatarUrl = (widget.profile.avatarUrl != null && widget.profile.avatarUrl!.isNotEmpty)
        ? widget.profile.avatarUrl!
        : AppConstants.userAvatarPlaceholder;

    return GestureDetector(
      onTap: _onAvatarTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgDark,
        ),
        child: ClipOval(
          child: AuthorizedCachedNetworkImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CupertinoActivityIndicator(radius: 15),
            errorWidget: (context, url, error) => CachedNetworkImage(
              imageUrl: AppConstants.userAvatarPlaceholder,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(radius: 15),
              errorWidget: (context, url, error) => Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.person,
                    size: 60,
                    color: CupertinoColors.systemGrey,
                  ),
                  if (widget.isSkeleton)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:0.3),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: accentColor),
        ),
        Text(
          label,
          style: AppTextStyles.postStats.copyWith(fontWeight: FontWeight.normal),
        ),
      ],
    );
  }
}
