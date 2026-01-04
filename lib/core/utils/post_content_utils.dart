// Утилиты для обработки контента постов и стилизации Markdown
//
// Предоставляет функции для предварительной обработки текста постов,
// стилизации markdown и определения необходимости кнопки "развернуть".
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../utils/theme_extensions.dart';

/// Абстрактный класс утилит для обработки контента постов и стилизации Markdown
abstract class PostContentUtils {
  /// Предварительно обрабатывает текстовый контент, заменяя переносы строк и хэштеги
  ///
  /// [text] - исходный текст для обработки
  /// Returns: обработанный текст с правильными переносами и стилизованными хэштегами
  static String preprocessText(String text) {
    // Replace line breaks with hard breaks for proper line wrapping
    text = text.replaceAll('\n', '  \n');
    // Replace hashtags with links for accent color styling
    return text.replaceAllMapped(
      RegExp(r'#([\wа-яё]+)', caseSensitive: false),
      (match) => '[#${match[1]}](hashtag)'
    );
  }

  /// Возвращает таблицу стилей Markdown в зависимости от состояния сворачивания контента
  ///
  /// [isCollapsed] - свернут ли контент
  /// [context] - контекст сборки для получения динамических цветов
  /// Returns: настроенная таблица стилей Markdown
  static MarkdownStyleSheet getMarkdownStyleSheet(
    bool isCollapsed,
    BuildContext context,
  ) {
    final headerFontSize = isCollapsed ? 20.0 : 24.0;
    return MarkdownStyleSheet(
      p: AppTextStyles.postContent.copyWith(height: 1.2),
      h1: AppTextStyles.postAuthor.copyWith(
        fontSize: headerFontSize,
        fontWeight: FontWeight.w600
      ),
      h2: AppTextStyles.postAuthor.copyWith(
        fontSize: headerFontSize - 2,
        fontWeight: FontWeight.w600
      ),
      h3: AppTextStyles.postAuthor.copyWith(
        fontSize: headerFontSize - 4,
        fontWeight: FontWeight.w600
      ),
      h4: AppTextStyles.postAuthor.copyWith(
        fontSize: headerFontSize - 6,
        fontWeight: FontWeight.w600
      ),
      h5: AppTextStyles.postAuthor.copyWith(
        fontSize: headerFontSize - 8,
        fontWeight: FontWeight.w600
      ),
      h6: AppTextStyles.postAuthor.copyWith(
        fontSize: headerFontSize - 10,
        fontWeight: FontWeight.w600
      ),
      a: AppTextStyles.postContent.copyWith(
        color: context.dynamicPrimaryColor,
        decoration: TextDecoration.none
      ),
      code: AppTextStyles.postContent.copyWith(
        backgroundColor: AppColors.overlayDark,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      strong: AppTextStyles.postContent.copyWith(fontWeight: FontWeight.bold),
      em: AppTextStyles.postContent.copyWith(fontStyle: FontStyle.italic),
      blockquote: AppTextStyles.postContent.copyWith(
        fontStyle: FontStyle.italic
      ),
      listBullet: AppTextStyles.postContent,
      listIndent: 16,
    );
  }

  /// Проверяет, начинается ли контент с заголовка и извлекает его
  ///
  /// [content] - текст контента для анализа
  /// Returns: Map с информацией о заголовке ('hasHeader', 'headerText', 'headerLevel', 'hasMoreContent')
  static Map<String, dynamic> extractHeaderIfPresent(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return {'hasHeader': false};

    final firstLine = lines[0].trim();
    // Check if first line starts with # and has content
    if (firstLine.startsWith('#') && firstLine.length > 1) {
      final headerMatch = RegExp(r'^(#+)\s+(.+)$').firstMatch(firstLine);
      if (headerMatch != null) {
        final headerLevel = headerMatch.group(1)!.length;
        final headerText = headerMatch.group(2)!.trim();
        // Check if there's non-empty content after the header (beyond empty lines)
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
    return {'hasHeader': false};
  }

  /// Обрезает контент до указанной максимальной длины с многоточием
  ///
  /// [content] - текст для обрезки
  /// [maxLength] - максимальная длина текста
  /// Returns: обрезанный текст с многоточием если превышает лимит
  static String truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Определяет, нужно ли показывать кнопку "развернуть" для контента
  ///
  /// [content] - текст контента для проверки
  /// [hasHeader] - есть ли заголовок в контенте
  /// [hasMoreContent] - есть ли дополнительный контент после заголовка
  /// [customLengthThreshold] - пользовательский порог длины
  /// Returns: true если нужно показать кнопку развернуть
  static bool shouldShowExpandButton(
    String content, {
    required bool hasHeader,
    required bool hasMoreContent,
    int? customLengthThreshold,
  }) {
    const int lengthThreshold = 100;

    if (hasHeader) {
      return hasMoreContent;
    } else {
      return content.length > (customLengthThreshold ?? lengthThreshold);
    }
  }
}
