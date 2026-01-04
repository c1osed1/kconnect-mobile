/// Типы медиа-контента в приложении
enum MediaType {
  /// Изображение
  image,
  /// Видео
  video,
}

/// Модель медиа-контента (изображения и видео)
///
/// Представляет медиа-объект с типом, URL и опциональным постером для видео.
/// Поддерживает фабричные конструкторы для удобного создания изображений и видео.
class MediaItem {
  /// Тип медиа-контента
  final MediaType type;

  /// URL медиа-файла
  final String url;

  /// URL постера/миниатюры для видео (опционально)
  final String? posterUrl;

  const MediaItem({
    required this.type,
    required this.url,
    this.posterUrl,
  });

  factory MediaItem.image(String url) {
    return MediaItem(
      type: MediaType.image,
      url: url,
    );
  }

  factory MediaItem.video(String url, {String? posterUrl}) {
    return MediaItem(
      type: MediaType.video,
      url: url,
      posterUrl: posterUrl,
    );
  }

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          url == other.url &&
          posterUrl == other.posterUrl;

  @override
  int get hashCode => Object.hash(type, url, posterUrl);
}
