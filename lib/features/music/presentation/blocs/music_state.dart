/// Состояния BLoC для музыкальной библиотеки
///
/// Определяет все возможные состояния управления данными музыкальной библиотеки,
/// включая статусы загрузки, кэширование и пагинацию треков и плейлистов.
library;

import 'package:equatable/equatable.dart';
import '../../domain/models/track.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/page_data.dart';
import '../../domain/models/artist.dart';

/// Статусы загрузки для операций с музыкальными данными
enum MusicLoadStatus { initial, loading, success, failure }

/// Состояние музыкальной библиотеки
///
/// Хранит текущее состояние всех музыкальных данных: треки, плейлисты,
/// статусы загрузки, кэширование поиска и историю прослушиваний.
class MusicState extends Equatable {
  static const Duration dataCacheDuration = Duration(minutes: 30);

  /// Страницы избранных треков: Map'<'pageNumber, PageData<Track>'>'
  final Map<int, PageData<Track>> favoritesPages;
  final MusicLoadStatus favoritesStatus;

  /// Обычные списки без пагинации
  final List<Track> popularTracks;
  final MusicLoadStatus popularStatus;

  final List<Track> newTracks;
  final MusicLoadStatus newTracksStatus;

  final Map<String, List<Track>> charts;
  final MusicLoadStatus chartsStatus;

  final DateTime? lastDataRefresh;

  /// Страницы всех треков
  final Map<int, PageData<Track>> allTracksPages;
  final MusicLoadStatus allTracksStatus;

  final List<Track> allTracksPaginated;
  final MusicLoadStatus allTracksPaginatedStatus;
  final int allTracksPaginatedCurrentPage;
  final bool allTracksPaginatedHasNextPage;
  final bool allTracksPaginatedHasPreviousPage;
  final int allTracksPaginatedTotalPages;

  /// Плейлисты
  final List<Playlist> myPlaylists;
  final MusicLoadStatus myPlaylistsStatus;
  final int myPlaylistsCurrentPage;
  final bool myPlaylistsHasNextPage;

  final List<Playlist> publicPlaylists;
  final MusicLoadStatus publicPlaylistsStatus;
  final int publicPlaylistsCurrentPage;
  final bool publicPlaylistsHasNextPage;

  final List<Track> vibeTracks;
  final MusicLoadStatus vibeStatus;

  final List<Artist> recommendedArtists;
  final MusicLoadStatus recommendedArtistsStatus;

  final List<Track> playedTracksHistory;
  final List<Track> searchResults;
  final MusicLoadStatus searchStatus;

  final Map<String, List<Track>> searchCache;

  final String? error;

  const MusicState({
    this.favoritesPages = const {},
    this.favoritesStatus = MusicLoadStatus.initial,
    this.popularTracks = const [],
    this.popularStatus = MusicLoadStatus.initial,
    this.newTracks = const [],
    this.newTracksStatus = MusicLoadStatus.initial,
    this.charts = const {},
    this.chartsStatus = MusicLoadStatus.initial,
    this.lastDataRefresh,
    this.allTracksPages = const {},
    this.allTracksStatus = MusicLoadStatus.initial,
    this.allTracksPaginated = const [],
    this.allTracksPaginatedStatus = MusicLoadStatus.initial,
    this.allTracksPaginatedCurrentPage = 1,
    this.allTracksPaginatedHasNextPage = true,
    this.allTracksPaginatedHasPreviousPage = false,
    this.allTracksPaginatedTotalPages = 1,
    this.myPlaylists = const [],
    this.myPlaylistsStatus = MusicLoadStatus.initial,
    this.myPlaylistsCurrentPage = 1,
    this.myPlaylistsHasNextPage = true,
    this.publicPlaylists = const [],
    this.publicPlaylistsStatus = MusicLoadStatus.initial,
    this.publicPlaylistsCurrentPage = 1,
    this.publicPlaylistsHasNextPage = true,
    this.vibeTracks = const [],
    this.vibeStatus = MusicLoadStatus.initial,
    this.recommendedArtists = const [],
    this.recommendedArtistsStatus = MusicLoadStatus.initial,
    this.playedTracksHistory = const [],
    this.searchResults = const [],
    this.searchStatus = MusicLoadStatus.initial,
    this.searchCache = const {},
    this.error,
  });

