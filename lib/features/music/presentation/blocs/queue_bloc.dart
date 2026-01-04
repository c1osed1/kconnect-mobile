/// BLoC для управления очередью воспроизведения музыки
///
/// Управляет очередью треков, включая добавление, удаление, переключение
/// между треками, shuffle режим и бесконечное воспроизведение vibe.
/// Поддерживает различные контексты очередей (favorites, all tracks, vibe)
library;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/models/queue_state.dart';
import '../../domain/models/queue.dart';
import '../../domain/models/track.dart';
import 'queue_event.dart';

/// BLoC класс для управления очередью воспроизведения
///
/// Обрабатывает все операции с очередью: создание очередей из разных источников,
/// навигация между треками, пагинация, shuffle и специальные режимы воспроизведения.
/// Поддерживает бесконечное воспроизведение для vibe плейлиста.
class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final MusicRepository _musicRepository;

  QueueBloc({required MusicRepository musicRepository})
      : _musicRepository = musicRepository,
        super(const QueueState()) {
    on<QueueInitialized>(_onInitialized);
    on<QueuePlayTracksRequested>(_onPlayTracksRequested);
    on<QueueNextRequested>(_onNextRequested);
    on<QueuePreviousRequested>(_onPreviousRequested);
    on<QueueLoadNextPageRequested>(_onLoadNextPageRequested);
    on<QueueAddPage>(_onAddPage);
    on<QueueAddVibeBatch>(_onAddVibeBatch);
    on<QueueShuffleRequested>(_onShuffleRequested);
    on<QueueClearRequested>(_onClearRequested);
    on<QueueErrorOccurred>(_onErrorOccurred);
  }

  void _onInitialized(QueueInitialized event, Emitter<QueueState> emit) {
    emit(const QueueState());
  }

  void _onPlayTracksRequested(QueuePlayTracksRequested event, Emitter<QueueState> emit) {

    try {
      final newState = state.withNewQueue(event.tracks, event.context, startIndex: event.startIndex);
      emit(newState);
    } catch (e) {
      emit(state.withError(e.toString()));
    }
  }

  void _onNextRequested(QueueNextRequested event, Emitter<QueueState> emit) async {
    if (state.currentQueue?.context == 'vibe' && !state.canGoNext) {

      emit(state.withLoadingNextPage());

      try {
        final newTracks = await _musicRepository.generateVibe();
        final newState = state.withAddedVibeBatch(newTracks);
        emit(newState);

        final nextState = newState.withNextTrack();
        emit(nextState);

        return;
      } catch (e) {
        emit(state.withError(e.toString()));
        return;
      }
    }

    if (!state.canGoNext) {
      return;
    }

    if (state.currentQueue?.shouldLoadNextPage ?? false) {
      
      await _loadNextPage(emit);

      if (!state.canGoNext) {
        return;
      }
    }

    final newState = state.withNextTrack();
    emit(newState);

  }

  void _onPreviousRequested(QueuePreviousRequested event, Emitter<QueueState> emit) {
    if (!state.canGoPrevious) {
      return;
    }

    final newState = state.withPreviousTrack();
    emit(newState);

  }

  void _onLoadNextPageRequested(QueueLoadNextPageRequested event, Emitter<QueueState> emit) async {
    if (state.currentQueue == null || state.isLoadingNextPage) return;

    final queue = state.currentQueue!;
    final context = queue.context;


    emit(state.withLoadingNextPage());

    try {
      final nextPage = (queue.loadedPages.keys.isEmpty ? 0 : queue.loadedPages.keys.reduce((a, b) => a > b ? a : b)) + 1;

      List<Track> newTracks;
      switch (context) {
        case 'favorites':
          final response = await _musicRepository.fetchFavorites(page: nextPage);
          newTracks = response.items;
          break;
        case 'allTracks':
          final response = await _musicRepository.fetchAllTracksPaginated(page: nextPage);
          newTracks = response.items;
          break;
        case 'vibe':
          newTracks = await _musicRepository.generateVibe();
          break;
        default:
          emit(state.withError('Unknown context: $context'));
          return;
      }

      if (context == 'vibe') {
        add(QueueAddVibeBatch(newTracks));
      } else {
        add(QueueAddPage(newTracks, nextPage));
      }

    } catch (e) {
      emit(state.withError(e.toString()));
    }
  }

  void _onAddPage(QueueAddPage event, Emitter<QueueState> emit) {
    if (state.currentQueue == null) return;

    final newState = state.withAddedPage(event.tracks, event.pageNumber);
    emit(newState);
  }

  void _onAddVibeBatch(QueueAddVibeBatch event, Emitter<QueueState> emit) {
    if (state.currentQueue == null) return;

    final newState = state.withAddedVibeBatch(event.tracks);
    emit(newState);

  }

  void _onShuffleRequested(QueueShuffleRequested event, Emitter<QueueState> emit) {
    if (state.currentQueue == null || state.currentQueue!.items.isEmpty) return;

    final currentTrack = state.currentTrack;
    final allItems = List<QueueItem>.from(state.currentQueue!.items);

    allItems.removeWhere((item) => item.track.id == currentTrack?.id);

    allItems.shuffle();

    final shuffledItems = currentTrack != null
        ? [QueueItem(track: currentTrack, context: state.currentQueue!.context, itemIndex: 0), ...allItems]
        : allItems;

    final shuffledQueue = state.currentQueue!.copyWith(
      items: shuffledItems,
      currentIndex: 0,
    );

    emit(state.copyWith(currentQueue: shuffledQueue));

  }

  void _onClearRequested(QueueClearRequested event, Emitter<QueueState> emit) {
    emit(state.withClearedQueue());
  }

  Future<void> _loadNextPage(Emitter<QueueState> emit) async {
    if (state.currentQueue == null || state.isLoadingNextPage) return;

    final queue = state.currentQueue!;
    final context = queue.context;

    emit(state.withLoadingNextPage());

    try {
      final nextPage = (queue.loadedPages.keys.isEmpty ? 0 : queue.loadedPages.keys.reduce((a, b) => a > b ? a : b)) + 1;

      List<Track> newTracks;
      switch (context) {
        case 'favorites':
          final response = await _musicRepository.fetchFavorites(page: nextPage);
          newTracks = response.items;
          break;
        case 'allTracks':
          final response = await _musicRepository.fetchAllTracksPaginated(page: nextPage);
          newTracks = response.items;
          break;
        case 'vibe':
          newTracks = await _musicRepository.generateVibe();
          break;
        default:
          emit(state.withError('Unknown context: $context'));
          return;
      }

      if (context == 'vibe') {
        final newState = state.withAddedVibeBatch(newTracks);
        emit(newState);
      } else {
        final newState = state.withAddedPage(newTracks, nextPage);
        emit(newState);
      }

    } catch (e) {
      emit(state.withError(e.toString()));
    }
  }

  void _onErrorOccurred(QueueErrorOccurred event, Emitter<QueueState> emit) {
    emit(state.withError(event.error));
  }
}
