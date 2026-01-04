/// Виджет секции избранных треков
///
/// Отображает список любимых треков пользователя с поддержкой
/// бесконечной прокрутки, пагинации и воспроизведения.
/// Включает состояния загрузки, ошибки и пустого списка.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../theme/app_text_styles.dart';
import '../domain/models/track.dart';
import '../presentation/blocs/playback_bloc.dart';
import '../presentation/blocs/queue_bloc.dart';
import '../presentation/blocs/queue_event.dart';
import '../presentation/blocs/music_bloc.dart';
import '../presentation/blocs/music_event.dart';
import '../presentation/blocs/music_state.dart';

import 'track_list_item.dart';

/// Виджет секции избранных треков с бесконечной прокруткой
class FavoritesSection extends StatefulWidget {
  const FavoritesSection({super.key});

  @override
  State<FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<FavoritesSection> {
  final ScrollController _scrollController = ScrollController();

  /// Инициализация виджета
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Загрузка данных при открытии секции
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final musicBloc = context.read<MusicBloc>();
        if (musicBloc.state.favorites.isEmpty && musicBloc.state.favoritesStatus == MusicLoadStatus.initial) {
          musicBloc.add(MusicFavoritesFetched());
        }
      }
    });
  }

  /// Освобождение ресурсов
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Обработчик прокрутки для бесконечной загрузки
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final musicBloc = context.read<MusicBloc>();
      if (musicBloc.state.favoritesHasNextPage && musicBloc.state.favoritesStatus != MusicLoadStatus.loading) {
        musicBloc.add(MusicFavoritesLoadMore());
      }
    }
  }

  /// Построение виджета с реакцией на изменения состояния
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        return _buildContent(state);
      },
    );
  }

  /// Построение содержимого в зависимости от состояния загрузки
  Widget _buildContent(MusicState state) {
    if (state.favoritesStatus == MusicLoadStatus.loading && state.favorites.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (state.favoritesStatus == MusicLoadStatus.failure && state.favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: () {
                context.read<MusicBloc>().add(MusicFavoritesFetched());
              },
              child: Text(
                'Повторить',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryPurple),
              ),
            ),
          ],
        ),
      );
    }

    if (state.favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.heart,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет любимых треков',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MusicBloc>().add(MusicFavoritesFetched(forceRefresh: true));
      },
      color: context.dynamicPrimaryColor,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == state.favorites.length) {
                  // Индикатор загрузки в конце списка
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  );
                }

                final track = state.favorites[index];
                return TrackListItem(
                  key: ValueKey(track.id),
                  track: track,
                  onTap: () => _onTrackPlay(track, state.favorites),
                  onLike: () => _onTrackLike(track),
                );
              },
              childCount: state.favorites.length + (state.favoritesHasNextPage ? 1 : 0),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  /// Обработчик воспроизведения трека
  ///
  /// Создает очередь с избранными треками и начинает воспроизведение выбранного трека
  void _onTrackPlay(Track track, List<Track> allTracks) {
    try {
      // Создание очереди с избранными треками
      final trackIndex = allTracks.indexWhere((t) => t.id == track.id);
      if (trackIndex != -1) {
        context.read<QueueBloc>().add(QueuePlayTracksRequested(allTracks, 'favorites', startIndex: trackIndex));
      }

      // Воспроизведение трека
      context.read<PlaybackBloc>().add(PlaybackPlayRequested(track));
    } catch (e) {
      // Обработка ошибки без показа пользователю
    }
  }

  /// Обработчик снятия лайка с трека
  ///
  /// Отправляет событие снятия лайка с трека в MusicBloc для обновления состояния
  void _onTrackLike(Track track) {
    try {
      context.read<MusicBloc>().add(MusicTrackLiked(track.id, track));
    } catch (e) {
      // Обработка ошибки без показа пользователю
    }
  }
}
