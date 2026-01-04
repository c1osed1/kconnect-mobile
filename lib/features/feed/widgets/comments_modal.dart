/// Модальное окно комментариев к посту
///
/// Предоставляет интерфейс для просмотра, добавления и управления комментариями.
/// Включает поддержку вложенных комментариев, лайков и Markdown форматирования.
/// Управляет состоянием комментариев через FeedBloc.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/authorized_cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../../features/auth/presentation/blocs/auth_state.dart';
import '../../../features/feed/presentation/blocs/feed_bloc.dart';
import '../../../features/feed/presentation/blocs/feed_state.dart';
import '../../../features/feed/presentation/blocs/feed_event.dart';
import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../../../features/profile/utils/profile_navigation_utils.dart';

/// Кастомная физика прокрутки для комментариев
///
/// Отключает отскок при прокрутке вверх за пределы списка,
/// сохраняя стандартное поведение для нижней границы.
class CustomScrollPhysics extends BouncingScrollPhysics {
  const CustomScrollPhysics({super.parent});

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Если отскок вверх (попытка прокрутки вверх за пределы минимума), не отскакивать
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      return 0.0;
    }
    // В противном случае использовать стандартное отскакивание для нижней границы
    return super.applyBoundaryConditions(position, value);
  }
}

/// Основной контейнер для комментариев поста
///
/// Содержит список комментариев и поле ввода нового комментария.
/// Высота увеличена до 65% экрана для лучшего использования пространства.
class CommentsBody extends StatelessWidget {
  /// ID поста, комментарии которого отображаются
  final int postId;

  /// Объект поста (может использоваться для дополнительной информации)
  final Post post;

  const CommentsBody({super.key, required this.postId, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        final comments = state.comments;

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Expanded(
                child: CommentsList(
                  postId: postId,
                  comments: comments,
                  commentsStatus: state.commentsStatus,
                ),
              ),
              CommentsInput(postId: postId),
            ],
          ),
        );
      },
    );
  }
}

/// Виджет списка комментариев
///
/// Отображает прокручиваемый список комментариев с поддержкой
/// вложенных ответов, лайков и обработки ошибок загрузки.
class CommentsList extends StatefulWidget {
  /// ID поста, комментарии которого отображаются
  final int postId;

  /// Список комментариев для отображения
  final List<Comment> comments;

  /// Статус загрузки комментариев
  final CommentsStatus commentsStatus;

  const CommentsList({
    super.key,
    required this.postId,
    required this.comments,
    required this.commentsStatus,
  });

  @override
  State<CommentsList> createState() => _CommentsListState();
}

