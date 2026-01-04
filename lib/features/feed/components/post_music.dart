import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/profile_accent_color_provider.dart';
import '../../music/domain/models/track.dart';
import '../../music/presentation/blocs/playback_bloc.dart';

/// Утилита для форматирования длительности трека в формат MM:SS
String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

/// Компонент для отображения музыкальных треков в постах
///
/// Показывает список прикрепленных музыкальных треков с обложками,
/// названиями, исполнителями и кнопками воспроизведения.
/// Интегрируется с системой воспроизведения музыки.
class PostMusic extends StatelessWidget {
  final List<Track> tracks;

  const PostMusic({
    super.key,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tracks.map((track) => _TrackRow(track: track)).toList(),
      ),
    );
  }
}

/// Виджет для отображения отдельного трека
class _TrackRow extends StatelessWidget {
  final Track track;

  const _TrackRow({
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    final durationText = _formatDuration(track.durationMs ~/ 1000);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: (0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Обложка альбома
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ImageUtils.buildAlbumArt(
                ImageUtils.getCompleteImageUrl(track.coverPath),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Информация о треке
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название трека
                Text(
                  track.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Исполнитель
                Text(
                  track.artist,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Длительность и кнопка воспроизведения
          Row(
            children: [
              // Длительность
              Text(
                durationText,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              // Кнопка воспроизведения
              GestureDetector(
                onTap: () => _playTrack(context, track),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.profileAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.play_fill,
                    color: AppColors.bgWhite,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playTrack(BuildContext context, Track track) {
    context.read<PlaybackBloc>().add(PlaybackPlayRequested(track));
  }
}
