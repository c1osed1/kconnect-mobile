/// Секция чартов с табами для разных категорий треков
///
/// Отображает чарты в виде табов: Популярное, Топ, Популярные, Новые.
/// Поддерживает загрузку данных и отображение первых 5 треков в каждой категории.
/// Для популярных треков отображаются индикаторы тренда (рост/падение).
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/theme_extensions.dart';
import '../domain/models/track.dart';
import '../presentation/blocs/music_bloc.dart';
import '../presentation/blocs/music_state.dart';
import 'trend_indicator.dart';

/// Виджет секции чартов с переключаемыми табами
///
/// Показывает музыкальные чарты в разных категориях.
/// Поддерживает компактное отображение треков с номерами позиций.
class ChartsSection extends StatefulWidget {
  final Function(Track, String, List<Track>)? onTrackTap;
  final Function(Track)? onTrackPlay;
  final Function(Track)? onTrackLike;

  const ChartsSection({
    super.key,
    this.onTrackTap,
    this.onTrackPlay,
    this.onTrackLike,
  });

  @override
  State<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<ChartsSection> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _chartTabs = [
    {'key': 'popular', 'label': 'Популярное', 'icon': CupertinoIcons.chart_bar_fill},
    {'key': 'most_liked', 'label': 'Топ', 'icon': CupertinoIcons.heart_fill},
    {'key': 'most_played', 'label': 'Популярные', 'icon': CupertinoIcons.flame_fill},
    {'key': 'new_releases', 'label': 'Новые', 'icon': CupertinoIcons.star_fill},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        if (state.chartsStatus == MusicLoadStatus.loading && state.charts.isEmpty) {
          return SizedBox(
            height: 200,
            child: Shimmer.fromColors(
              baseColor: AppColors.bgCard,
              highlightColor: AppColors.bgCard.withValues(alpha: 0.5),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Загрузка чартов...'),
                ),
              ),
            ),
          );
        }

        if (state.charts.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        final selectedKey = _chartTabs[_selectedTabIndex]['key'] as String;
        final selectedTracks = state.charts[selectedKey] ?? [];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha:0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Чарты',
                    style: AppTextStyles.h3,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 4,
                  children: List.generate(_chartTabs.length, (index) => CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _selectedTabIndex = index),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == index
                            ? AppColors.primaryPurple.withValues(alpha:0.1)
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedTabIndex == index
                              ? AppColors.primaryPurple
                              : AppColors.bgCard,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _chartTabs[index]['icon'] as IconData? ?? CupertinoIcons.music_note,
                              size: 16,
                              color: _selectedTabIndex == index
                                  ? AppColors.primaryPurple
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _chartTabs[index]['label'] as String,
                                style: AppTextStyles.bodySecondary.copyWith(
                                  fontSize: 12,
                                  fontWeight: _selectedTabIndex == index
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _selectedTabIndex == index
                                      ? AppColors.primaryPurple
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 8),
              // Separator
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: AppColors.primaryPurple.withValues(alpha:0.1),
              ),
              const SizedBox(height: 8),
              // Content
              SizedBox(
                height: 440, // Increased height for 5 items to prevent overflow
                child: _buildChartList(selectedTracks),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartList(List<Track> tracks) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'Нет данных',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    // Limit to first 5 tracks and disable scrolling by using Column
    final limitedTracks = tracks.take(5).toList();
    final trackWidgets = List.generate(limitedTracks.length, (index) {
      final track = limitedTracks[index];
      return Container(
        margin: index == 4 ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
        child: _buildCompactTrackItem(track, index, tracks),
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: trackWidgets,
      ),
    );
  }

  Widget _buildCompactTrackItem(Track track, int index, List<Track> selectedTracks) {
    final title = track.title;
    final artist = track.artist;
    final albumArt = track.coverPath;
    final isLiked = track.isLiked;
    final selectedKey = _chartTabs[_selectedTabIndex]['key'] as String;

    return GestureDetector(
      onTap: widget.onTrackTap != null ? () => widget.onTrackTap!(track, selectedKey, selectedTracks) : null,
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Album art
            SizedBox(
              width: 54,
              height: 54,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ImageUtils.buildAlbumArt(
                  albumArt,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: SizedBox(
                height: 54,
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title with hashtag number
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' #${index + 1}',
                              style: TextStyle(
                                color: AppColors.primaryPurple,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Artist
                      Text(
                        artist,
                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Trend indicator (only for popular tracks)
            if (selectedKey == 'popular')
              TrendIndicator(
                trend: track.trend,
                changePercent: track.changePercent,
                iconSize: 12,
              ),
            // Like button
            if (widget.onTrackLike != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => widget.onTrackLike!(track),
                child: Icon(
                  isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  size: 18,
                  color: isLiked
                      ? context.dynamicPrimaryColor
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
