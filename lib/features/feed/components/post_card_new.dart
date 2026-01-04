import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants.dart';
import '../presentation/blocs/feed_bloc.dart';
import '../presentation/blocs/feed_event.dart';
import '../presentation/blocs/feed_state.dart';
import '../../../features/feed/domain/models/post.dart';
import '../widgets/comments_modal.dart';
import 'post_utils.dart';
import 'post_content.dart';
import 'post_header.dart';
import 'post_media.dart';
import 'post_music.dart';
import 'post_actions.dart';
import 'post_constants.dart';
import 'post_context_menu.dart';
import '../../profile/utils/profile_navigation_utils.dart';
import '../../../routes/route_names.dart';
import '../../../core/media_item.dart';
import '../../../core/widgets/profile_accent_color_provider.dart';

/// Карточка поста
class PostCardNew extends StatelessWidget {
  final int? postId;
  final Post? post;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final Color? backgroundColor;
  final bool isFullWidth;
  final bool transparentBackground;
  final bool semiTransparent;
  final Function()? onLike;
  final bool? isLikeProcessing;

  const PostCardNew({
    super.key,
    this.postId,
    this.post,
    this.margin,
    this.opacity,
    this.backgroundColor,
    this.isFullWidth = true,
    this.transparentBackground = false,
    this.semiTransparent = false,
    this.onLike,
    this.isLikeProcessing,
  }) : assert(post != null || postId != null, 'Either post or postId must be provided');

  @override
  Widget build(BuildContext context) {
    if (post != null) {
      return _PostCardContent(
        post: post!,
        margin: margin,
        opacity: opacity,
        backgroundColor: backgroundColor,
        isFullWidth: isFullWidth,
        transparentBackground: transparentBackground,
        semiTransparent: semiTransparent,
        onLike: onLike,
        isLikeProcessing: isLikeProcessing ?? false,
      );
    }

    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        final foundPost = state.posts.firstWhere(
          (p) => p.id == postId,
          orElse: () => Post(
            id: postId!,
            content: 'Post not found',
            userId: 0,
            userName: 'Unknown',
            userAvatar: '',
            createdAt: 0,
            likesCount: 0,
            dislikesCount: 0,
            commentsCount: 0,
            isLiked: false,
            isDisliked: false,
            isBookmarked: false,
            attachments: [],
            comments: [],
          ),
        );

        return _PostCardContent(
          post: foundPost,
          margin: margin,
          opacity: opacity,
          backgroundColor: backgroundColor,
          isFullWidth: isFullWidth,
          transparentBackground: transparentBackground,
          semiTransparent: semiTransparent,
          onLike: onLike,
          isLikeProcessing: isLikeProcessing ?? state.processingPostLikes.contains(foundPost.id),
        );
      },
    );
  }
}

/// Рендер контента поста
class _PostCardContent extends StatefulWidget {
  final Post post;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final Color? backgroundColor;
  final bool isFullWidth;
  final bool transparentBackground;
  final bool semiTransparent;
  final Function()? onLike;
  final bool isLikeProcessing;

  const _PostCardContent({
    required this.post,
    this.margin,
    this.opacity,
    this.backgroundColor,
    this.isFullWidth = true,
    this.transparentBackground = false,
    this.semiTransparent = false,
    this.onLike,
    this.isLikeProcessing = false,
  });

  @override
  State<_PostCardContent> createState() => _PostCardContentState();
}