  /// Получить все избранные треки в плоском списке
  List<Track> get favorites {
    final sortedPages = favoritesPages.keys.toList()..sort();
    return sortedPages.expand((page) => favoritesPages[page]!.items).toList();
  }

  /// Получить все треки в плоском списке
  List<Track> get allTracks {
    final sortedPages = allTracksPages.keys.toList()..sort();
    return sortedPages.expand((page) => allTracksPages[page]!.items).toList();
  }

  /// Проверить, есть ли следующая страница для избранных
  bool get favoritesHasNextPage {
    final maxPage = favoritesPages.keys.isEmpty ? 0 : favoritesPages.keys.reduce((a, b) => a > b ? a : b);
    return favoritesPages[maxPage]?.hasNext ?? false;
  }

  /// Проверить, есть ли предыдущая страница для избранных
  bool get favoritesHasPreviousPage {
    final minPage = favoritesPages.keys.isEmpty ? 1 : favoritesPages.keys.reduce((a, b) => a < b ? a : b);
    return minPage > 1;
  }

  /// Получить текущую страницу для избранных (последнюю загруженную)
  int get favoritesCurrentPage {
    if (favoritesPages.isEmpty) return 1;
    return favoritesPages.keys.reduce((a, b) => a > b ? a : b);
  }

  /// Получить общее количество страниц для избранных
  int get favoritesTotalPages {
    if (favoritesPages.isEmpty) return 1;
    // Возвращаем максимальную страницу + 1, если есть следующая страница, иначе максимальную
    final maxPage = favoritesPages.keys.reduce((a, b) => a > b ? a : b);
    final pageData = favoritesPages[maxPage];
    return pageData?.hasNext ?? false ? maxPage + 1 : maxPage;
  }

  /// Аналогично для всех треков
  bool get allTracksHasNextPage {
    final maxPage = allTracksPages.keys.isEmpty ? 0 : allTracksPages.keys.reduce((a, b) => a > b ? a : b);
    return allTracksPages[maxPage]?.hasNext ?? false;
  }

  bool get allTracksHasPreviousPage {
    final minPage = allTracksPages.keys.isEmpty ? 1 : allTracksPages.keys.reduce((a, b) => a < b ? a : b);
    return minPage > 1;
  }

  int get allTracksCurrentPage {
    if (allTracksPages.isEmpty) return 1;
    return allTracksPages.keys.reduce((a, b) => a > b ? a : b);
  }

