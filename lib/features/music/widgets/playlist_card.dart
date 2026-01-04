/// Карточка плейлиста для отображения в списках
///
/// Отображает обложку плейлиста, название, владельца и количество треков.
/// Поддерживает нажатие для навигации к деталям плейлиста.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../domain/models/playlist.dart';

/// Виджет для отображения карточки плейлиста
///
/// Показывает обложку, название плейлиста, имя владельца
/// и количество треков в горизонтальном списке.
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = playlist.name;
    final ownerName = playlist.owner.name;
    final tracksCount = playlist.tracksCount;
    final coverImage = playlist.coverImage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 220,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ImageUtils.buildAlbumArt(
              _getCoverUrl(coverImage),
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
            // Title
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Owner and tracks count
            Text(
              '$ownerName • $tracksCount треков',
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getCoverUrl(String? coverImage) {
    if (coverImage != null && coverImage.isNotEmpty && !coverImage.contains('403')) {
      final url = ImageUtils.getCompleteImageUrl(coverImage);
      return url ?? 'https://k-connect.ru/static/uploads/system/album_placeholder.jpg';
    }
    // Fallback to default album placeholder
    return 'https://k-connect.ru/static/uploads/system/album_placeholder.jpg';
  }
}
