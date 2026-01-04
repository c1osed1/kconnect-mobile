//feed_screen

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_colors.dart';
import '../../core/utils/theme_extensions.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/auth/presentation/blocs/auth_state.dart';
import 'presentation/blocs/feed_bloc.dart';
import 'presentation/blocs/feed_event.dart';
import 'presentation/blocs/feed_state.dart';
import 'components/post_card_new.dart';
import 'widgets/online_users_bar.dart';

import 'widgets/post_shimmer.dart';
import 'components/feed_scroll_mixin.dart';

/// Thin loading bar with shimmer animation
class _LoadingBar extends StatefulWidget {
  final Color color;

  const _LoadingBar({required this.color});

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animationValue = _controller.value;
        return Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.2),
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.5 + (animationValue * 3), 0),
                        end: Alignment(-0.5 + (animationValue * 3), 0),
                        colors: [
                          widget.color.withValues(alpha: 0.0),
                          widget.color,
                          widget.color.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FeedScreen extends StatefulWidget {
  final ValueNotifier<bool> isTabAnimating;
  final void Function(bool) onScrollChanged;
  final ValueNotifier<bool> scrollToTopRequested;

  const FeedScreen({super.key, required this.isTabAnimating, required this.onScrollChanged, required this.scrollToTopRequested});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin, FeedScrollMixin<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showScrollToTop = ValueNotifier(false);
  bool _hasInitialized = false;

  void _onScrollToTopRequested() {
    if (widget.scrollToTopRequested.value) {
      scrollToTop();
      widget.scrollToTopRequested.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.scrollToTopRequested.addListener(_onScrollToTopRequested);
    // Initialize scroll listeners when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) => initScrollListeners());
  }

  @override
  bool get wantKeepAlive => true;

  // Геттеры для FeedScrollMixin
  @override
  FeedBloc get feedBloc => context.read<FeedBloc>();
  @override
  ScrollController get scrollController => _scrollController;
  @override
  ValueNotifier<bool> get showScrollToTop => _showScrollToTop;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is AuthAuthenticated && !_hasInitialized) {
          // Initialize feed once auth is confirmed
          context.read<FeedBloc>().add(InitFeedEvent());
          _hasInitialized = true;
        } else if (authState is AuthUnauthenticated) {
          setState(() {
            _hasInitialized = false;
          });
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // Show loading while auth is being checked
          if (authState is AuthLoading || authState is AuthInitial) {
            return CupertinoPageScaffold(
              backgroundColor: AppColors.bgDark,
              child: const SafeArea(
                child: Center(
                  child: CupertinoActivityIndicator(radius: 20),
                ),
              ),
            );
          }

          // If unauthenticated, show nothing or handle navigation
          if (authState is AuthUnauthenticated) {
            return const SizedBox.shrink(); // Or navigate to login
          }

          // If authenticated, show the feed
          if (authState is AuthAuthenticated) {
            return BlocListener<FeedBloc, FeedState>(
              listener: (context, state) {
                // Show error snackbar if we have posts and an error occurred
                if (state.error != null && state.posts.isNotEmpty && state.status == FeedStatus.success) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Не удалось обновить ленту',
                                  style: const TextStyle(color: CupertinoColors.white),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  context.read<FeedBloc>().add(RefreshFeedEvent());
                                }, minimumSize: Size(0, 0),
                                child: const Text(
                                  'Повторить',
                                  style: TextStyle(
                                    color: CupertinoColors.activeBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.bgDark.withValues(alpha: 0.9),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  });
                }
              },
              child: BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  // Handle initial loading state
                  if (state.status == FeedStatus.loading && state.posts.isEmpty) {
                    return Scaffold(
                      backgroundColor: AppColors.bgDark,
                      body: const SafeArea(
                        child: Center(
                          child: CupertinoActivityIndicator(radius: 20),
                        ),
                      ),
                    );
                  }

                  // Handle initial error state
                  if (state.status == FeedStatus.failure && state.posts.isEmpty) {
                    return Scaffold(
                      backgroundColor: AppColors.bgDark,
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.wifi_slash,
                                size: 64,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.error ?? 'Не удалось загрузить ленту',
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton.filled(
                                onPressed: () {
                                  context.read<FeedBloc>().add(InitFeedEvent());
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox.expand(
                    child: Scaffold(
                      backgroundColor: AppColors.bgDark,
                      body: SafeArea(
                        child: Column(
                          children: [
                            const OnlineUsersBar(),
                            // Thin loading bar with shimmer animation under online users bar
                            if (state.isRefreshing && state.posts.isNotEmpty)
                              _LoadingBar(color: context.dynamicPrimaryColor),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  context.read<FeedBloc>().add(RefreshFeedEvent());
                                },
                                color: context.dynamicPrimaryColor,
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  cacheExtent: 800,
                                  slivers: [
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (index >= state.posts.length) {
                                            if (state.paginationStatus == PaginationStatus.loading) {
                                              return const PostShimmer();
                                            } else if (state.paginationStatus == PaginationStatus.failed) {
                                              return Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Column(
                                                    children: [
                                                      const Text(
                                                        'Не удалось загрузить больше постов',
                                                        style: TextStyle(
                                                          color: CupertinoColors.systemGrey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      CupertinoButton(
                                                        onPressed: () {
                                                          context.read<FeedBloc>().add(FetchPostsEvent());
                                                        },
                                                        child: const Text('Повторить'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return const SizedBox();
                                            }
                                          }
                                          final post = state.posts[index];
                                          return PostCardNew(
                                            postId: post.id,
                                            key: ValueKey(post.id),
                                          );
                                        },
                                        childCount: state.posts.length + (state.paginationStatus == PaginationStatus.loading ? 1 : 0),
                                        addAutomaticKeepAlives: false,
                                        addRepaintBoundaries: true,
                                        addSemanticIndexes: false,
                                      ),
                                    ),
                                    const SliverToBoxAdapter(
                                      child: SizedBox(height: 80),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          // Default loading state
          return CupertinoPageScaffold(
            backgroundColor: AppColors.bgDark,
            child: const SafeArea(
              child: Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollToTopRequested.removeListener(_onScrollToTopRequested);
    _scrollController.dispose();
    _showScrollToTop.dispose();
    super.dispose();
  }
}
