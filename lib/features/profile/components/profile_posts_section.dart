/// Секция постов профиля с закреплёнными и обычными постами
///
/// Управляет отображением постов профиля: закреплённый пост вверху,
/// затем обычные посты с пагинацией и загрузкой по требованию.
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feed/domain/models/post.dart';
import '../presentation/blocs/profile_state.dart';
import '../presentation/blocs/profile_event.dart';
import '../presentation/blocs/profile_bloc.dart';
import '../../feed/components/post_card_new.dart';
import '../../feed/widgets/post_shimmer.dart';

/// Виджет секции постов профиля с закреплёнными постами
///
/// Отображает посты пользователя с поддержкой закреплённых постов,
/// пагинации и обработки ошибок загрузки.
class ProfilePostsSection extends StatelessWidget {
  final ProfileLoaded profileState;
  final Color accentColor;

  const ProfilePostsSection({
    super.key,
    required this.profileState,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Show error state if posts failed to load
    if (profileState.postsError) {
      return SliverToBoxAdapter(
        child: _buildPostsErrorWidget(context),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final hasPinnedPost = profileState.pinnedPost != null;
          final pinnedPostOffset = hasPinnedPost ? 1 : 0;
          final totalRegularPosts = profileState.posts.length;

          // Handle pinned post (first item if exists)
          if (hasPinnedPost && index == 0) {
            return _buildPostCard(profileState.pinnedPost!, context, accentColor);
          }

          // Handle regular posts
          final regularIndex = index - pinnedPostOffset;
          if (regularIndex >= totalRegularPosts) {
            if (profileState.isLoadingPosts) {
              return const PostShimmer();
            } else if (profileState.hasNextPosts) {
              // Load more posts
              context.read<ProfileBloc>().add(FetchMoreProfilePostsEvent(
                userId: profileState.profile.username,
                page: profileState.currentPostsPage + 1,
                perPage: profileState.postsPerPage,
              ));
              return const PostShimmer();
            } else {
              return const SizedBox();
            }
          }
          return _buildPostCard(profileState.posts[regularIndex], context, accentColor);
        },
        childCount: profileState.posts.length + (profileState.pinnedPost != null ? 1 : 0) + (profileState.isLoadingPosts ? 1 : 0) + (profileState.hasNextPosts ? 1 : 0),
      ),
    );
  }

  Widget _buildPostCard(Post post, BuildContext context, Color accentColor) {
    return PostCardNew(
      post: post,
      key: ValueKey(post.id),
      opacity: 0.8,
      onLike: () {
        context.read<ProfileBloc>().add(LikeProfilePostEvent(post.id, post));
      },
      isLikeProcessing: profileState.processingLikes.contains(post.id),
    );
  }

  Widget _buildPostsErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
            'Не удалось загрузить посты',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (profileState.postsErrorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                profileState.postsErrorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CupertinoColors.systemGrey2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () {
              context.read<ProfileBloc>().add(RetryProfilePostsEvent());
            },
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
}
