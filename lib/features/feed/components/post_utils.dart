/// Утилиты для обработки и работы с данными постов
///
/// Содержит функции для предварительной обработки текста постов,
/// извлечения заголовков, работы с медиа-контентом и пользовательскими данными.
/// Используется компонентами постов для унификации логики обработки данных.
library;

import '../../../core/constants.dart';
import '../../../features/feed/domain/models/comment.dart';
import '../../../features/music/domain/models/track.dart';

/// Статический класс с утилитами для работы с постами
class PostUtils {
  /// Предварительная обработка текста для правильного отображения переносов строк
  static String preprocessText(String text) {

    text = text.replaceAll('\n', '  \n');
    return text.replaceAllMapped(RegExp(r'#([\wа-яё]+)', caseSensitive: false), (match) {
      return '[#${match[1]}](hashtag)';
    });
  }

  /// Обрезка контента до указанной максимальной длины
  static String truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Проверка, начинается ли контент с заголовка и его извлечение
  static Map<String, dynamic> extractHeaderIfPresent(String content) {
    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.startsWith('#') && firstLine.length > 1) {
        final headerMatch = RegExp(r'^(#+)\s+(.+)$').firstMatch(firstLine);
        if (headerMatch != null) {
          final headerLevel = headerMatch.group(1)!.length;
          final headerText = headerMatch.group(2)!.trim();
          final remainingContent = content.substring(firstLine.length).trim();
          final hasMoreContent = remainingContent.isNotEmpty;
          return {
            'hasHeader': true,
            'headerText': headerText,
            'headerLevel': headerLevel,
            'hasMoreContent': hasMoreContent,
          };
        }
      }
    }
    return {'hasHeader': false};
  }

  /// Преобразование временной метки в целое число
  static int parseTimestamp(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      try {
        final dateTime = DateTime.parse(value);
        return dateTime.millisecondsSinceEpoch;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Проверка наличия медиа-контента в посте
  static bool hasMedia(List<String>? images, String? image, String? video) {
    return (images != null && images.isNotEmpty) ||
           (image != null && image.isNotEmpty) ||
           (video != null && video.isNotEmpty);
  }

  /// Проверка наличия музыкального контента в посте
  static bool hasMusic(List<Track>? music) {
    return music != null && music.isNotEmpty;
  }

  /// Получение URL аватара пользователя с запасными вариантами
  static String getUserAvatar(Map<String, dynamic>? user) {
    if (user == null) return AppConstants.userAvatarPlaceholder;
    final avatarUrl = user['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) return avatarUrl;
    final photo = user['photo'] as String?;
    if (photo != null && photo.isNotEmpty) return photo;
    return AppConstants.userAvatarPlaceholder;
  }

  /// Получение имени пользователя с запасным вариантом
  static String getUserName(Map<String, dynamic>? user, String fallback) {
    if (user == null) return fallback;
    return user['name'] as String? ?? fallback;
  }

  /// Получение username пользователя с запасным вариантом
  static String getUserUsername(Map<String, dynamic>? user, String fallback) {
    if (user == null) return fallback;
    return user['username'] as String? ?? fallback;
  }

  /// Преобразование Comment из JSON в объект Comment
  static Comment? parseLastComment(Map<String, dynamic>? lastCommentJson) {
    if (lastCommentJson == null) return null;
    try {
      return Comment.fromJson(lastCommentJson);
    } catch (e) {
      return null;
    }
  }
}