class _PostCardContentState extends State<_PostCardContent> {
  void _openMediaViewer(Post post, int initialIndex) {

    final List<MediaItem> items = [];

    if (post.images != null) {
      for (final img in post.images!) {
        if (img.isNotEmpty && _isValidUrl(img)) {
          items.add(MediaItem.image(img));
        } else {
        }
      }
    } else if (post.image != null && post.image!.isNotEmpty && _isValidUrl(post.image!)) {
      items.add(MediaItem.image(post.image!));
    }

    if (post.video != null && post.video!.isNotEmpty && _isValidUrl(post.video!)) {
      String? posterUrl = (post.videoPoster != null && post.videoPoster!.isNotEmpty && _isValidUrl(post.videoPoster!)) ? post.videoPoster : null;
      items.add(MediaItem.video(post.video!, posterUrl: posterUrl));
    } else {

    }

    final validItems = items.where((item) => item.url.isNotEmpty).toList();

    if (validItems.isNotEmpty) {
      try {
        Navigator.of(context).pushNamed(
          RouteNames.mediaViewer,
          arguments: {
            'items': validItems,
            'initialIndex': initialIndex,
          },
        );
      } catch (e) {
        // Игнорирование ошибок навигации
      }
    } else {
      
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _openComments() {
    final postId = widget.post.id;

    WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (modalSheetContext) {
        return [
          WoltModalSheetPage(
            hasSabGradient: false,
            navBarHeight: 50,
            backgroundColor: const Color.fromARGB(255, 12, 12, 12),
            topBarTitle: Text(
              'Комментарии',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            trailingNavBarWidget: IconButton(
              padding: EdgeInsets.zero,
              onPressed: Navigator.of(modalSheetContext).pop,
              icon: Icon(
                CupertinoIcons.xmark,
                color: AppColors.textPrimary,
              ),
            ),
            child: CommentsBody(postId: postId, post: widget.post),
          ),
        ];
      },
    );
  }

  void _handleLike() {
    if (widget.onLike != null) {
      widget.onLike!();
    } else {
      context.read<FeedBloc>().add(LikePostEvent(widget.post.id));
    }
  }

  void _handleRepost() {
    // TODO: Реализовать функцию поделиться - добавить диалог с опциями шаринга:
    // копирование ссылки, поделиться в другие соцсети, отправить в чат
  }

  @override
  Widget build(BuildContext context) {
    // Обработка репостов
    if (widget.post.type == 'repost' && widget.post.originalPost != null) {
      return _RepostCardContent(
        post: widget.post,
        margin: widget.margin,
        opacity: widget.opacity,
        backgroundColor: widget.backgroundColor,
        isFullWidth: widget.isFullWidth,
        transparentBackground: widget.transparentBackground,
        semiTransparent: widget.semiTransparent,
        onCommentsPressed: _openComments,
        onLikePressed: _handleLike,
        onRepostPressed: _handleRepost,
      );
    }

    // Обычный пост
    return RepaintBoundary(
      child: Container(
        padding: widget.transparentBackground
            ? const EdgeInsets.symmetric(horizontal: PostConstants.transparentPadding)
            : const EdgeInsets.all(PostConstants.cardHorizontalPadding),
        margin: widget.transparentBackground
            ? (widget.margin ?? EdgeInsets.zero)
            : (widget.isFullWidth
                ? EdgeInsets.zero
                : (widget.margin ?? const EdgeInsets.symmetric(vertical: PostConstants.cardVerticalPadding, horizontal: 12))),
        decoration: widget.transparentBackground
            ? null
            : BoxDecoration(
                color: widget.semiTransparent
                    ? (AppColors.bgDark.withValues(alpha: 0.5))
                    : (widget.backgroundColor?.withValues(alpha: widget.opacity ?? 1.0) ?? AppColors.bgCard.withValues(alpha: widget.opacity ?? 1.0)),
                borderRadius: widget.isFullWidth ? BorderRadius.zero : BorderRadius.circular(PostConstants.cardBorderRadius),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок поста
            PostHeader(
              user: widget.post.user,
              timestamp: widget.post.createdAt,
              viewsCount: widget.post.viewsCount,
              isPinned: widget.post.isPinned,
              onMenuPressed: () => PostContextMenu.show(context, widget.post),
            ),

            const SizedBox(height: PostConstants.elementSpacing),

            // Контент поста
            if (widget.post.content.isNotEmpty) ...[
              PostContent(content: widget.post.content),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Медиа контент
            if (PostUtils.hasMedia(widget.post.images, widget.post.image, widget.post.video)) ...[
              PostMedia(
                images: widget.post.images,
                singleImage: widget.post.image,
                videoUrl: widget.post.video,
                videoPoster: widget.post.videoPoster,
                isFullWidth: widget.isFullWidth,
                onMediaTap: (index) => _openMediaViewer(widget.post, index),
              ),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Музыка
            if (PostUtils.hasMusic(widget.post.music)) ...[
              PostMusic(tracks: widget.post.music!),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Действия поста
            PostActions(
              isLiked: widget.post.isLiked,
              likesCount: widget.post.likesCount,
              originalLikesCount: widget.post.likesCount, // Для обычного поста совпадают
              lastComment: widget.post.lastComment,
              commentsCount: widget.post.commentsCount,
              onLikePressed: _handleLike,
              onRepostPressed: _handleRepost,
              onCommentsPressed: _openComments,
              isLikeProcessing: widget.isLikeProcessing,
            ),
          ],
        ),
      ),
    );
  }
}

/// Репост компонент
class _RepostCardContent extends StatefulWidget {
  final Post post;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final Color? backgroundColor;
  final bool isFullWidth;
  final bool transparentBackground;
  final bool semiTransparent;
  final Function()? onCommentsPressed;
  final Function()? onLikePressed;
  final Function()? onRepostPressed;

  const _RepostCardContent({
    required this.post,
    this.margin,
    this.opacity,
    this.backgroundColor,
    this.isFullWidth = true,
    this.transparentBackground = false,
    this.semiTransparent = false,
    this.onCommentsPressed,
    this.onLikePressed,
    this.onRepostPressed,
  });

  @override
  _RepostCardContentState createState() => _RepostCardContentState();
}

class _RepostCardContentState extends State<_RepostCardContent> {
  bool _isExpanded = false;

  void _openMediaViewer(Post post, int initialIndex) {
    final List<String> urls = [];
    if (post.images != null && post.images!.isNotEmpty) {
      urls.addAll(post.images!);
    } else if (post.image != null && post.image!.isNotEmpty && _isValidUrl(post.image!)) {
      urls.add(post.image!);
    }
    if (post.video != null && post.videoPoster != null && post.videoPoster!.isNotEmpty && _isValidUrl(post.videoPoster!)) {
      urls.add(post.videoPoster!);
    }

    final List<MediaItem> items = [];
    int imageIndex = 0;
    int videoIndex = 0;

    for (final url in urls) {
      if (post.images != null && imageIndex < post.images!.length && post.images![imageIndex] == url && _isValidUrl(post.images![imageIndex])) {
        items.add(MediaItem.image(url));
        imageIndex++;
      } else if (post.video != null && videoIndex == 0 && url == post.videoPoster && _isValidUrl(post.video!)) {
        items.add(MediaItem.video(post.video!, posterUrl: url));
        videoIndex++;
      } else if (post.image != null && url == post.image && _isValidUrl(post.image!)) {
        items.add(MediaItem.image(url));
      }
    }

    final validItems = items.where((item) => item.url.isNotEmpty).toList();

    if (validItems.isNotEmpty) {
      Navigator.of(context).pushNamed(
        RouteNames.mediaViewer,
        arguments: {
          'items': validItems,
          'initialIndex': initialIndex,
        },
      );
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Widget _buildUserAvatar(BuildContext context, String avatarUrl) {
    final String effectiveAvatarUrl = avatarUrl.isNotEmpty ? avatarUrl : AppConstants.userAvatarPlaceholder;

    return GestureDetector(
      onTap: () => _navigateToProfile(context, PostUtils.getUserUsername(widget.post.user, '')),
      child: Container(
        width: PostConstants.avatarSize,
        height: PostConstants.avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgCard,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: effectiveAvatarUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
            errorWidget: (context, url, error) => CachedNetworkImage(
              imageUrl: AppConstants.userAvatarPlaceholder,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
              errorWidget: (context, url, error) => const Icon(
                CupertinoIcons.person,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallUserAvatar(BuildContext context, String avatarUrl) {
    final String effectiveAvatarUrl = avatarUrl.isNotEmpty ? avatarUrl : AppConstants.userAvatarPlaceholder;

    return GestureDetector(
      onTap: () => _navigateToProfile(context, PostUtils.getUserUsername(widget.post.originalPost?.user, '')),
      child: Container(
        width: PostConstants.repostAvatarSize,
        height: PostConstants.repostAvatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgCard,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: effectiveAvatarUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
            errorWidget: (context, url, error) => CachedNetworkImage(
              imageUrl: AppConstants.userAvatarPlaceholder,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
              errorWidget: (context, url, error) => const Icon(
                CupertinoIcons.person,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String username) {
    ProfileNavigationUtils.navigateToProfile(context, username);
  }

  bool _needsExpansion(String content) {
    if (content.trim().isEmpty) {
      return false;
    }

    final headerInfo = PostUtils.extractHeaderIfPresent(content);
    final hasHeader = headerInfo['hasHeader'] as bool;

    if (hasHeader) {
      return headerInfo['hasMoreContent'] as bool;
    } else {
      return content.length > PostConstants.maxContentLength;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final transparentBackground = widget.transparentBackground;
    final margin = widget.margin;
    final isFullWidth = widget.isFullWidth;
    final semiTransparent = widget.semiTransparent;
    final backgroundColor = widget.backgroundColor;
    final opacity = widget.opacity;
    final onLikePressed = widget.onLikePressed;
    final onRepostPressed = widget.onRepostPressed;
    final onCommentsPressed = widget.onCommentsPressed;

    final repostUser = post.user ?? {};
    final repostAvatar = PostUtils.getUserAvatar(repostUser);
    final repostName = PostUtils.getUserName(repostUser, 'Unknown');
    final repostUsername = PostUtils.getUserUsername(repostUser, '');

    final originalPost = post.originalPost!;
    final originalUser = originalPost.user ?? {};
    final originalAvatar = PostUtils.getUserAvatar(originalUser);
    final originalName = PostUtils.getUserName(originalUser, 'Unknown');
    final originalUsername = PostUtils.getUserUsername(originalUser, '');
    final originalLikesCount = originalPost.likesCount;

    final needsRepostExpansion = _needsExpansion(post.content);
    final needsOriginalExpansion = _needsExpansion(originalPost.content);
    final needsCommonExpand = (post.content.isNotEmpty && needsRepostExpansion) || (originalPost.content.isNotEmpty && needsOriginalExpansion);

    return RepaintBoundary(
      child: Container(
        padding: transparentBackground
            ? const EdgeInsets.symmetric(horizontal: PostConstants.transparentPadding)
            : const EdgeInsets.all(PostConstants.cardHorizontalPadding),
        margin: transparentBackground
            ? (margin ?? EdgeInsets.zero)
            : (isFullWidth ? EdgeInsets.zero : (margin ?? const EdgeInsets.symmetric(vertical: PostConstants.cardVerticalPadding, horizontal: 12))),
        decoration: transparentBackground
            ? null
            : BoxDecoration(
                color: semiTransparent
                    ? (AppColors.bgDark.withValues(alpha: 0.5))
                    : (backgroundColor?.withValues(alpha: opacity ?? 1.0) ?? AppColors.bgCard.withValues(alpha: opacity ?? 1.0)),
                borderRadius: isFullWidth ? BorderRadius.zero : BorderRadius.circular(PostConstants.cardBorderRadius),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header с обоими пользователями и иконкой репоста
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Репостер в верхней строке
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserAvatar(context, repostAvatar),
                    const SizedBox(width: PostConstants.elementSpacing),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToProfile(context, repostUsername),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(repostName, style: AppTextStyles.postAuthor),
                                if (post.isPinned) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    CupertinoIcons.pin_fill,
                                    size: 14,
                                    color: context.profileAccentColor,
                                  ),
                                ],
                              ],
                            ),
                            Text('@$repostUsername', style: AppTextStyles.postUsername),
                          ],
                        ),
                      ),
                    ),


                  ],
                ),

                // Оригинальный автор с отступом слева
                Padding(
                  padding: const EdgeInsets.only(left: PostConstants.repostContentIndent, top: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.arrow_counterclockwise,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _buildSmallUserAvatar(context, originalAvatar),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToProfile(context, originalUsername),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(originalName, style: AppTextStyles.postAuthor),
                              Text('@$originalUsername', style: AppTextStyles.postUsername),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: PostConstants.elementSpacing),

            // Содержание репоста (комментарий от репостера)
            if (post.content.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.only(left: 12, top: 0),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: context.profileAccentColor,
                      width: 3,
                    ),
                  ),
                ),
                child: PostContent(
                  content: post.content,
                  isExpandedOverride: needsCommonExpand ? _isExpanded : null,
                ),
              ),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Содержание оригинального поста
            if (originalPost.content.isNotEmpty) ...[
              PostContent(
                content: originalPost.content,
                isRepostContent: true,
                isExpandedOverride: needsCommonExpand ? _isExpanded : null,
              ),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Медиа оригинального поста
            if (PostUtils.hasMedia(originalPost.images, originalPost.image, originalPost.video)) ...[
              PostMedia(
                images: originalPost.images,
                singleImage: originalPost.image,
                videoUrl: originalPost.video,
                videoPoster: originalPost.videoPoster,
                isFullWidth: isFullWidth,
                onMediaTap: (index) => _openMediaViewer(originalPost, index),
              ),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Музыка оригинального поста
            if (PostUtils.hasMusic(originalPost.music)) ...[
              PostMusic(tracks: originalPost.music!),
              const SizedBox(height: PostConstants.elementSpacing),
            ],

            // Общая кнопка "Развернуть" если есть что развернуть в некоторых контентах и текст еще не развернут
            if (needsCommonExpand && !_isExpanded) ...[
              const SizedBox(height: PostConstants.elementSpacing),
              Center(
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
              ),
            ],

            // Действия для репоста
            PostActions(
              isLiked: post.isLiked,
              likesCount: post.likesCount,
              originalLikesCount: originalLikesCount,
              lastComment: post.lastComment,
              commentsCount: post.commentsCount,
              onLikePressed: onLikePressed,
              onRepostPressed: onRepostPressed,
              onCommentsPressed: onCommentsPressed,
            ),
          ],
        ),
      )
      );
  }
}
