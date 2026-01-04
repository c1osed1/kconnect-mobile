/// Компонент заголовка профиля с SliverAppBar
///
/// Отображает баннер профиля, имя пользователя и статус верификации.
/// Использует SliverAppBar с гибким пространством для анимированного заголовка.
/// Поддерживает различные состояния загрузки и ошибок.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_colors.dart';
import '../../../services/api_client/dio_client.dart';
import '../domain/models/user_profile.dart';

/// Виджет заголовка профиля с баннером и информацией
///
/// Создает расширяемый заголовок профиля с баннером, именем пользователя
/// и статусом верификации. Использует SliverAppBar для плавной анимации.
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final Color accentColor;
  final bool isSkeleton;
  final bool isOtherProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.accentColor,
    this.isSkeleton = false,
    this.isOtherProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: false,
      floating: false,
      snap: false,
      expandedHeight: 220.0,
      stretch: false,
      leading: Container(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background banner
            _buildBannerBackground(context),
            // Shimmer for banner if skeleton and no banner
            if (isSkeleton && profile.bannerUrl == null)
              _buildBannerShimmer(accentColor),
            // Name and username with backdrop filter
            _buildNameOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerBackground(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: DioClient().getImageAuthHeaders(),
      builder: (context, snapshot) {
        return Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha:0.3),
            image: profile.bannerUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      profile.bannerUrl!,
                      headers: snapshot.data,
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBannerShimmer(Color accentColor) {
    return Positioned.fill(
      child: Container(
        color: accentColor.withValues(alpha:0.2),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildNameOverlay(BuildContext context) {
    final isAccentWhite = accentColor.computeLuminance() > 0.85;
    final displayName = profile.name.length > 30 ? '${profile.name.substring(0, 30)}...' : profile.name;

    return Positioned(
      bottom: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: accentColor.withValues(alpha:0.3),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  displayName,
                  style: AppTextStyles.h1.copyWith(color: isAccentWhite ? Colors.black : null),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  minFontSize: 14,
                  maxFontSize: 28,
                ),
                Row(
                  children: [
                    Text(
                      '@${profile.username}',
                      style: AppTextStyles.body.copyWith(color: isAccentWhite ? Colors.black : AppColors.textSecondary),
                    ),
                    if (profile.verification?.status == 'verified') ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
