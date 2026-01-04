/// Типы постов в системе
///
/// Определяет различные виды постов: обычные посты и репосты.
/// Используется для различения логики отображения и обработки.
enum PostType {
  /// Обычный пост
  post,
  /// Репост другого поста
  repost,
}

/// Расширение для работы с enum PostType
///
/// Предоставляет удобные методы для конвертации между значениями enum
/// и строковыми представлениями, а также фабричные конструкторы.
extension PostTypeExtension on PostType {
  String get value {
    switch (this) {
      case PostType.post:
        return 'post';
      case PostType.repost:
        return 'repost';
    }
  }

  static PostType fromString(String? value) {
    switch (value) {
      case 'repost':
        return PostType.repost;
      case 'post':
      default:
        return PostType.post;
    }
  }
}
