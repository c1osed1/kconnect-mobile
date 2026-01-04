/// Компонент для отображения текстового контента поста
///
/// Поддерживает markdown разметку, автоматическое сворачивание длинного контента,
/// выделение заголовков и hashtag'ов. Обеспечивает expand/collapse функциональность.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/widgets/profile_accent_color_provider.dart';
import 'post_constants.dart';
import 'post_utils.dart';


/// Компонент контента поста с поддержкой markdown и expand/truncate
class PostContent extends StatefulWidget {
  final String content;
  final bool isRepostContent;
  final bool? isExpandedOverride;

  const PostContent({
    super.key,
    required this.content,
    this.isRepostContent = false,
    this.isExpandedOverride,
  });

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  bool _isExpanded = false;

  String get _preprocessedContent => PostUtils.preprocessText(widget.content);

  /// Получение Markdown стиля
  MarkdownStyleSheet _getMarkdownStyleSheet(bool isCollapsed, BuildContext context) {
    final headerFontSize = isCollapsed ? 20.0 : 24.0;
    return MarkdownStyleSheet(
      p: AppTextStyles.postContent.copyWith(height: 1.2),
      h1: AppTextStyles.postAuthor.copyWith(fontSize: headerFontSize, fontWeight: FontWeight.w600),
      h2: AppTextStyles.postAuthor.copyWith(fontSize: headerFontSize - 2, fontWeight: FontWeight.w600),
      h3: AppTextStyles.postAuthor.copyWith(fontSize: headerFontSize - 4, fontWeight: FontWeight.w600),
      h4: AppTextStyles.postAuthor.copyWith(fontSize: headerFontSize - 6, fontWeight: FontWeight.w600),
      h5: AppTextStyles.postAuthor.copyWith(fontSize: headerFontSize - 8, fontWeight: FontWeight.w600),
      h6: AppTextStyles.postAuthor.copyWith(fontSize: headerFontSize - 10, fontWeight: FontWeight.w600),
      a: AppTextStyles.postContent.copyWith(color: context.profileAccentColor, decoration: TextDecoration.none),
      code: AppTextStyles.postContent.copyWith(
        backgroundColor: AppColors.overlayDark,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      strong: AppTextStyles.postContent.copyWith(fontWeight: FontWeight.bold),
      em: AppTextStyles.postContent.copyWith(fontStyle: FontStyle.italic),
      blockquote: AppTextStyles.postContent.copyWith(fontStyle: FontStyle.italic),
      listBullet: AppTextStyles.postContent,
      listIndent: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerInfo = PostUtils.extractHeaderIfPresent(widget.content);
    final hasHeader = headerInfo['hasHeader'] as bool;
    final isExpanded = widget.isExpandedOverride ?? _isExpanded;

    if (widget.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Контент поста
        isExpanded
            ? RepaintBoundary(
                child: MarkdownBody(
                  data: _preprocessedContent,
                  styleSheet: _getMarkdownStyleSheet(false, context),
                ),
              )
            : Builder(
                builder: (context) {
                  if (hasHeader) {
                    // Отображаем только заголовок с truncate
                    final headerLevel = headerInfo['headerLevel'] as int;
                    final headerText = headerInfo['headerText'] as String;
                    final truncatedHeader = headerText.length > PostConstants.maxHeaderLength
                        ? '${headerText.substring(0, PostConstants.maxHeaderLength)}...'
                        : headerText;

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: RepaintBoundary(
                        child: MarkdownBody(
                          data: '${'#' * headerLevel} $truncatedHeader',
                          styleSheet: _getMarkdownStyleSheet(true, context),
                        ),
                      ),
                    );
                  } else {
                    // Обычный контент с truncate
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: widget.isRepostContent ? 100 : PostConstants.maxContentPreviewHeight),
                      child: Stack(
                        children: [
                          ClipRect(
                            child: RepaintBoundary(
                              child: MarkdownBody(
                                data: PostUtils.preprocessText(
                                  PostUtils.truncateContent(widget.content, PostConstants.maxContentLength)
                                ),
                                styleSheet: _getMarkdownStyleSheet(true, context),
                              ),
                            ),
                          ),
                          // Градиентная маска для длинного контента
                          if (widget.content.length > PostConstants.maxContentLength)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: PostConstants.gradientMaskHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.bgCard.withValues(alpha:0.0),
                                      AppColors.bgCard,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                },
              ),

        // Кнопка "Развернуть" если есть что развернуть и не используется внешний контроль
        if (!isExpanded && widget.isExpandedOverride == null)
          Builder(
            builder: (context) {
              bool shouldShowExpand = false;

              if (hasHeader) {
                shouldShowExpand = headerInfo['hasMoreContent'] as bool;
              } else {
                shouldShowExpand = widget.content.length > PostConstants.maxContentLength;
              }

              if (!shouldShowExpand) return const SizedBox.shrink();

              return Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isExpanded = true),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Развернуть',
                      style: AppTextStyles.postStats.copyWith(
                        color: context.profileAccentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
