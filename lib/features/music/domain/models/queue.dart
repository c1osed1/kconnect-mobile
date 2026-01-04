import 'package:equatable/equatable.dart';
import 'package:kconnect_mobile/features/music/domain/models/track.dart';

/// Типы музыкальных очередей
enum QueueType {
  /// Конечная очередь с фиксированным набором треков
  finite,

  /// Пагинированная очередь с динамической загрузкой страниц
  paginated,

  /// Бесконечная очередь с генерацией музыки по вкусу
  infiniteVibe,
}

/// Элемент музыкальной очереди
///
/// Представляет трек в очереди с контекстом его происхождения
/// и позицией в пагинированной загрузке.
class QueueItem extends Equatable {
  final Track track;
  final String context; // 'popular', 'favorites', 'allTracks', 'vibe', etc.
  final int pageIndex; // For paginated queues, -1 for non-paginated
  final int itemIndex; // Original index within the page/context

  const QueueItem({
    required this.track,
    required this.context,
    this.pageIndex = -1,
    required this.itemIndex,
  });

  @override
  List<Object?> get props => [track.id, context, pageIndex, itemIndex];
}

class Queue extends Equatable {
  final List<QueueItem> items;
  final int currentIndex;
  final QueueType type;
  final String context;
  final Map<int, bool> loadedPages; // For paginated queues: page -> isLoaded

  const Queue({
    required this.items,
    this.currentIndex = 0,
    required this.type,
    required this.context,
    this.loadedPages = const {},
  });

  bool get hasNext => currentIndex < items.length - 1;
  bool get hasPrevious => currentIndex > 0;
  QueueItem? get currentItem => items.isNotEmpty && currentIndex >= 0 && currentIndex < items.length
      ? items[currentIndex]
      : null;

  Track? get currentTrack => currentItem?.track;

  // For paginated queues: check if next page needs to be loaded
  bool get shouldLoadNextPage {
    if (type != QueueType.paginated) return false;
    final nextItemIndex = currentIndex + 1;
    if (nextItemIndex >= items.length) return true; // Reached end, need next page

    // Check if we're close to the end of current page (within 3 tracks)
    final currentPage = items[currentIndex].pageIndex;
    final nextPage = items[nextItemIndex].pageIndex;
    return currentPage == nextPage && nextItemIndex >= items.length - 3;
  }

  Queue copyWith({
    List<QueueItem>? items,
    int? currentIndex,
    QueueType? type,
    String? context,
    Map<int, bool>? loadedPages,
  }) {
    return Queue(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      type: type ?? this.type,
      context: context ?? this.context,
      loadedPages: loadedPages ?? this.loadedPages,
    );
  }

  // Add new page to paginated queue
  Queue addPage(List<Track> newTracks, int pageNumber) {
    final newItems = newTracks.map((track) => QueueItem(
      track: track,
      context: context,
      pageIndex: pageNumber,
      itemIndex: newTracks.indexOf(track),
    )).toList();

    return copyWith(
      items: [...items, ...newItems],
      loadedPages: {...loadedPages, pageNumber: true},
    );
  }

  // Add new batch to infinite vibe queue
  Queue addVibeBatch(List<Track> newTracks) {
    final newItems = newTracks.map((track) => QueueItem(
      track: track,
      context: context,
      pageIndex: -1, // Vibe doesn't use pages
      itemIndex: items.length + newTracks.indexOf(track),
    )).toList();

    return copyWith(items: [...items, ...newItems]);
  }

  @override
  List<Object?> get props => [items, currentIndex, type, context, loadedPages];
}
