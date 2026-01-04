// Горизонтальный список исполнителей секции с shimmer-загрузкой
//
// Отображает список исполнителей в горизонтальной прокрутке.
// Поддерживает состояния загрузки с shimmer-эффектом.
// Используется для отображения рекомендованных исполнителей в музыке.
library;

import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_colors.dart';
import '../domain/models/artist.dart';
import '../presentation/blocs/music_state.dart';
import 'artist_card.dart';

/// Виджет горизонтального списка исполнителей с загрузкой
///
/// Показывает исполнителей в горизонтальном списке с поддержкой
/// различных состояний загрузки и пустых данных.
class ArtistsSection extends StatelessWidget {
  final List<Artist> items;
  final MusicLoadStatus status;
  final Function(Artist)? onArtistTap;

  const ArtistsSection({
    super.key,
    required this.items,
    required this.status,
    this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    if (status == MusicLoadStatus.loading && items.isEmpty) {
      return SizedBox(
        height: 160,
        child: Shimmer.fromColors(
          baseColor: AppColors.bgCard,
          highlightColor: AppColors.bgCard.withValues(alpha: 0.5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5, // Show 5 shimmer placeholders
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: index == 4 ? 0 : 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(height: 140),
              );
            },
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ArtistCard(
            key: ValueKey(item.id),
            artist: item,
            onTap: onArtistTap != null ? () => onArtistTap!(item) : null,
          );
        },
      ),
    );
  }
}
