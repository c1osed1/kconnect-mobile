/// События для управления состоянием музыкальной библиотеки в BLoC
///
/// Определяет все возможные события, которые могут происходить
/// с данными музыкальной библиотеки: загрузка треков, поиск, управление плейлистами.
library;

import 'package:equatable/equatable.dart';
import '../../domain/models/track.dart';

/// Базовый класс для всех событий музыкальной библиотеки
abstract class MusicEvent extends Equatable {
  const MusicEvent();

  @override
  List<Object?> get props => [];
}

class MusicFavoritesFetched extends MusicEvent {
  const MusicFavoritesFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicFavoritesLoadMore extends MusicEvent {
  const MusicFavoritesLoadMore();

  @override
  List<Object?> get props => [];
}

class MusicFavoritesLoadPrevious extends MusicEvent {
  const MusicFavoritesLoadPrevious();

  @override
  List<Object?> get props => [];
}

class MusicPopularFetched extends MusicEvent {
  const MusicPopularFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicNewFetched extends MusicEvent {
  const MusicNewFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicChartsFetched extends MusicEvent {
  const MusicChartsFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicAllTracksPaginatedFetched extends MusicEvent {
  const MusicAllTracksPaginatedFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicAllTracksPaginatedLoadMore extends MusicEvent {
  const MusicAllTracksPaginatedLoadMore();

  @override
  List<Object?> get props => [];
}

class MusicAllTracksPaginatedLoadPrevious extends MusicEvent {
  const MusicAllTracksPaginatedLoadPrevious();

  @override
  List<Object?> get props => [];
}

class MusicMyPlaylistsFetched extends MusicEvent {
  const MusicMyPlaylistsFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicPublicPlaylistsFetched extends MusicEvent {
  const MusicPublicPlaylistsFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicMyVibeFetched extends MusicEvent {
  const MusicMyVibeFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicRecommendedArtistsFetched extends MusicEvent {
  const MusicRecommendedArtistsFetched({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class MusicTrackLiked extends MusicEvent {
  const MusicTrackLiked(this.trackId, this.track);

  final int trackId;
  final Track track;

  @override
  List<Object?> get props => [trackId, track];
}

class MusicTracksSearched extends MusicEvent {
  const MusicTracksSearched(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class MusicPlayedTracksHistoryLoaded extends MusicEvent {
  const MusicPlayedTracksHistoryLoaded();

  @override
  List<Object?> get props => [];
}

class MusicPlayedTrackSaved extends MusicEvent {
  const MusicPlayedTrackSaved(this.track);

  final Track track;

  @override
  List<Object?> get props => [track];
}

class MusicPlayedTracksHistoryCleared extends MusicEvent {
  const MusicPlayedTracksHistoryCleared();

  @override
  List<Object?> get props => [];
}

class MusicReset extends MusicEvent {
  const MusicReset();

  @override
  List<Object?> get props => [];
}
