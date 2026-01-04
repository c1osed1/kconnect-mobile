import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_colors.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_event.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_state.dart';
import 'components/profile_header.dart';
import 'components/profile_screen_header.dart';
import 'components/profile_background.dart';
import 'components/profile_content_card.dart';
import 'components/profile_posts_section.dart';
import 'components/swipe_pop_container.dart';
import 'utils/profile_color_utils.dart';
import 'utils/profile_cache_utils.dart';
import '../../core/widgets/profile_accent_color_provider.dart';

class OtherProfileScreen extends StatefulWidget {
  final String username;

  const OtherProfileScreen({super.key, required this.username});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> with AutomaticKeepAliveClientMixin, ProfileCacheManager {
  late ProfileBloc _profileBloc;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileBloc = context.read<ProfileBloc>();
  }

  @override
  void initState() {
    super.initState();
    initCacheManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileBloc>().add(PushProfileStackEvent(widget.username));
      }
    });
  }

  @override
  void dispose() {
    _profileBloc.add(PopProfileStackEvent());
    disposeCacheManager();
    super.dispose();
  }

  @override
  void onAppResumed() {
    _checkCacheAndRefreshIfNeeded();
  }

  void _checkCacheAndRefreshIfNeeded() async {
    try {
      final shouldRefresh = await shouldRefreshCache(_getPostsCount(), null);
      if (shouldRefresh) {
        _profileBloc.add(RefreshProfileEvent(forceRefresh: true));
      }
    } catch (e) {
      // Ошибка
    }
  }

  int? _getPostsCount() {
    final currentState = _profileBloc.state;
    if (currentState is ProfileLoaded) {
      return currentState.posts.length + (currentState.pinnedPost != null ? 1 : 0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && state.isRefreshing == false) {
          if (state.postsError && state.postsErrorMessage != null) {
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
                            state.postsErrorMessage ?? 'Не удалось загрузить посты',
                            style: const TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.read<ProfileBloc>().add(LoadProfilePostsEvent(
                              state.profile.id.toString(),
                              forceRefresh: true,
                            ));
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
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (previous, current) {
          if (current.isLoaded) {
            final currentLoaded = current.asLoaded!;
            final previousLoaded = previous.isLoaded ? previous.asLoaded! : null;
            
            final currentMatches = currentLoaded.profile.username == widget.username && 
                                  currentLoaded.isValidForUsername(widget.username);
            final previousMatches = previousLoaded != null && 
                                   previousLoaded.profile.username == widget.username && 
                                   previousLoaded.isValidForUsername(widget.username);
            
            if (currentMatches && !previousMatches) {
              return true;
            }
            if (currentMatches && previousMatches) {
              return previous != current;
            }
            return false;
          }
          return true;
        },
        builder: (context, state) {
          if (state.isLoaded) {
            final loadedState = state.asLoaded!;
  
            if (!loadedState.isValidForUsername(widget.username)) {
              return const Center(child: CupertinoActivityIndicator());
            }
            return _buildProfileView(loadedState);
          }

          if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.asError!.message,
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () {
                      context.read<ProfileBloc>().add(PushProfileStackEvent(widget.username));
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CupertinoActivityIndicator());
        },
      ),
    );
  }

  Widget _buildProfileView(ProfileLoaded profileState) {
    final profile = profileState.profile;
    final isOtherProfile = true;
    final accentColor = ProfileColorUtils.getProfileAccentColor(profile, context);

    final scrollView = ProfileAccentColorProvider(
      accentColor: accentColor,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(RefreshProfileEvent());
            },
            color: accentColor,
            child: CustomScrollView(
              slivers: [
                ProfileHeader(
                  profile: profile,
                  accentColor: accentColor,
                  isSkeleton: profileState.isSkeleton,
                ),
                SliverToBoxAdapter(
                  child: ProfileContentCard(
                    profile: profile,
                    followingInfo: profileState.followingInfo,
                    profileState: profileState,
                    accentColor: accentColor,
                    onEditPressed: null,
                    onFollowPressed: () => context.read<ProfileBloc>().add(FollowUserEvent(profile.username)),
                    onUnfollowPressed: () => context.read<ProfileBloc>().add(UnfollowUserEvent(profile.username)),
                  ),
                ),
                ProfilePostsSection(
                  profileState: profileState,
                  accentColor: accentColor,
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    late Widget scrollContent;
    if (isOtherProfile) {
      scrollContent = Column(
        children: [
          ProfileScreenHeader(
            username: profile.username,
            accentColor: accentColor,
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: scrollView),
        ],
      );
    }

    final screenWidget = Container(
      color: AppColors.bgDark.withValues(alpha:0.8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (profile.profileBackgroundUrl != null)
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
              child: ProfileBackground(
                backgroundUrl: profile.profileBackgroundUrl,
              ),
            ),
          SafeArea(
            bottom: true,
            child: scrollContent,
          ),
        ],
      ),
    );

    return SwipePopContainer(
      child: screenWidget,
    );
  }



}
