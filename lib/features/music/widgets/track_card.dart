/// Карточка трека для отображения в горизонтальных списках
///
/// Отображает обложку трека, название, исполнителя, жанр и статус верификации.
/// Поддерживает различные действия: воспроизведение, лайк, навигация.
/// Используется в секциях музыки для показа треков.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/theme_extensions.dart';
import '../domain/models/track.dart';

/// Виджет карточки трека с обложкой и информацией
///
/// Показывает трек в компактном формате с обложкой,
/// названием, исполнителем и дополнительными элементами (лайк, верификация).
class TrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onLike;

  const TrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.onPlay,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final title = track.title;
    final artist = track.artist;
    final albumArt = track.coverPath;
    final genre = track.genre?.trim();
    final verified = track.verified;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 220,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art with overlay
            Stack(
              children: [
                ImageUtils.buildAlbumArt(
                  ImageUtils.getCompleteImageUrl(albumArt),
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                // Genre badge top-left
                if (genre != null && genre.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        genre,
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                // Verified badge top-right
                if (verified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.dynamicPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 12,
                        color: AppColors.bgWhite,
                      ),
                    ),
                  ),

              ],
            ),
            // Title
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist (single line to save space)
            Text(
              artist,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }



}
