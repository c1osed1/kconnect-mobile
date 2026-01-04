/// Секция плейлистов с прокруткой и загрузкой
///
/// Отображает мои плейлисты и публичные плейлисты в отдельных секциях.
/// Поддерживает пагинацию и pull-to-refresh для обновления данных.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../theme/app_text_styles.dart';
import '../domain/models/playlist.dart';
import '../presentation/blocs/music_bloc.dart';
import '../presentation/blocs/music_event.dart';
import '../presentation/blocs/music_state.dart';
import 'playlist_card.dart';

/// Виджет секции плейлистов с поддержкой пагинации
///
/// Отображает две секции: "Мои плейлисты" и "Публичные плейлисты".
/// Поддерживает бесконечную прокрутку и обновление данных.
class PlaylistsSection extends StatefulWidget {
  const PlaylistsSection({super.key});

  @override
  State<PlaylistsSection> createState() => _PlaylistsSectionState();
}

class _PlaylistsSectionState extends State<PlaylistsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final musicBloc = context.read<MusicBloc>();
        musicBloc.add(MusicMyPlaylistsFetched());
        musicBloc.add(MusicPublicPlaylistsFetched());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more for my playlists - disabled for now
      // if (state.myPlaylistsHasNextPage && state.myPlaylistsStatus != MusicLoadStatus.loading) {
      //   musicBloc.add(const MusicMyPlaylistsLoadMore());
      // }

      // Load more for public playlists - disabled for now
      // if (state.publicPlaylistsHasNextPage && state.publicPlaylistsStatus != MusicLoadStatus.loading) {
      //   musicBloc.add(const MusicPublicPlaylistsLoadMore());
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        return _buildContent(state);
      },
    );
  }

  Widget _buildContent(MusicState state) {
    if (state.myPlaylistsStatus == MusicLoadStatus.loading && state.myPlaylists.isEmpty &&
        state.publicPlaylistsStatus == MusicLoadStatus.loading && state.publicPlaylists.isEmpty) {
      return Center(
        child: const CupertinoActivityIndicator(),
      );
    }

    if (state.myPlaylistsStatus == MusicLoadStatus.failure && state.myPlaylists.isEmpty &&
        state.publicPlaylistsStatus == MusicLoadStatus.failure && state.publicPlaylists.isEmpty) {
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
                context.read<MusicBloc>().add(MusicMyPlaylistsFetched());
                context.read<MusicBloc>().add(MusicPublicPlaylistsFetched());
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

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MusicBloc>().add(MusicMyPlaylistsFetched(forceRefresh: true));
        context.read<MusicBloc>().add(MusicPublicPlaylistsFetched(forceRefresh: true));
      },
      color: context.dynamicPrimaryColor,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Мои плейлисты',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        if (state.myPlaylists.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.myPlaylists.length + (state.myPlaylistsHasNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.myPlaylists.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }

                  final playlist = state.myPlaylists[index];
                  return PlaylistCard(
                    key: ValueKey(playlist.id),
                    playlist: playlist,
                    onTap: () => _onPlaylistTap(playlist),
                  );
                },
              ),
            ),
          ),

        if (state.myPlaylists.isEmpty && state.myPlaylistsStatus != MusicLoadStatus.loading)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'У вас пока нет плейлистов',
                style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        if (state.publicPlaylists.isNotEmpty || state.publicPlaylistsStatus == MusicLoadStatus.loading)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Публичные плейлисты',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

        if (state.publicPlaylists.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.publicPlaylists.length + (state.publicPlaylistsHasNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.publicPlaylists.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }

                  final playlist = state.publicPlaylists[index];
                  return PlaylistCard(
                    key: ValueKey(playlist.id),
                    playlist: playlist,
                    onTap: () => _onPlaylistTap(playlist),
                  );
                },
              ),
            ),
          ),

        if (state.publicPlaylists.isEmpty && state.publicPlaylistsStatus != MusicLoadStatus.loading)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Публичные плейлисты не найдены',
                style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
        ],
      ),
    );
  }

  void _onPlaylistTap(Playlist playlist) {
    // TODO: Навигация в подробности плейлиста
    debugPrint('Tapped playlist: ${playlist.name}');
  }
}
