import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/utils/theme_extensions.dart';
import '../../features/profile/components/swipe_pop_container.dart';
import 'widgets/section_list.dart';
import 'widgets/charts_section.dart';
import 'widgets/vibe_animated_card.dart';
import 'widgets/music_navigation_card.dart';
import 'widgets/favorites_section.dart';
import 'widgets/playlists_section.dart';
import 'widgets/all_tracks_section.dart';
import 'widgets/music_search_screen.dart';
import 'widgets/artists_section.dart';
import './domain/models/track.dart';
import './domain/models/artist.dart';
import './presentation/blocs/playback_bloc.dart';
import './presentation/blocs/queue_bloc.dart';
import './presentation/blocs/queue_event.dart';
import './presentation/blocs/music_bloc.dart';
import './presentation/blocs/music_event.dart';
import './presentation/blocs/music_state.dart';


enum MusicSection { home, favorites, playlists, allTracks, search }

class MusicHome extends StatefulWidget {
  final ValueNotifier<MusicSection>? sectionController;

  const MusicHome({super.key, this.sectionController});

  @override
  State<MusicHome> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<MusicHome> with AutomaticKeepAliveClientMixin {
  MusicSection currentSection = MusicSection.home;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.sectionController?.addListener(_onSectionControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final musicBloc = context.read<MusicBloc>();
        musicBloc.add(MusicMyVibeFetched());
        musicBloc.add(MusicPopularFetched());
        musicBloc.add(MusicChartsFetched());
        musicBloc.add(MusicRecommendedArtistsFetched());
      }
    });
  }

  @override
  void dispose() {
    widget.sectionController?.removeListener(_onSectionControllerChanged);
    super.dispose();
  }

  void _onSectionControllerChanged() {
    setState(() => currentSection = widget.sectionController?.value ?? MusicSection.home);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    switch (currentSection) {
      case MusicSection.home:
        return _buildHomeSection();
      case MusicSection.favorites:
        return _buildFavoritesSection();
      case MusicSection.playlists:
        return _buildPlaylistsSection();
      case MusicSection.allTracks:
        return _buildAllTracksSection();
      case MusicSection.search:
        return _buildSearchSection();
    }
  }

  Widget _buildHomeSection() {
    return SizedBox.expand(
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              final musicBloc = context.read<MusicBloc>();
              musicBloc.add(MusicPopularFetched(forceRefresh: true));
              musicBloc.add(MusicChartsFetched(forceRefresh: true));
            },
            color: context.dynamicPrimaryColor,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: VibeAnimatedCard(
                    onPressed: _onVibeTap,
                  ),
                ),
                SliverToBoxAdapter(
                  child: MusicNavigationCardsRow(
                    leftCard: MusicNavigationCard(
                      title: 'Мои любимые',
                      icon: CupertinoIcons.heart_fill,
                      onPressed: _onFavoritesTap,
                      color: AppColors.error,
                    ),
                    rightCard: MusicNavigationCard(
                      title: 'Плейлисты',
                      icon: CupertinoIcons.music_albums_fill,
                      onPressed: _onPlaylistsTap,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Популярные треки',
                      style: AppTextStyles.h3,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: BlocBuilder<MusicBloc, MusicState>(
                    builder: (context, state) {
                      return SectionList(
                        items: state.popularTracks,
                        status: state.popularStatus,
                        onTrackTap: (track) => _onTrackPlay(track, queueContext: 'popular', allTracks: state.popularTracks),
                        onTrackLike: (track) => _onTrackLike(track, context),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildRectangleCard(
                      'Все треки',
                      CupertinoIcons.music_note_list,
                      () => _onAllTracksTap(),
                      color: context.dynamicPrimaryColor,
                      textPosition: TextAlign.left,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ChartsSection(
                    onTrackTap: (track, chartType, allTracks) => _onTrackPlay(track, queueContext: chartType, allTracks: allTracks),
                    onTrackLike: (track) => _onTrackLike(track, context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Исполнители',
                      style: AppTextStyles.h3,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: BlocBuilder<MusicBloc, MusicState>(
                    builder: (context, state) {
                      return ArtistsSection(
                        items: state.recommendedArtists,
                        status: state.recommendedArtistsStatus,
                        onArtistTap: (artist) => _onArtistTap(artist),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 36),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    color: AppColors.bgDark,
                  ),
                ),
          ]
        )
      )
    )
  )
  );
  }

  Widget _buildFavoritesSection() {
    return SwipePopContainer(
      onPop: _goToHomeSection,
      child: const FavoritesSection(),
    );
  }

  Widget _buildPlaylistsSection() {
    return SwipePopContainer(
      onPop: _goToHomeSection,
      child: const PlaylistsSection(),
    );
  }

  Widget _buildAllTracksSection() {
    return SwipePopContainer(
      onPop: _goToHomeSection,
      child: const AllTracksSection(),
    );
  }

  Widget _buildSearchSection() {
    return SwipePopContainer(
      onPop: _goToHomeSection,
      child: const MusicSearchScreen(),
    );
  }



  Widget _buildRectangleCard(String title, IconData icon, VoidCallback onTap, {required Color color, TextAlign textPosition = TextAlign.center}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.button,
                textAlign: textPosition,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onVibeTap() {
    try {
      final musicBloc = context.read<MusicBloc>();
      final vibeTracks = musicBloc.state.vibeTracks;

      if (vibeTracks.isNotEmpty) {
        context.read<QueueBloc>().add(QueuePlayTracksRequested(vibeTracks, 'vibe', startIndex: 0));
        context.read<PlaybackBloc>().add(PlaybackPlayRequested(vibeTracks.first));
      }
    } catch (e) {
      // Ошибка
    }
  }

  void _onFavoritesTap() {
    setState(() => currentSection = MusicSection.favorites);
    widget.sectionController?.value = MusicSection.favorites;
    final musicBloc = context.read<MusicBloc>();
    musicBloc.add(MusicFavoritesFetched());
  }

  void _onPlaylistsTap() {
    setState(() => currentSection = MusicSection.playlists);
    widget.sectionController?.value = MusicSection.playlists;
    final musicBloc = context.read<MusicBloc>();
    musicBloc.add(MusicMyPlaylistsFetched());
    musicBloc.add(MusicPublicPlaylistsFetched());
  }

  void _onAllTracksTap() {
    setState(() => currentSection = MusicSection.allTracks);
    widget.sectionController?.value = MusicSection.allTracks;
    final musicBloc = context.read<MusicBloc>();
    musicBloc.add(MusicAllTracksPaginatedFetched());
  }

  void _onTrackPlay(Track track, {String? queueContext, List<Track>? allTracks}) {
    try {
      if (allTracks != null && allTracks.isNotEmpty) {
        final trackIndex = allTracks.indexWhere((t) => t.id == track.id);
        if (trackIndex != -1) {
          context.read<QueueBloc>().add(QueuePlayTracksRequested(allTracks, queueContext ?? 'unknown', startIndex: trackIndex));
        }
      }
      context.read<PlaybackBloc>().add(PlaybackPlayRequested(track));
    } catch (e) {
      // Ошибка
    }
  }

  void _onTrackLike(Track track, BuildContext context) async {
    try {
      context.read<MusicBloc>().add(MusicTrackLiked(track.id, track));
    } catch (e) {
      // Ошибка
    }
  }

  void _onArtistTap(Artist artist) {
    // TODO: Navigate to artist profile or tracks
  }

  void _goToHomeSection() {
    setState(() => currentSection = MusicSection.home);
    widget.sectionController?.value = MusicSection.home;
  }
}
