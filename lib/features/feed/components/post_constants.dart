/// Константы и размеры для компонентов постов в ленте
///
/// Определяет все размеры, отступы, радиусы скругления и пороговые значения
/// для отображения постов в ленте. Используется для поддержания一致ного
/// внешнего вида и поведения компонентов постов.
class PostConstants {
  /// Максимальная длина контента для preview
  static const int maxContentLength = 100;

  /// Максимальная длина заголовка для preview
  static const int maxHeaderLength = 80;

  /// Горизонтальные отступы карточки
  static const double cardHorizontalPadding = 24.0;

  /// Вертикальные отступы карточки
  static const double cardVerticalPadding = 6.0;

  /// Отступы для прозрачного фона
  static const double transparentPadding = 16.0;

  /// Размер аватара пользователя
  static const double avatarSize = 40.0;

  /// Размер аватара в репосте
  static const double repostAvatarSize = 25.0;

  /// Ширина контейнера комментариев
  static const double commentPreviewWidth = 200.0;

  /// Высота превью изображений
  static const double imagePreviewHeight = 200.0;

  /// Максимальная высота превью контента
  static const double maxContentPreviewHeight = 140.0;

  /// Максимальная высота превью с заголовком
  static const double maxHeaderPreviewHeight = 120.0;

  /// Высота градиентной маски
  static const double gradientMaskHeight = 40.0;

  /// Радиус скругления изображений и карточек
  static const double borderRadius = 8.0;

  /// Радиус скругления карточки
  static const double cardBorderRadius = 12.0;

  /// Размер иконок действий
  static const double actionIconSize = 24.0;

  /// Размер иконок репоста
  static const double repostActionIconSize = 20.0;

  /// Размер иконок статистики
  static const double statsIconSize = 20.0;

  /// Размер маленьких иконок (время, просмотры)
  static const double smallIconSize = 12.0;

  /// Отступы между элементами
  static const double elementSpacing = 8.0;

  /// Горизонтальный отступ от аватара к контенту
  static const double avatarMargin = 10.0;

  /// Отступ от левого края для оригинального поста в репосте
  static const double repostContentIndent = 45.0;

  /// Порог прокрутки для показа кнопки "наверх"
  static const double scrollToTopThreshold = 200.0;

  /// Порог возле нижнего края для подгрузки
  static const double loadMoreThreshold = 50.0;

  /// Коэффициент максимальной высоты изображения от высоты экрана (0.0-1.0)
  static const double maxImageHeightFactor = 0.5;
}
