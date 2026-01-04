import 'package:equatable/equatable.dart';
import 'package:kconnect_mobile/features/music/domain/models/queue.dart';
import 'package:kconnect_mobile/features/music/domain/models/track.dart';

/// Состояние музыкальной очереди
///
/// Управляет состоянием воспроизведения музыки, включая текущую очередь треков,
/// статус загрузки и информацию о текущем треке.
/// Поддерживает различные типы очередей: пагинированные, бесконечные и конечные.
enum QueueLoadStatus {
  /// Начальное состояние
  initial,
  /// Загрузка данных
  loading,
  /// Успешная загрузка
  success,
  /// Ошибка загрузки
  failure
}

/// Модель состояния музыкальной очереди
///
/// Содержит информацию о текущей очереди воспроизведения, статусе загрузки
/// и методы для управления очередью треков.
class QueueState extends Equatable {
  final Queue? currentQueue;
  final QueueLoadStatus status;
  final String? error;
  final bool isLoadingNextPage;

  const QueueState({
    this.currentQueue,
    this.status = QueueLoadStatus.initial,
    this.error,
    this.isLoadingNextPage = false,
  });

  bool get hasQueue => currentQueue != null;
  bool get hasTracks => currentQueue?.items.isNotEmpty ?? false;
  bool get canGoNext => currentQueue?.hasNext ?? false;
  bool get canGoPrevious => currentQueue?.hasPrevious ?? false;

  QueueItem? get currentItem => currentQueue?.currentItem;
  Track? get currentTrack => currentQueue?.currentTrack;

  int get currentIndex => currentQueue?.currentIndex ?? 0;
  int get totalTracks => currentQueue?.items.length ?? 0;

  QueueState copyWith({
    Queue? currentQueue,
    QueueLoadStatus? status,
    String? error,
    bool? isLoadingNextPage,
  }) {
    return QueueState(
      currentQueue: currentQueue ?? this.currentQueue,
      status: status ?? this.status,
      error: error ?? this.error,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
    );
  }

  // Create a new queue from tracks
  QueueState withNewQueue(List<Track> tracks, String context, {int startIndex = 0}) {
    final queueType = _determineQueueType(context);
    final items = tracks.map((track) => QueueItem(
      track: track,
      context: context,
      pageIndex: queueType == QueueType.paginated ? 1 : -1, // API page 1 for paginated
      itemIndex: tracks.indexOf(track),
    )).toList();

    final queue = Queue(
      items: items,
      currentIndex: startIndex,
      type: queueType,
      context: context,
      loadedPages: queueType == QueueType.paginated ? {1: true} : {}, // Mark page 1 as loaded
    );

    return copyWith(
      currentQueue: queue,
      status: QueueLoadStatus.success,
      error: null,
      isLoadingNextPage: false,
    );
  }

  // Add page to existing paginated queue
  QueueState withAddedPage(List<Track> newTracks, int pageNumber) {
    if (currentQueue == null) return this;

    final updatedQueue = currentQueue!.addPage(newTracks, pageNumber);

    return copyWith(
      currentQueue: updatedQueue,
      isLoadingNextPage: false,
    );
  }

  // Add vibe batch to infinite queue
  QueueState withAddedVibeBatch(List<Track> newTracks) {
    if (currentQueue == null) return this;

    final updatedQueue = currentQueue!.addVibeBatch(newTracks);

    return copyWith(
      currentQueue: updatedQueue,
      isLoadingNextPage: false,
    );
  }

  // Move to next track
  QueueState withNextTrack() {
    if (!canGoNext || currentQueue == null) return this;

    final updatedQueue = currentQueue!.copyWith(
      currentIndex: currentQueue!.currentIndex + 1,
    );

    return copyWith(currentQueue: updatedQueue);
  }

  // Move to previous track
  QueueState withPreviousTrack() {
    if (!canGoPrevious || currentQueue == null) return this;

    final updatedQueue = currentQueue!.copyWith(
      currentIndex: currentQueue!.currentIndex - 1,
    );

    return copyWith(currentQueue: updatedQueue);
  }

  // Set loading state for next page
  QueueState withLoadingNextPage() {
    return copyWith(isLoadingNextPage: true);
  }

  // Set error state
  QueueState withError(String error) {
    return copyWith(
      status: QueueLoadStatus.failure,
      error: error,
      isLoadingNextPage: false,
    );
  }

  // Clear queue
  QueueState withClearedQueue() {
    return const QueueState();
  }

  QueueType _determineQueueType(String context) {
    switch (context) {
      case 'favorites':
      case 'allTracks':
        return QueueType.paginated;
      case 'vibe':
        return QueueType.infiniteVibe;
      default:
        return QueueType.finite;
    }
  }

  @override
  List<Object?> get props => [currentQueue, status, error, isLoadingNextPage];

  @override
  String toString() {
    return 'QueueState('
        'hasQueue: $hasQueue, '
        'tracks: $totalTracks, '
        'currentIndex: $currentIndex, '
        'status: $status, '
        'isLoadingNextPage: $isLoadingNextPage)';
  }
}
