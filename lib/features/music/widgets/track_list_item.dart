/// Элемент списка треков для вертикального отображения
///
/// Отображает трек в формате списка с обложкой, названием,
/// исполнителем, длительностью и кнопкой лайка.
/// Используется в результатах поиска и истории прослушиваний.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/theme_extensions.dart';
import '../domain/models/track.dart';

/// Виджет элемента списка треков
///
/// Показывает информацию о треке в компактном вертикальном формате.
/// Поддерживает лайки и навигацию к воспроизведению.
class TrackListItem extends StatefulWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const TrackListItem({
    super.key,
    required this.track,
    this.onTap,
    this.onLike,
  });

  @override
  State<TrackListItem> createState() => _TrackListItemState();
}

class _TrackListItemState extends State<TrackListItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Album art
            ImageUtils.buildAlbumArt(
              ImageUtils.getCompleteImageUrl(widget.track.coverPath),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    widget.track.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Artist
                  Text(
                    widget.track.artist,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Duration
            Text(
              _formatDuration(widget.track.durationMs ~/ 1000),
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
            ),
            const SizedBox(width: 12),
            // Like button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onLike,
              child: Icon(
                widget.track.isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                size: 20,
                color: widget.track.isLiked ? context.dynamicPrimaryColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int duration) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
