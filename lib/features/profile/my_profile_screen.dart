/// Экран моего профиля с поддержкой keep alive и кэширования
///
/// Отображает профиль текущего пользователя с постами,
/// статистикой и возможностью редактирования.
/// Поддерживает автоматическое обновление кэша при возобновлении работы приложения.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_event.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_state.dart';
import '../../../providers/profile_bloc_providers.dart';
import 'components/profile_header.dart';
import 'components/profile_background.dart';
import 'components/profile_content_card.dart';
import 'components/profile_posts_section.dart';
import 'utils/profile_color_utils.dart';
import 'utils/profile_cache_utils.dart';
import '../../core/widgets/profile_accent_color_provider.dart';

/// Экран моего профиля с поддержкой keep alive
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with AutomaticKeepAliveClientMixin, ProfileCacheManager {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    initCacheManager();
  }

  @override
  void dispose() {
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
      if (!mounted) return;
      if (shouldRefresh) {
        context.read<ProfileBloc>().add(RefreshProfileEvent(forceRefresh: true));
      }
    } catch (e) {
      // Ошибка
    }
  }

  int? _getPostsCount() {
    final currentState = context.read<ProfileBloc>().state;
    if (currentState is ProfileLoaded) {
      return currentState.posts.length + (currentState.pinnedPost != null ? 1 : 0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider<ProfileBloc>(
      create: (BuildContext context) {
        final authBloc = BlocProvider.of<AuthBloc>(context);
        return ProfileBlocProviders.createProfileBloc(authBloc);
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<ProfileBloc>().add(LoadCurrentProfileEvent());
          });
        }

        ProfileLoaded? profileState;

        if (state.isLoaded) {
          profileState = state.asLoaded!;
        }

        if (profileState != null) {
          return _buildProfileView(profileState);
        }

        if (state.isError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.asError!.message,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () async {
                    if (!mounted) return;
                    context.read<ProfileBloc>().add(LoadCurrentProfileEvent());
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        if (state.isUpdated) {
          final updatedState = state.asUpdated!;
          profileState = ProfileLoaded(
            profile: updatedState.profile,
            isOwnProfile: true,
            isSkeleton: false,
          );
          return _buildProfileView(profileState);
        }

        return const Center(child: CupertinoActivityIndicator());
      },
    )
    );
  }

  Widget _buildProfileView(ProfileLoaded profileState) {
    final profile = profileState.profile;
    final accentColor = ProfileColorUtils.getProfileAccentColor(profile, context);

    final scrollView = ProfileAccentColorProvider(
      accentColor: accentColor,
      child: RefreshIndicator(
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
                onEditPressed: _showEditProfileDialog,
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
    );

    final screenWidget = Container(
      color: AppColors.bgDark.withValues(alpha:0.8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (profile.profileBackgroundUrl != null)
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: ProfileBackground(
                backgroundUrl: profile.profileBackgroundUrl,
              ),
            ),
          SafeArea(
            bottom: true,
            child: scrollView,
          ),
        ],
      ),
    );

    return screenWidget;
  }

  VoidCallback get _showEditProfileDialog => () => showCupertinoDialog(
        // TODO: Реализовать диалог редактирования профиля
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Редактирование профиля'),
          content: const Text('Эта функция будет реализована в следующей версии'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

}