  MusicState copyWith({
    Map<int, PageData<Track>>? favoritesPages,
    MusicLoadStatus? favoritesStatus,
    List<Track>? favorites,
    int? favoritesCurrentPage,
    bool? favoritesHasNextPage,
    bool? favoritesHasPreviousPage,
    int? favoritesTotalPages,
    List<Track>? popularTracks,
    MusicLoadStatus? popularStatus,
    List<Track>? newTracks,
    MusicLoadStatus? newTracksStatus,
    Map<String, List<Track>>? charts,
    MusicLoadStatus? chartsStatus,
    DateTime? lastDataRefresh,
    Map<int, PageData<Track>>? allTracksPages,
    MusicLoadStatus? allTracksStatus,
    List<Track>? allTracks,
    List<Track>? allTracksPaginated,
    MusicLoadStatus? allTracksPaginatedStatus,
    int? allTracksPaginatedCurrentPage,
    bool? allTracksPaginatedHasNextPage,
    bool? allTracksPaginatedHasPreviousPage,
    int? allTracksPaginatedTotalPages,
    List<Playlist>? myPlaylists,
    MusicLoadStatus? myPlaylistsStatus,
    int? myPlaylistsCurrentPage,
    bool? myPlaylistsHasNextPage,
    List<Playlist>? publicPlaylists,
    MusicLoadStatus? publicPlaylistsStatus,
    int? publicPlaylistsCurrentPage,
    bool? publicPlaylistsHasNextPage,
    List<Track>? vibeTracks,
    MusicLoadStatus? vibeStatus,
    List<Artist>? recommendedArtists,
    MusicLoadStatus? recommendedArtistsStatus,
    List<Track>? playedTracksHistory,
    List<Track>? searchResults,
    MusicLoadStatus? searchStatus,
    Map<String, List<Track>>? searchCache,
    String? error,
  }) {
    return MusicState(
      favoritesPages: favoritesPages ?? this.favoritesPages,
      favoritesStatus: favoritesStatus ?? this.favoritesStatus,
      popularTracks: popularTracks ?? this.popularTracks,
      popularStatus: popularStatus ?? this.popularStatus,
      newTracks: newTracks ?? this.newTracks,
      newTracksStatus: newTracksStatus ?? this.newTracksStatus,
      charts: charts ?? this.charts,
      chartsStatus: chartsStatus ?? this.chartsStatus,
      lastDataRefresh: lastDataRefresh ?? this.lastDataRefresh,
      allTracksPages: allTracksPages ?? this.allTracksPages,
      allTracksStatus: allTracksStatus ?? this.allTracksStatus,
      allTracksPaginated: allTracksPaginated ?? this.allTracksPaginated,
      allTracksPaginatedStatus: allTracksPaginatedStatus ?? this.allTracksPaginatedStatus,
      allTracksPaginatedCurrentPage: allTracksPaginatedCurrentPage ?? this.allTracksPaginatedCurrentPage,
      allTracksPaginatedHasNextPage: allTracksPaginatedHasNextPage ?? this.allTracksPaginatedHasNextPage,
      allTracksPaginatedHasPreviousPage: allTracksPaginatedHasPreviousPage ?? this.allTracksPaginatedHasPreviousPage,
      allTracksPaginatedTotalPages: allTracksPaginatedTotalPages ?? this.allTracksPaginatedTotalPages,
      myPlaylists: myPlaylists ?? this.myPlaylists,
      myPlaylistsStatus: myPlaylistsStatus ?? this.myPlaylistsStatus,
      myPlaylistsCurrentPage: myPlaylistsCurrentPage ?? this.myPlaylistsCurrentPage,
      myPlaylistsHasNextPage: myPlaylistsHasNextPage ?? this.myPlaylistsHasNextPage,
      publicPlaylists: publicPlaylists ?? this.publicPlaylists,
      publicPlaylistsStatus: publicPlaylistsStatus ?? this.publicPlaylistsStatus,
      publicPlaylistsCurrentPage: publicPlaylistsCurrentPage ?? this.publicPlaylistsCurrentPage,
      publicPlaylistsHasNextPage: publicPlaylistsHasNextPage ?? this.publicPlaylistsHasNextPage,
      vibeTracks: vibeTracks ?? this.vibeTracks,
      vibeStatus: vibeStatus ?? this.vibeStatus,
      recommendedArtists: recommendedArtists ?? this.recommendedArtists,
      recommendedArtistsStatus: recommendedArtistsStatus ?? this.recommendedArtistsStatus,
      playedTracksHistory: playedTracksHistory ?? this.playedTracksHistory,
      searchResults: searchResults ?? this.searchResults,
      searchStatus: searchStatus ?? this.searchStatus,
      searchCache: searchCache ?? this.searchCache,
      error: error,
    );
  }

  /// Добавить страницу к избранным
  MusicState addFavoritesPage(PageData<Track> page) {
    return copyWith(
      favoritesPages: {...favoritesPages, page.pageNumber: page},
    );
  }

  /// Добавить страницу ко всем трекам
  MusicState addAllTracksPage(PageData<Track> page) {
    return copyWith(
      allTracksPages: {...allTracksPages, page.pageNumber: page},
    );
  }

  @override
  List<Object?> get props => [
    favoritesPages,
    favoritesStatus,
    popularTracks,
    popularStatus,
    newTracks,
    newTracksStatus,
    charts,
    chartsStatus,
    lastDataRefresh,
    allTracksPages,
    allTracksStatus,
    myPlaylists,
    myPlaylistsStatus,
    publicPlaylists,
    publicPlaylistsStatus,
    vibeTracks,
    vibeStatus,
    recommendedArtists,
    recommendedArtistsStatus,
    playedTracksHistory,
    searchResults,
    searchStatus,
    searchCache,
    error,
  ];
}