class _CommentsListState extends State<CommentsList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _preprocessedCache = {};

  String _preprocessText(String text) {
    if (_preprocessedCache.containsKey(text)) {
      return _preprocessedCache[text]!;
    }
    final result = text.replaceAllMapped(RegExp(r'#([\wа-яё]+)', caseSensitive: false), (match) {
      return '[#${match[1]}](hashtag)';
    });
    _preprocessedCache[text] = result;
    return result;
  }

  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(LoadCommentsEvent(widget.postId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Comment> _getCommentTree(List<Comment> comments) {
    return comments;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? int.tryParse(authState.user.id) : null;

    if (widget.commentsStatus == CommentsStatus.loading && widget.comments.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (widget.commentsStatus == CommentsStatus.failure) {
      return _buildCommentsErrorWidget();
    }

    if (widget.comments.isEmpty) {
      return Center(
        child: Text('Нет комментариев', style: AppTextStyles.postStats),
      );
    }

    final commentTree = _getCommentTree(widget.comments);

    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, feedState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView.separated(
            controller: _scrollController,
            physics: const CustomScrollPhysics(),
            itemCount: commentTree.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final comment = commentTree[index];
              final isProcessing = feedState.processingCommentLikes.contains(comment.id);
              return CommentThread(
                comment: comment,
                currentUserId: currentUserId,
                preprocessText: _preprocessText,
                isProcessing: isProcessing,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommentsErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'Не удалось загрузить комментарии',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (context.read<FeedBloc>().state.commentsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.read<FeedBloc>().state.commentsError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CupertinoColors.systemGrey2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () {
              context.read<FeedBloc>().add(LoadCommentsEvent(widget.postId));
            },
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
}

class CommentThread extends StatelessWidget {
  final Comment comment;
  final int? currentUserId;
  final String Function(String) preprocessText;
  final bool isProcessing;

  const CommentThread({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.preprocessText,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final replies = comment.replies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentItem(
          comment: comment,
          currentUserId: currentUserId,
          preprocessText: preprocessText,
          isProcessing: isProcessing,
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CommentThread(
                    comment: reply,
                    currentUserId: currentUserId,
                    preprocessText: preprocessText,
                    isProcessing: false,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class CommentItem extends StatelessWidget {
  final Comment comment;
  final int? currentUserId;
  final String Function(String) preprocessText;
  final bool isProcessing;

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.preprocessText,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = comment.userAvatar;
    final name = comment.userName;
    final text = comment.content;
    final createdAt = comment.createdAt;
    final likesCount = comment.likesCount;
    final isLiked = comment.userLiked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.overlayDark.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  ProfileNavigationUtils.navigateToProfile(context, comment.username);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgCard,
                  ),
                  child: ClipOval(
                    child: AuthorizedCachedNetworkImage(
                      imageUrl: avatar.isNotEmpty ? avatar : AppConstants.userAvatarPlaceholder,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      memCacheWidth: 64,
                      memCacheHeight: 64,
                      placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
                      errorWidget: (context, url, error) => Image.network(
                        AppConstants.userAvatarPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ProfileNavigationUtils.navigateToProfile(context, comment.username);
                          },
                          child: Text(
                            name,
                            style: AppTextStyles.postAuthor.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date_utils.formatRelativeTimeFromMillis(createdAt),
                          style: AppTextStyles.postTime.copyWith(fontSize: 11), // Уменьшен размер
                        ),
                        const Spacer(),
                        if (comment.userId == currentUserId)
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.read<FeedBloc>().add(DeleteCommentEvent(comment.id)),
                            child: Icon(
                              CupertinoIcons.trash,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: preprocessText(text),
            styleSheet: MarkdownStyleSheet(
              p: AppTextStyles.postContent.copyWith(
                height: 1.3,
                fontSize: 14,
              ),
            ),
          ),
          if (comment.image != null && comment.image!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: AuthorizedCachedNetworkImage(
                    imageUrl: comment.image!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      color: AppColors.bgCard,
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Реализовать функцию ответа на комментарий - добавить диалог ввода ответа,
                    // обновить UI для отображения вложенных ответов, отправить ответ на сервер
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrowshape_turn_up_left,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ответить',
                        style: AppTextStyles.postStats.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: isProcessing ? null : () => context.read<FeedBloc>().add(LikeCommentEvent(comment.id)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isProcessing
                          ? const CupertinoActivityIndicator(radius: 6)
                          : Icon(
                              CupertinoIcons.heart,
                              size: 16,
                              color: isLiked ? context.dynamicPrimaryColor : AppColors.textSecondary,
                            ),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: AppTextStyles.postStats.copyWith(
                          fontSize: 11,
                          color: isLiked ? context.dynamicPrimaryColor : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsInput extends StatefulWidget {
  final int postId;

  const CommentsInput({super.key, required this.postId});

  @override
  State<CommentsInput> createState() => _CommentsInputState();
}

class _CommentsInputState extends State<CommentsInput> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      context.read<FeedBloc>().add(AddCommentEvent(widget.postId, text));
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.overlayDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.bgWhite.withValues(alpha: 0.1),
                ),
              ),
              child: CupertinoTextField(
                controller: _commentController,
                placeholder: 'Написать комментарий...',
                placeholderStyle: TextStyle(
                  color: AppColors.bgWhite.withValues(alpha: 0.5),
                ),
                style: AppTextStyles.postContent.copyWith(
                  color: AppColors.bgWhite,
                ),
                maxLines: 3,
                minLines: 1,
                decoration: const BoxDecoration(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: context.dynamicPrimaryColor,
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addComment,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  CupertinoIcons.paperplane,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
