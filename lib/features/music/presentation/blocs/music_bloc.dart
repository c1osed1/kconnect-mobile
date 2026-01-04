/// BLoC для управления данными музыкальной библиотеки
///
/// Управляет загрузкой треков, плейлистов, чартов и поиском.
/// Поддерживает пагинацию и кэширование данных для оптимизации производительности.
library;

import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/models/track.dart';
import '../../domain/models/page_data.dart';
import 'music_event.dart';
import 'music_state.dart';

/// BLoC класс для управления музыкальными данными
///
/// Обрабатывает все операции с музыкальной библиотекой: загрузка треков,
/// управление избранными, поиск, работа с плейлистами.
/// Поддерживает кэширование и пагинацию для эффективной работы.
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final MusicRepository _musicRepository;
  CancelToken? _currentSearchCancelToken;

  MusicBloc({required MusicRepository musicRepository})
      : _musicRepository = musicRepository,
        super(const MusicState()) {
    on<MusicFavoritesFetched>(_onFavoritesFetched);
    on<MusicFavoritesLoadMore>(_onFavoritesLoadMore);
    on<MusicFavoritesLoadPrevious>(_onFavoritesLoadPrevious);
    on<MusicPopularFetched>(_onPopularFetched);
    on<MusicNewFetched>(_onNewFetched);
    on<MusicChartsFetched>(_onChartsFetched);
    on<MusicAllTracksPaginatedFetched>(_onAllTracksPaginatedFetched);
    on<MusicAllTracksPaginatedLoadMore>(_onAllTracksPaginatedLoadMore);
    on<MusicAllTracksPaginatedLoadPrevious>(_onAllTracksPaginatedLoadPrevious);
    on<MusicMyPlaylistsFetched>(_onMyPlaylistsFetched);
    on<MusicPublicPlaylistsFetched>(_onPublicPlaylistsFetched);
    on<MusicMyVibeFetched>(_onMyVibeFetched);
    on<MusicRecommendedArtistsFetched>(_onRecommendedArtistsFetched);
    on<MusicTrackLiked>(_onTrackLiked);
    on<MusicTracksSearched>(_onTracksSearched);
    on<MusicPlayedTracksHistoryLoaded>(_onPlayedTracksHistoryLoaded);
    on<MusicPlayedTrackSaved>(_onPlayedTrackSaved);
    on<MusicPlayedTracksHistoryCleared>(_onPlayedTracksHistoryCleared);
    on<MusicReset>(_onReset);
  }

  /// Обработчик загрузки избранных треков
  ///
  /// Выполняет первоначальную загрузку избранных треков пользователя.
  /// Создает PageData объект для поддержки пагинации.
  /// Логирует информацию о загруженной странице для отладки.
  void _onFavoritesFetched(MusicFavoritesFetched event, Emitter<MusicState> emit) async {
    if (state.favoritesStatus == MusicLoadStatus.loading) return;
    try {
      emit(state.copyWith(favoritesStatus: MusicLoadStatus.loading));
      final response = await _musicRepository.fetchFavorites();
      final hasPrevious = response.currentPage > 0;
      developer.log('MusicBloc: Favorites fetched - page: ${response.currentPage}, hasPrevious: $hasPrevious', name: 'MUSIC');

      final pageData = PageData<Track>(
        pageNumber: response.currentPage,
        items: response.items,
        hasNext: response.hasNextPage,
        hasPrevious: hasPrevious,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
      );

      emit(state.copyWith(
        favoritesPages: {response.currentPage: pageData},
        favoritesStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        favoritesStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки следующей страницы избранных треков
  ///
  /// Выполняет пагинацию вперед для списка избранных треков.
  /// Добавляет новую страницу в карту favoritesPages.
  /// Проверяет наличие следующей страницы перед загрузкой.
  void _onFavoritesLoadMore(MusicFavoritesLoadMore event, Emitter<MusicState> emit) async {
    if (!state.favoritesHasNextPage || state.favoritesStatus == MusicLoadStatus.loading) return;
    emit(state.copyWith(favoritesStatus: MusicLoadStatus.loading));
    try {
      final nextPage = state.favoritesCurrentPage + 1;
      final response = await _musicRepository.fetchFavorites(page: nextPage);
      final hasPrevious = response.currentPage > 0;
      developer.log('MusicBloc: FavoritesLoadMore - response.currentPage: ${response.currentPage}, hasPrevious: $hasPrevious', name: 'MUSIC');

      final pageData = PageData<Track>(
        pageNumber: response.currentPage,
        items: response.items,
        hasNext: response.hasNextPage,
        hasPrevious: hasPrevious,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
      );

      emit(state.copyWith(
        favoritesPages: {...state.favoritesPages, response.currentPage: pageData},
        favoritesStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        favoritesStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки предыдущей страницы избранных треков
  ///
  /// Выполняет пагинацию назад для списка избранных треков.
  /// Добавляет предыдущую страницу в карту favoritesPages.
  /// Проверяет наличие предыдущей страницы перед загрузкой.
  void _onFavoritesLoadPrevious(MusicFavoritesLoadPrevious event, Emitter<MusicState> emit) async {
    if (!state.favoritesHasPreviousPage || state.favoritesStatus == MusicLoadStatus.loading) return;

    emit(state.copyWith(favoritesStatus: MusicLoadStatus.loading));
    try {
      final previousPage = state.favoritesCurrentPage - 1;
      final response = await _musicRepository.fetchFavorites(page: previousPage);
      final hasPrevious = response.currentPage > 0;

      developer.log('MusicBloc: FavoritesLoadPrevious - loaded page $previousPage, '
                   'added ${response.items.length} tracks', name: 'MUSIC');

      final pageData = PageData<Track>(
        pageNumber: response.currentPage,
        items: response.items,
        hasNext: response.hasNextPage,
        hasPrevious: hasPrevious,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
      );

      emit(state.copyWith(
        favoritesPages: {...state.favoritesPages, response.currentPage: pageData},
        favoritesStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        favoritesStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки популярных треков
  ///
  /// Выполняет загрузку популярных треков с поддержкой кэширования.
  /// Проверяет актуальность данных и принудительную перезагрузку.
  /// Кэширует данные на время MusicState.dataCacheDuration.
  void _onPopularFetched(MusicPopularFetched event, Emitter<MusicState> emit) async {
    if (state.popularStatus == MusicLoadStatus.loading) return;

    final now = DateTime.now();
    final isDataFresh = state.lastDataRefresh != null &&
        now.difference(state.lastDataRefresh!) < MusicState.dataCacheDuration;

    if (!event.forceRefresh && isDataFresh) {
      return;
    }

    try {
      emit(state.copyWith(popularStatus: MusicLoadStatus.loading));
      final tracks = await _musicRepository.fetchPopularTracks();
      emit(state.copyWith(
        popularTracks: tracks,
        popularStatus: MusicLoadStatus.success,
        lastDataRefresh: now,
      ));
    } catch (e) {
      emit(state.copyWith(
        popularStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки новых треков
  ///
  /// Выполняет загрузку самых новых треков в музыкальной библиотеке.
  /// Не использует кэширование, всегда загружает свежие данные.
  void _onNewFetched(MusicNewFetched event, Emitter<MusicState> emit) async {
    if (state.newTracksStatus == MusicLoadStatus.loading) return;
    try {
      emit(state.copyWith(newTracksStatus: MusicLoadStatus.loading));
      final tracks = await _musicRepository.fetchNewTracks();
      emit(state.copyWith(
        newTracks: tracks,
        newTracksStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        newTracksStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки музыкальных чартов
  ///
  /// Выполняет загрузку чартов (рейтингов) треков по категориям.
  /// Поддерживает кэширование данных для оптимизации производительности.
  /// Возвращает Map с чартами по категориям.
  void _onChartsFetched(MusicChartsFetched event, Emitter<MusicState> emit) async {
    if (state.chartsStatus == MusicLoadStatus.loading) return;

    final now = DateTime.now();
    final isDataFresh = state.lastDataRefresh != null &&
        now.difference(state.lastDataRefresh!) < MusicState.dataCacheDuration;

    if (!event.forceRefresh && isDataFresh) {
      return;
    }

    try {
      emit(state.copyWith(chartsStatus: MusicLoadStatus.loading));
      final charts = await _musicRepository.fetchCharts();
      emit(state.copyWith(
        charts: charts,
        chartsStatus: MusicLoadStatus.success,
        lastDataRefresh: now,
      ));
    } catch (e) {
      emit(state.copyWith(
        chartsStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки всех треков с пагинацией (устаревший метод)
  ///
  /// Этот метод больше не используется в приложении.
  /// Оставлен для совместимости, но рекомендуется использовать
  /// другие методы загрузки треков по категориям.
  void _onAllTracksPaginatedFetched(MusicAllTracksPaginatedFetched event, Emitter<MusicState> emit) async {
    if (state.allTracksStatus == MusicLoadStatus.loading) return;
    try {
      emit(state.copyWith(allTracksStatus: MusicLoadStatus.loading));
      final response = await _musicRepository.fetchAllTracksPaginated();
      final hasPrevious = response.currentPage > 0;
      developer.log('MusicBloc: AllTracksPaginated fetched - page: ${response.currentPage}, hasPrevious: $hasPrevious', name: 'MUSIC');

      final pageData = PageData<Track>(
        pageNumber: response.currentPage,
        items: response.items,
        hasNext: response.hasNextPage,
        hasPrevious: hasPrevious,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
      );

      emit(state.copyWith(
        allTracksPages: {response.currentPage: pageData},
        allTracksStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        allTracksStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки следующей страницы всех треков
  ///
  /// Выполняет пагинацию вперед для списка всех треков.
  /// Добавляет новую страницу в карту allTracksPages.
  /// Проверяет наличие следующей страницы перед загрузкой.
  void _onAllTracksPaginatedLoadMore(MusicAllTracksPaginatedLoadMore event, Emitter<MusicState> emit) async {
    if (!state.allTracksHasNextPage || state.allTracksStatus == MusicLoadStatus.loading) return;
    emit(state.copyWith(allTracksStatus: MusicLoadStatus.loading));
    try {
      final nextPage = state.allTracksCurrentPage + 1;
      final response = await _musicRepository.fetchAllTracksPaginated(page: nextPage);
      final hasPrevious = response.currentPage > 0;
      developer.log('MusicBloc: AllTracksPaginatedLoadMore - response.currentPage: ${response.currentPage}, hasPrevious: $hasPrevious', name: 'MUSIC');

      final pageData = PageData<Track>(
        pageNumber: response.currentPage,
        items: response.items,
        hasNext: response.hasNextPage,
        hasPrevious: hasPrevious,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
      );

      emit(state.copyWith(
        allTracksPages: {...state.allTracksPages, response.currentPage: pageData},
        allTracksStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        allTracksStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки предыдущей страницы всех треков
  ///
  /// Выполняет пагинацию назад для списка всех треков.
  /// Добавляет предыдущую страницу в карту allTracksPages.
  /// Проверяет наличие предыдущей страницы перед загрузкой.
  void _onAllTracksPaginatedLoadPrevious(MusicAllTracksPaginatedLoadPrevious event, Emitter<MusicState> emit) async {
    if (!state.allTracksHasPreviousPage || state.allTracksStatus == MusicLoadStatus.loading) return;

    emit(state.copyWith(allTracksStatus: MusicLoadStatus.loading));
    try {
      final previousPage = state.allTracksCurrentPage - 1;
      final response = await _musicRepository.fetchAllTracksPaginated(page: previousPage);
      final hasPrevious = response.currentPage > 0;

      developer.log('MusicBloc: AllTracksPaginatedLoadPrevious - loaded page $previousPage, '
                   'added ${response.items.length} tracks', name: 'MUSIC');

      final pageData = PageData<Track>(
        pageNumber: response.currentPage,
        items: response.items,
        hasNext: response.hasNextPage,
        hasPrevious: hasPrevious,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
      );

      emit(state.copyWith(
        allTracksPages: {...state.allTracksPages, response.currentPage: pageData},
        allTracksStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        allTracksStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки плейлистов пользователя
  ///
  /// Выполняет загрузку списка плейлистов, созданных текущим пользователем.
  /// Обновляет состояние с полученными плейлистами и информацией о пагинации.
  void _onMyPlaylistsFetched(MusicMyPlaylistsFetched event, Emitter<MusicState> emit) async {
    if (state.myPlaylistsStatus == MusicLoadStatus.loading) return;
    try {
      emit(state.copyWith(myPlaylistsStatus: MusicLoadStatus.loading));
      final response = await _musicRepository.fetchMyPlaylists();
      emit(state.copyWith(
        myPlaylists: response.items,
        myPlaylistsStatus: MusicLoadStatus.success,
        myPlaylistsCurrentPage: response.currentPage,
        myPlaylistsHasNextPage: response.hasNextPage,
      ));
    } catch (e) {
      emit(state.copyWith(
        myPlaylistsStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки публичных плейлистов
  ///
  /// Выполняет загрузку списка публичных плейлистов от всех пользователей.
  /// Обновляет состояние с полученными плейлистами и информацией о пагинации.
  void _onPublicPlaylistsFetched(MusicPublicPlaylistsFetched event, Emitter<MusicState> emit) async {
    if (state.publicPlaylistsStatus == MusicLoadStatus.loading) return;
    try {
      emit(state.copyWith(publicPlaylistsStatus: MusicLoadStatus.loading));
      final response = await _musicRepository.fetchPublicPlaylists();
      emit(state.copyWith(
        publicPlaylists: response.items,
        publicPlaylistsStatus: MusicLoadStatus.success,
        publicPlaylistsCurrentPage: response.currentPage,
        publicPlaylistsHasNextPage: response.hasNextPage,
      ));
    } catch (e) {
      emit(state.copyWith(
        publicPlaylistsStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки персонализированных треков Vibe
  ///
  /// Выполняет загрузку треков, подобранных алгоритмом Vibe
  /// на основе предпочтений пользователя.
  void _onMyVibeFetched(MusicMyVibeFetched event, Emitter<MusicState> emit) async {
    if (state.vibeStatus == MusicLoadStatus.loading) return;
    try {
      emit(state.copyWith(vibeStatus: MusicLoadStatus.loading));
      final tracks = await _musicRepository.fetchMyVibe();
      emit(state.copyWith(
        vibeTracks: tracks,
        vibeStatus: MusicLoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        vibeStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик загрузки рекомендованных исполнителей
  ///
  /// Выполняет загрузку списка рекомендованных исполнителей.
  /// Поддерживает кэширование данных для оптимизации производительности.
  void _onRecommendedArtistsFetched(MusicRecommendedArtistsFetched event, Emitter<MusicState> emit) async {
    if (state.recommendedArtistsStatus == MusicLoadStatus.loading) return;

    final now = DateTime.now();
    final isDataFresh = state.lastDataRefresh != null &&
        now.difference(state.lastDataRefresh!) < MusicState.dataCacheDuration;

    if (!event.forceRefresh && isDataFresh && state.recommendedArtists.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(recommendedArtistsStatus: MusicLoadStatus.loading));
      final artists = await _musicRepository.fetchRecommendedArtists();
      emit(state.copyWith(
        recommendedArtists: artists,
        recommendedArtistsStatus: MusicLoadStatus.success,
        lastDataRefresh: now,
      ));
    } catch (e) {
      emit(state.copyWith(
        recommendedArtistsStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик постановки/снятия лайка с трека
  ///
  /// Переключает статус лайка для указанного трека.
  /// Обновляет состояние трека во всех коллекциях, где он присутствует.
  /// Синхронизирует изменения между избранными, популярными, новыми треками и т.д.
  void _onTrackLiked(MusicTrackLiked event, Emitter<MusicState> emit) async {
    try {
      await _musicRepository.toggleLikeTrack(event.trackId);

      final updatedTrack = event.track.copyWith(isLiked: !event.track.isLiked);

      emit(state.copyWith(
        favoritesPages: _updateTrackInFavoritesPages(state.favoritesPages, updatedTrack),
        allTracksPages: _updateTrackInAllTracksPages(state.allTracksPages, updatedTrack),
        popularTracks: _updateTrackInList(state.popularTracks, updatedTrack),
        newTracks: _updateTrackInList(state.newTracks, updatedTrack),
        allTracks: _updateTrackInList(state.allTracks, updatedTrack),
        allTracksPaginated: _updateTrackInList(state.allTracksPaginated, updatedTrack),
        vibeTracks: _updateTrackInList(state.vibeTracks, updatedTrack),
        charts: state.charts.map((key, tracks) => MapEntry(
          key,
          tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList(),
        )),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик сброса состояния MusicBloc
  ///
  /// Сбрасывает все данные и возвращает BLoC в начальное состояние.
  /// Используется для полной очистки данных при выходе из аккаунта или перезагрузке.
  void _onReset(MusicReset event, Emitter<MusicState> emit) {
    emit(const MusicState());
  }

  /// Обновляет трек в списке треков
  ///
  /// Заменяет трек с указанным ID на обновленную версию.
  /// Используется для синхронизации статуса лайка во всех коллекциях.
  ///
  /// [tracks] - исходный список треков
  /// [updatedTrack] - трек с обновленными данными
  /// Returns: новый список с обновленным треком
  List<Track> _updateTrackInList(List<Track> tracks, Track updatedTrack) {
    return tracks.map((t) => t.id == updatedTrack.id ? updatedTrack : t).toList();
  }

  /// Обновляет трек в страницах избранных треков
  ///
  /// Проходит по всем страницам избранных треков и обновляет
  /// трек с указанным ID на обновленную версию.
  /// Необходим для синхронизации статуса лайка в пагинированных данных.
  ///
  /// [favoritesPages] - карта страниц с избранными треками
  /// [updatedTrack] - трек с обновленными данными
  /// Returns: новая карта страниц с обновленным треком
  Map<int, PageData<Track>> _updateTrackInFavoritesPages(
    Map<int, PageData<Track>> favoritesPages,
    Track updatedTrack,
  ) {
    return favoritesPages.map((pageNumber, pageData) {
      final updatedItems = pageData.items.map((track) =>
        track.id == updatedTrack.id ? updatedTrack : track
      ).toList();

      return MapEntry(
        pageNumber,
        PageData<Track>(
          pageNumber: pageData.pageNumber,
          items: updatedItems,
          hasNext: pageData.hasNext,
          hasPrevious: pageData.hasPrevious,
          totalPages: pageData.totalPages,
          totalItems: pageData.totalItems,
        ),
      );
    });
  }

  /// Обновляет трек в страницах всех треков
  ///
  /// Проходит по всем страницам всех треков и обновляет
  /// трек с указанным ID на обновленную версию.
  /// Необходим для синхронизации статуса лайка в пагинированных данных.
  ///
  /// [allTracksPages] - карта страниц со всеми треками
  /// [updatedTrack] - трек с обновленными данными
  /// Returns: новая карта страниц с обновленным треком
  Map<int, PageData<Track>> _updateTrackInAllTracksPages(
    Map<int, PageData<Track>> allTracksPages,
    Track updatedTrack,
  ) {
    return allTracksPages.map((pageNumber, pageData) {
      final updatedItems = pageData.items.map((track) =>
        track.id == updatedTrack.id ? updatedTrack : track
      ).toList();

      return MapEntry(
        pageNumber,
        PageData<Track>(
          pageNumber: pageData.pageNumber,
          items: updatedItems,
          hasNext: pageData.hasNext,
          hasPrevious: pageData.hasPrevious,
          totalPages: pageData.totalPages,
          totalItems: pageData.totalItems,
        ),
      );
    });
  }

  /// Обработчик поиска треков
  ///
  /// Выполняет поиск треков по текстовому запросу.
  /// Использует кэширование результатов для оптимизации повторных поисков.
  /// Поддерживает отмену предыдущего поиска при новом запросе.
  void _onTracksSearched(MusicTracksSearched event, Emitter<MusicState> emit) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(state.copyWith(
        searchResults: [],
        searchStatus: MusicLoadStatus.initial,
      ));
      return;
    }

    if (state.searchCache.containsKey(query)) {
      emit(state.copyWith(
        searchResults: state.searchCache[query]!,
        searchStatus: MusicLoadStatus.success,
      ));
      return;
    }

    _currentSearchCancelToken?.cancel('New search started');
    _currentSearchCancelToken = CancelToken();

    try {
      emit(state.copyWith(searchStatus: MusicLoadStatus.loading));
      final results = await _musicRepository.searchTracks(query, cancelToken: _currentSearchCancelToken);

      final updatedCache = Map<String, List<Track>>.from(state.searchCache);
      updatedCache[query] = results;

      emit(state.copyWith(
        searchResults: results,
        searchStatus: MusicLoadStatus.success,
        searchCache: updatedCache,
      ));
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        emit(state.copyWith(
          searchStatus: MusicLoadStatus.failure,
          error: e.toString(),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        searchStatus: MusicLoadStatus.failure,
        error: e.toString(),
      ));
    } finally {
      _currentSearchCancelToken = null;
    }
  }

  /// Обработчик загрузки истории прослушанных треков
  ///
  /// Выполняет загрузку списка треков, которые пользователь прослушал ранее.
  /// Используется для отображения истории прослушиваний.
  void _onPlayedTracksHistoryLoaded(MusicPlayedTracksHistoryLoaded event, Emitter<MusicState> emit) async {
    try {
      const userId = 'current_user';
      final history = await _musicRepository.getPlayedTracksHistory(userId);
      emit(state.copyWith(playedTracksHistory: history));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик сохранения трека в историю прослушиваний
  ///
  /// Добавляет трек в начало списка истории прослушиваний.
  /// Ограничивает размер истории до 10 треков, удаляя самые старые.
  /// Удаляет дубликаты, если трек уже был в истории.
  void _onPlayedTrackSaved(MusicPlayedTrackSaved event, Emitter<MusicState> emit) async {
    try {
      const userId = 'current_user';
      await _musicRepository.savePlayedTrackToHistory(userId, event.track);

      final currentHistory = List<Track>.from(state.playedTracksHistory);
      currentHistory.removeWhere((track) => track.id == event.track.id);
      currentHistory.insert(0, event.track);
      if (currentHistory.length > 10) {
        currentHistory.removeRange(10, currentHistory.length);
      }

      emit(state.copyWith(playedTracksHistory: currentHistory));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик очистки истории прослушанных треков
  ///
  /// Полностью очищает список истории прослушиваний пользователя.
  /// Используется при выходе из аккаунта или ручной очистке истории.
  void _onPlayedTracksHistoryCleared(MusicPlayedTracksHistoryCleared event, Emitter<MusicState> emit) async {
    try {
      const userId = 'current_user';
      await _musicRepository.clearPlayedTracksHistory(userId);
      emit(state.copyWith(playedTracksHistory: []));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
