/// Горизонтальный список треков секции с shimmer-загрузкой
///
/// Отображает список треков в горизонтальной прокрутке.
/// Поддерживает состояния загрузки с shimmer-эффектом.
/// Используется для отображения треков в различных секциях музыки.
library;

import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_colors.dart';
import '../domain/models/track.dart';
import '../presentation/blocs/music_state.dart';
import 'track_card.dart';

/// Виджет горизонтального списка треков с загрузкой
///
/// Показывает треки в горизонтальном списке с поддержкой
/// различных состояний загрузки и пустых данных.
class SectionList extends StatelessWidget {
  final List<Track> items;
  final MusicLoadStatus status;
  final Function(Track)? onTrackTap;
  final Function(Track)? onTrackPlay;
  final Function(Track)? onTrackLike;

  const SectionList({
    super.key,
    required this.items,
    required this.status,
    this.onTrackTap,
    this.onTrackPlay,
    this.onTrackLike,
  });

  @override
  Widget build(BuildContext context) {
    if (status == MusicLoadStatus.loading && items.isEmpty) {
      return SizedBox(
        height: 220,
        child: Shimmer.fromColors(
          baseColor: AppColors.bgCard,
          highlightColor: AppColors.bgCard.withValues(alpha: 0.5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5, // Show 5 shimmer placeholders
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: EdgeInsets.only(right: index == 4 ? 0 : 16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album art placeholder
                    Container(
                      height: 140,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Title placeholder
                    Container(
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppColors.bgCard,
                    ),
                    // Artist placeholder
                    Container(
                      height: 14,
                      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      width: 100,
                      color: AppColors.bgCard,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return TrackCard(
            key: ValueKey(item.id),
            track: item,
            onTap: onTrackTap != null ? () => onTrackTap!(item) : null,
            onPlay: onTrackPlay != null ? () => onTrackPlay!(item) : null,
            onLike: onTrackLike != null ? () => onTrackLike!(item) : null,
          );
        },
      ),
    );
  }
}
