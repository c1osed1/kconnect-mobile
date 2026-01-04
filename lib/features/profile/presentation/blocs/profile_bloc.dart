import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';
import 'package:kconnect_mobile/features/feed/domain/models/post.dart';
import 'package:kconnect_mobile/features/feed/domain/usecases/fetch_posts_usecase.dart';
import 'package:kconnect_mobile/features/profile/domain/models/following_info.dart';
import 'package:kconnect_mobile/features/profile/domain/models/profile_posts_response.dart';
import 'package:kconnect_mobile/features/profile/domain/models/user_profile.dart';
import 'package:kconnect_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:kconnect_mobile/features/profile/domain/usecases/fetch_pinned_post_usecase.dart';
import 'package:kconnect_mobile/features/profile/domain/usecases/fetch_user_posts_usecase.dart';
import 'package:kconnect_mobile/features/profile/domain/usecases/fetch_user_profile_usecase.dart';
import 'package:kconnect_mobile/features/profile/domain/usecases/follow_user_usecase.dart';
import 'package:kconnect_mobile/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_event.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_state.dart';

/// BLoC для управления состоянием профиля пользователя
///
/// Отвечает за загрузку профилей, постов, управление подписками,
/// обновление профиля и навигацию между профилями в стеке.
/// Обеспечивает последовательную загрузку данных для предотвращения конфликтов.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FetchUserProfileUseCase _fetchProfileUseCase;
  final FetchUserPostsUseCase _fetchUserPostsUseCase;
  final FetchPinnedPostUseCase _fetchPinnedPostUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final FollowUserUseCase _followUserUseCase;
  final LikePostUseCase _likePostUseCase;
  final ProfileRepository _repository;
  final AuthBloc _authBloc;

  /// Stack for nested profile navigation
  final List<ProfileStackEntry> _profileStack = [];

  /// Track loading states to prevent concurrent operations
  final Map<String, bool> _loadingProfiles = {};
  final Map<String, bool> _loadingPosts = {};
  
  /// Track last push time to prevent rapid repeated pushes
  final Map<String, DateTime> _lastPushTime = {};

  /// Get current state - last in stack or initial
  ProfileState get _currentState =>
      _profileStack.isNotEmpty ? _profileStack.last.state : ProfileInitial();

  /// Update stack entry with current state if it matches the username
  void _updateStackEntryWithState(ProfileLoaded state) {
    if (_profileStack.isNotEmpty) {
      final lastEntry = _profileStack.last;
      if (lastEntry.username == state.profile.username || 
          (lastEntry.username == 'current' && state.isOwnProfile)) {
        _profileStack[_profileStack.length - 1] = ProfileStackEntry(
          username: lastEntry.username,
          state: state,
        );
        debugPrint('ProfileBloc: Updated stack entry for ${lastEntry.username} with state (posts=${state.posts.length}, followingInfo=${state.followingInfo != null})');
      }
    }
  }

  ProfileBloc({
    required AuthBloc authBloc,
    required FetchUserProfileUseCase fetchProfileUseCase,
    required FetchUserPostsUseCase fetchUserPostsUseCase,
    required FetchPinnedPostUseCase fetchPinnedPostUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required FollowUserUseCase followUserUseCase,
    required LikePostUseCase likePostUseCase,
    required ProfileRepository repository,
  })  : _authBloc = authBloc,
        _fetchProfileUseCase = fetchProfileUseCase,
        _fetchUserPostsUseCase = fetchUserPostsUseCase,
        _fetchPinnedPostUseCase = fetchPinnedPostUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _followUserUseCase = followUserUseCase,
        _likePostUseCase = likePostUseCase,
        _repository = repository,
        super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<LoadCurrentProfileEvent>(_onLoadCurrentProfile);
    on<LoadProfileStatsEvent>(_onLoadProfileStats);
    on<LoadProfilePostsEvent>(_onLoadProfilePosts);
    on<FetchMoreProfilePostsEvent>(_onFetchMoreProfilePosts);
    on<LoadFollowingInfoEvent>(_onLoadFollowingInfo);
    on<LoadFollowingInfoWithFollowersEvent>(_onLoadFollowingInfoWithFollowers);
    on<LikeProfilePostEvent>(_onLikeProfilePost);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfileStatusEvent>(_onUpdateProfileStatus);
    on<UpdateProfileAvatarEvent>(_onUpdateProfileAvatar);
    on<DeleteProfileAvatarEvent>(_onDeleteProfileAvatar);
    on<AddSocialLinkEvent>(_onAddSocialLink);
    on<DeleteSocialLinkEvent>(_onDeleteSocialLink);
    on<FollowUserEvent>(_onFollowUser);
    on<UnfollowUserEvent>(_onUnfollowUser);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<RefreshProfileEvent>(_onRefreshProfile);
    on<ClearProfileCacheEvent>(_onClearProfileCache);
    on<PushProfileStackEvent>(_onPushProfileStack);
    on<PopProfileStackEvent>(_onPopProfileStack);
    on<RetryProfilePostsEvent>(_onRetryProfilePosts);
  }

  String? get _currentUserId {
    if (_authBloc.state is AuthAuthenticated) {
      return (_authBloc.state as AuthAuthenticated).user.username;
    }
    return null;
  }

  String? get _currentUserDBId {
    if (_authBloc.state is AuthAuthenticated) {
      return (_authBloc.state as AuthAuthenticated).user.id;
    }
    return null;
  }

  bool _isOwnProfile(String userIdentifier) {
    return userIdentifier == 'current' || userIdentifier == _currentUserId;
  }

  void _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    debugPrint('ProfileBloc: _onLoadProfile called with userIdentifier=${event.userIdentifier}, forceRefresh=${event.forceRefresh}');

    // Check if already loading this profile to prevent concurrent operations
    final loadingKey = event.userIdentifier;
    if (_loadingProfiles[loadingKey] == true) {
      debugPrint('ProfileBloc: Profile $loadingKey is already loading, skipping');
      return;
    }

    // Capture current state snapshot at the start - this is critical for preserving data
    final currentStateSnapshot = state;
    ProfileLoaded? existingState;
    // Only consider non-skeleton loaded states as existing (skeleton states should be replaced)
    if (currentStateSnapshot is ProfileLoaded && 
        currentStateSnapshot.profile.username == event.userIdentifier &&
        !currentStateSnapshot.isSkeleton &&
        currentStateSnapshot.profile.id != 0) {
      existingState = currentStateSnapshot;
      debugPrint('ProfileBloc: Found existing non-skeleton state for ${event.userIdentifier}, posts=${existingState.posts.length}, followingInfo=${existingState.followingInfo != null}');
    }

    // Set loading flag
    _loadingProfiles[loadingKey] = true;

    try {
      // If we have existing profile for this user, keep it visible
      // Only show loading if there's no existing profile
      if (existingState != null && !event.forceRefresh) {
        emit(existingState.copyWith(isRefreshing: true));
        debugPrint('ProfileBloc: Keeping existing profile visible, setting isRefreshing=true');
      } else if (existingState == null) {
        emit(ProfileLoading());
        debugPrint('ProfileBloc: Emitting ProfileLoading state');
      } else {
        // forceRefresh with existing profile - still show it but mark as refreshing
        emit(existingState.copyWith(isRefreshing: true));
        debugPrint('ProfileBloc: Force refresh with existing profile, setting isRefreshing=true');
      }

      final profile = await _fetchProfileUseCase.execute(
        event.userIdentifier,
        forceRefresh: event.forceRefresh,
      );
      debugPrint('ProfileBloc: Profile loaded successfully - id=${profile.id}, username=${profile.username}, name=${profile.name}');

      final isOwnProfile = _isOwnProfile(event.userIdentifier);
      debugPrint('ProfileBloc: isOwnProfile=$isOwnProfile');

      // CRITICAL FIX: Use the original existingState captured at the start, not latestState
      // This ensures we preserve all data (posts, followingInfo, etc.) even if state changed during loading
      // Only fall back to latestState if existingState was null (new profile)
      ProfileLoaded? stateToUpdate;
      if (existingState != null) {
        // Use the original existingState to preserve all data
        stateToUpdate = existingState;
        debugPrint('ProfileBloc: Using original existingState to preserve data');
      } else {
        // For new profiles, check latest state (might have been set by skeleton)
        final latestState = state;
        if (latestState is ProfileLoaded && latestState.profile.username == event.userIdentifier) {
          stateToUpdate = latestState;
          debugPrint('ProfileBloc: Using latestState for new profile');
        }
      }

      // Always update profile completely, preserving all existing data (posts, pinnedPost, followingInfo)
      ProfileLoaded updatedProfileState;
      if (stateToUpdate != null) {
        // Explicitly preserve all data: posts, pinnedPost, followingInfo, stats, etc.
        updatedProfileState = stateToUpdate.copyWith(
          profile: profile, // Always update profile with fresh data (includes banner)
          isRefreshing: false,
          postsError: false,
          postsErrorMessage: null,
          isSkeleton: false, // Explicitly remove skeleton when profile is loaded
          // Explicitly preserve: posts, pinnedPost, followingInfo, stats are preserved by copyWith
        );
        emit(updatedProfileState);
        debugPrint('ProfileBloc: Updated profile, preserved posts count=${stateToUpdate.posts.length}, pinnedPost=${stateToUpdate.pinnedPost != null}, followingInfo=${stateToUpdate.followingInfo != null}');
      } else {
        updatedProfileState = ProfileLoaded(
          profile: profile,
          isOwnProfile: isOwnProfile,
          isRefreshing: false,
          isSkeleton: false, // Explicitly set to false to remove skeleton
        );
        emit(updatedProfileState);
        debugPrint('ProfileBloc: Created new ProfileLoaded state');
      }
      
      // Update stack entry with loaded profile
      _updateStackEntryWithState(updatedProfileState);
      
      debugPrint('ProfileBloc: Emitted ProfileLoaded state with updated profile (banner: ${profile.bannerUrl}, background: ${profile.profileBackgroundUrl})');

      // Load posts sequentially after profile is loaded and state is updated
      // This ensures posts are loaded with correct profile state
      // Only load posts if forceRefresh is true OR if we don't have posts yet
      final finalState = state;
      if (finalState is ProfileLoaded) {
        final shouldLoadPosts = event.forceRefresh || finalState.posts.isEmpty;
        if (shouldLoadPosts) {
          await _loadProfilePostsSequentially(profile.id.toString(), event.forceRefresh, emit);
        } else {
          debugPrint('ProfileBloc: Skipping posts load - already have posts and not forceRefresh');
        }
      } else {
        await _loadProfilePostsSequentially(profile.id.toString(), event.forceRefresh, emit);
      }

    } catch (e) {
      debugPrint('ProfileBloc: Error loading profile - ${e.toString()}');
      // Get current state to preserve data
      final errorState = state;
      if (errorState is ProfileLoaded && errorState.profile.username == event.userIdentifier) {
        emit(errorState.copyWith(
          isRefreshing: false,
        ));
        // Error will be shown via snackbar or other UI mechanism
      } else {
        emit(ProfileError('Не удалось загрузить профиль: ${e.toString()}'));
      }
    } finally {
      // Clear loading flag
      _loadingProfiles[loadingKey] = false;
    }
  }

  /// Helper method to load posts sequentially after profile is loaded
  Future<void> _loadProfilePostsSequentially(String userId, bool forceRefresh, Emitter<ProfileState> emit) async {
    // Check if already loading posts for this user
    if (_loadingPosts[userId] == true) {
      debugPrint('ProfileBloc: Posts for userId=$userId are already loading, skipping');
      return;
    }

    _loadingPosts[userId] = true;

    try {
      final currentState = state;
      if (currentState is! ProfileLoaded) {
        debugPrint('ProfileBloc: Cannot load posts - current state is not ProfileLoaded: ${currentState.runtimeType}');
        return;
      }

      debugPrint('ProfileBloc: Loading posts sequentially for userId=$userId, forceRefresh=$forceRefresh');
      emit(currentState.copyWith(isLoadingPosts: true, postsError: false, postsErrorMessage: null));

      // Load posts and pinned post concurrently
      final [response, pinnedPost] = await Future.wait([
        _repository.fetchUserPosts(
          userId: userId,
          page: 1,
          perPage: 10,
          forceRefresh: forceRefresh,
        ),
        _fetchPinnedPostUseCase.execute(currentState.profile.username),
      ]);

      // Get latest state to ensure we have the most recent profile data
      final latestState = state;
      if (latestState is! ProfileLoaded) {
        debugPrint('ProfileBloc: State changed during posts loading, aborting');
        return;
      }

      // Filter out pinned post from regular posts if it exists
      final ProfilePostsResponse originalResponse = response as ProfilePostsResponse;
      final Post? pinnedPostTyped = pinnedPost as Post?;
      final filteredResponse = pinnedPostTyped != null
          ? ProfilePostsResponse(
              posts: originalResponse.posts
                  .where((post) => post.id != pinnedPostTyped.id)
                  .toList(),
              hasNext: originalResponse.hasNext,
              hasPrev: originalResponse.hasPrev,
              page: originalResponse.page,
              pages: originalResponse.pages,
              perPage: originalResponse.perPage,
              total: originalResponse.total,
            )
          : originalResponse;

      // Update state preserving profile and all other data
      final updatedState = latestState.copyWith(
        isLoadingPosts: false,
        pinnedPost: pinnedPost,
      ).setPosts(filteredResponse);

      debugPrint('ProfileBloc: Posts loaded successfully - count=${filteredResponse.posts.length}, hasNext=${filteredResponse.hasNext}');
      emit(updatedState);
      
      // Update stack entry with loaded posts
      _updateStackEntryWithState(updatedState);

      // Load following info sequentially after posts are loaded
      await _loadFollowingInfoSequentially(latestState.profile.id.toString(), latestState.profile.username, latestState.isOwnProfile, emit);

    } catch (e) {
      debugPrint('ProfileBloc: Error loading posts - ${e.toString()}');
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(currentState.copyWith(
          isLoadingPosts: false,
          postsError: true,
          postsErrorMessage: 'Не удалось загрузить посты: ${e.toString()}',
        ));
      }
    } finally {
      _loadingPosts[userId] = false;
    }
  }

  /// Helper method to load following info sequentially after posts are loaded
  Future<void> _loadFollowingInfoSequentially(String profileId, String username, bool isOwnProfile, Emitter<ProfileState> emit) async {
    if (isOwnProfile || _currentUserDBId == null) {
      debugPrint('ProfileBloc: Skipping following info - isOwnProfile=$isOwnProfile, currentUserDBId=$_currentUserDBId');
      return;
    }

    try {
      debugPrint('ProfileBloc: Loading following info sequentially for profileId=$profileId');
      final followingInfo = await _repository.fetchFollowingInfoWithFollowers(
        profileId: profileId,
        currentUserId: _currentUserDBId!,
      );
      debugPrint('ProfileBloc: Following info loaded successfully');

      // Get latest state to preserve all data
      final currentState = state;
      if (currentState is ProfileLoaded) {
        // Preserve all data: profile, posts, pinnedPost, etc.
        final updatedState = currentState.copyWith(followingInfo: followingInfo);
        emit(updatedState);
        
        // Update stack entry with loaded followingInfo
        _updateStackEntryWithState(updatedState);
      }
    } catch (e) {
      debugPrint('ProfileBloc: Failed to fetch following info: $e');
      // Don't emit error for following info - it's optional data
    }
  }

  void _onLoadCurrentProfile(LoadCurrentProfileEvent event, Emitter<ProfileState> emit) async {
    debugPrint('ProfileBloc: _onLoadCurrentProfile called with forceRefresh=${event.forceRefresh}');

    // Use 'current' as identifier for loading flags
    const loadingKey = 'current';
    if (_loadingProfiles[loadingKey] == true) {
      debugPrint('ProfileBloc: Current profile is already loading, skipping');
      return;
    }

    // Capture current state snapshot at the start
    final currentStateSnapshot = state;
    ProfileLoaded? existingState;
    if (currentStateSnapshot is ProfileLoaded && currentStateSnapshot.isOwnProfile) {
      existingState = currentStateSnapshot;
    }

    // Set loading flag
    _loadingProfiles[loadingKey] = true;

    try {
      // If we have existing own profile, keep it visible
      // Only show loading if there's no existing profile
      if (existingState != null && !event.forceRefresh) {
        emit(existingState.copyWith(isRefreshing: true));
        debugPrint('ProfileBloc: Keeping existing own profile visible, setting isRefreshing=true');
      } else if (existingState == null) {
        emit(ProfileLoading());
        debugPrint('ProfileBloc: Emitting ProfileLoading state for current profile');
      } else {
        // forceRefresh with existing profile - still show it but mark as refreshing
        emit(existingState.copyWith(isRefreshing: true));
        debugPrint('ProfileBloc: Force refresh with existing own profile, setting isRefreshing=true');
      }

      final profile = await _repository.fetchCurrentUserProfile(
        forceRefresh: event.forceRefresh,
      );

      final stats = await _repository.fetchUserStats(profile.username);

      // Get current state again to ensure we have latest data
      final latestState = state;
      ProfileLoaded? latestExistingState;
      if (latestState is ProfileLoaded && latestState.isOwnProfile) {
        latestExistingState = latestState;
      }

      // Always update profile completely, preserving all existing data (posts, pinnedPost, followingInfo)
      if (latestExistingState != null) {
        // Explicitly preserve all data: posts, pinnedPost, followingInfo, etc.
        emit(latestExistingState.copyWith(
          profile: profile, // Always update profile with fresh data (includes banner)
          stats: stats,
          isRefreshing: false,
          postsError: false,
          postsErrorMessage: null,
          isSkeleton: false, // Explicitly remove skeleton when profile is loaded
          // Explicitly preserve: posts, pinnedPost, followingInfo are preserved by copyWith
        ));
        debugPrint('ProfileBloc: Updated current profile, preserved posts count=${latestExistingState.posts.length}, pinnedPost=${latestExistingState.pinnedPost != null}');
      } else {
        final profileLoaded = ProfileLoaded(
          profile: profile,
          isOwnProfile: true,
          stats: stats,
          isRefreshing: false,
          isSkeleton: false, // Explicitly set to false to remove skeleton
        );
        emit(profileLoaded);
      }
      debugPrint('ProfileBloc: Emitted ProfileLoaded state with updated current profile (banner: ${profile.bannerUrl}, background: ${profile.profileBackgroundUrl})');

      // Load posts sequentially after profile is loaded and state is updated
      // This ensures posts are loaded with correct profile state
      await _loadProfilePostsSequentially(profile.id.toString(), event.forceRefresh, emit);

    } catch (e) {
      debugPrint('ProfileBloc: Error loading current profile - ${e.toString()}');
      // Get current state to preserve data
      final errorState = state;
      if (errorState is ProfileLoaded && errorState.isOwnProfile) {
        emit(errorState.copyWith(
          isRefreshing: false,
        ));
        // Error will be shown via snackbar or other UI mechanism
      } else {
        emit(ProfileError('Не удалось загрузить профиль: ${e.toString()}'));
      }
    } finally {
      // Clear loading flag
      _loadingProfiles[loadingKey] = false;
    }
  }

  void _onLoadProfileStats(LoadProfileStatsEvent event, Emitter<ProfileState> emit) async {
    try {
      final stats = await _repository.fetchUserStats(event.userIdentifier);
      emit(ProfileStatsLoaded(stats));
    } catch (e) {
      emit(ProfileError('Не удалось загрузить статистику: ${e.toString()}'));
    }
  }

  void _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(ProfileUpdating(currentState.profile));

        await _updateProfileUseCase.updateName(event.name);
        await _updateProfileUseCase.updateUsername(event.username);
        await _updateProfileUseCase.updateAbout(event.about);

        // Refresh profile
        final profile = await _repository.fetchCurrentUserProfile(forceRefresh: true);
        emit(ProfileUpdated(profile));
      }
    } catch (e) {
      emit(ProfileError('Не удалось обновить профиль: ${e.toString()}'));
    }
  }

  void _onUpdateProfileStatus(UpdateProfileStatusEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded && currentState.isOwnProfile) {
        await _updateProfileUseCase.updateStatus(event.statusText, event.statusColor);
        emit(ProfileUpdated(currentState.profile, 'Статус профиля обновлен'));
      }
    } catch (e) {
      emit(ProfileError('Не удалось обновить статус: ${e.toString()}'));
    }
  }

  void _onUpdateProfileAvatar(UpdateProfileAvatarEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded && currentState.isOwnProfile) {
        await _updateProfileUseCase.updateAvatar(event.avatarPath);
        emit(ProfileUpdated(currentState.profile, 'Аватар обновлен'));
      }
    } catch (e) {
      emit(ProfileError('Не удалось обновить аватар: ${e.toString()}'));
    }
  }

  void _onDeleteProfileAvatar(DeleteProfileAvatarEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded && currentState.isOwnProfile) {
        await _updateProfileUseCase.deleteAvatar();
        emit(ProfileUpdated(currentState.profile, 'Аватар удален'));
      }
    } catch (e) {
      emit(ProfileError('Не удалось удалить аватар: ${e.toString()}'));
    }
  }

  void _onAddSocialLink(AddSocialLinkEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded && currentState.isOwnProfile) {
        await _updateProfileUseCase.addSocialLink(event.name, event.link);
        emit(ProfileUpdated(currentState.profile, 'Ссылка добавлена'));
      }
    } catch (e) {
      emit(ProfileError('Не удалось добавить ссылку: ${e.toString()}'));
    }
  }

  void _onDeleteSocialLink(DeleteSocialLinkEvent event, Emitter<ProfileState> emit) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded && currentState.isOwnProfile) {
        await _updateProfileUseCase.deleteSocialLink(event.name);
        emit(ProfileUpdated(currentState.profile, 'Ссылка удалена'));
      }
    } catch (e) {
      emit(ProfileError('Не удалось удалить ссылку: ${e.toString()}'));
    }
  }

  void _onFollowUser(FollowUserEvent event, Emitter<ProfileState> emit) async {
    try {
      await _followUserUseCase.follow(event.username);

      // Update following info after successful follow
      final currentState = state;
      if (currentState is ProfileLoaded && !currentState.isOwnProfile && _currentUserId != null) {
        if (currentState.followingInfo != null) {
          final updatedFollowingInfo = FollowingInfo(
            currentUserFollows: true,
            currentUserIsFriend: currentState.followingInfo!.currentUserIsFriend,
            followsBack: currentState.followingInfo!.followsBack,
          );
          emit(currentState.copyWith(followingInfo: updatedFollowingInfo));
        }
      }

      emit(ProfileFollowSuccess('Вы подписались на @${event.username}', true));
    } catch (e) {
      emit(ProfileError('Не удалось подписаться: ${e.toString()}'));
    }
  }

  void _onUnfollowUser(UnfollowUserEvent event, Emitter<ProfileState> emit) async {
    try {
      await _followUserUseCase.unfollow(event.username);

      // Update following info after successful unfollow
      final currentState = state;
      if (currentState is ProfileLoaded && !currentState.isOwnProfile && _currentUserId != null) {
        if (currentState.followingInfo != null) {
          final updatedFollowingInfo = FollowingInfo(
            currentUserFollows: false,
            currentUserIsFriend: false, // Unfollowing also removes friendship
            followsBack: false,
          );
          emit(currentState.copyWith(followingInfo: updatedFollowingInfo));
        }
      }

      emit(ProfileFollowSuccess('Вы отписались от @${event.username}', false));
    } catch (e) {
      emit(ProfileError('Не удалось отписаться: ${e.toString()}'));
    }
  }

  void _onToggleNotifications(ToggleNotificationsEvent event, Emitter<ProfileState> emit) async {
    try {
      await _followUserUseCase.toggleNotifications(
        event.followedUsername,
        event.enabled,
      );

      final message = event.enabled ? 'Уведомления включены' : 'Уведомления отключены';

      if (state is ProfileLoaded) {
        emit(ProfileUpdated((state as ProfileLoaded).profile, message));
      }
    } catch (e) {
      emit(ProfileError('Не удалось изменить настройки уведомлений: ${e.toString()}'));
    }
  }

  void _onRefreshProfile(RefreshProfileEvent event, Emitter<ProfileState> emit) async {
    debugPrint('ProfileBloc: _onRefreshProfile called with forceRefresh=${event.forceRefresh}');
    final currentState = state;
    if (currentState is ProfileLoaded) {
      debugPrint('ProfileBloc: Refreshing profile, isOwnProfile=${currentState.isOwnProfile}, isSkeleton=${currentState.isSkeleton}, posts count=${currentState.posts.length}');
      
      // If skeleton, we still need to load the profile
      // Check if we have a valid profile ID (not 0, which is skeleton)
      final hasValidProfile = currentState.profile.id != 0;
      
      // Trigger a complete refresh of both profile and posts
      if (currentState.isOwnProfile) {
        debugPrint('ProfileBloc: Adding LoadCurrentProfileEvent');
        add(LoadCurrentProfileEvent(forceRefresh: event.forceRefresh));
      } else if (hasValidProfile) {
        // For other profiles with valid profile, reload with force refresh
        debugPrint('ProfileBloc: Adding LoadProfileEvent for ${currentState.profile.username}');
        add(LoadProfileEvent(currentState.profile.username, forceRefresh: event.forceRefresh));
      } else {
        // Skeleton profile - try to load by username from skeleton
        debugPrint('ProfileBloc: Skeleton profile detected, loading by username: ${currentState.profile.username}');
        add(LoadProfileEvent(currentState.profile.username, forceRefresh: true));
      }

      // Force reload posts if we have a valid profile ID
      if (hasValidProfile) {
        debugPrint('ProfileBloc: Adding LoadProfilePostsEvent for userId=${currentState.profile.id}');
        add(LoadProfilePostsEvent(currentState.profile.id.toString(), forceRefresh: event.forceRefresh));
      }
    } else {
      debugPrint('ProfileBloc: Current state is not ProfileLoaded: ${currentState.runtimeType}');
    }
  }

  void _onClearProfileCache(ClearProfileCacheEvent event, Emitter<ProfileState> emit) async {
    try {
      await _repository.clearCache();
      emit(ProfileInitial()); // Reset to initial state
    } catch (e) {
      emit(ProfileError('Не удалось очистить кеш: ${e.toString()}'));
    }
  }

  void _onLoadProfilePosts(LoadProfilePostsEvent event, Emitter<ProfileState> emit) async {
    debugPrint('ProfileBloc: _onLoadProfilePosts called with userId=${event.userId}, forceRefresh=${event.forceRefresh}');
    // Use the sequential loading method to ensure data consistency
    await _loadProfilePostsSequentially(event.userId, event.forceRefresh, emit);
  }

  void _onFetchMoreProfilePosts(FetchMoreProfilePostsEvent event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is ProfileLoaded && !currentState.isLoadingPosts && currentState.hasNextPosts) {
      try {
        emit(currentState.copyWith(isLoadingPosts: true));

        final response = await _fetchUserPostsUseCase.execute(
          userId: event.userId,
          page: event.page,
          perPage: event.perPage,
        );

        // Filter out pinned post from additional posts if it exists
        final ProfilePostsResponse originalResponse = response;
        final filteredResponse = currentState.pinnedPost != null
            ? ProfilePostsResponse(
                posts: originalResponse.posts
                    .where((post) => post.id != currentState.pinnedPost!.id)
                    .toList(),
                hasNext: originalResponse.hasNext,
                hasPrev: originalResponse.hasPrev,
                page: originalResponse.page,
                pages: originalResponse.pages,
                perPage: originalResponse.perPage,
                total: originalResponse.total,
              )
            : originalResponse;

        emit(currentState.copyWith(
          isLoadingPosts: false,
        ).addPosts(filteredResponse));
      } catch (e) {
        final loadedState = state;
        if (loadedState is ProfileLoaded) {
          emit(loadedState.copyWith(isLoadingPosts: false));
        }
        // Don't emit global error - just set posts error in state (for paging, we don't change to error state)
        // For pagination errors, we just stop loading - the user can refresh if needed
      }
    }
  }

  void _onLoadFollowingInfo(LoadFollowingInfoEvent event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is ProfileLoaded && !currentState.isOwnProfile) {
      try {
        final followingInfo = await _repository.fetchFollowingInfo(
          profileId: event.profileId,
          currentUserId: event.currentUserId,
        );

        emit(currentState.copyWith(followingInfo: followingInfo));
      } catch (e) {
        // Don't emit error for following info - it's optional data
      }
    }
  }

  void _onLoadFollowingInfoWithFollowers(LoadFollowingInfoWithFollowersEvent event, Emitter<ProfileState> emit) async {
    debugPrint('ProfileBloc: _onLoadFollowingInfoWithFollowers called for profileId=${event.profileId}, currentUserId=${event.currentUserId}');
    
    // Get current state snapshot
    final currentStateSnapshot = state;
    if (currentStateSnapshot is! ProfileLoaded || currentStateSnapshot.isOwnProfile) {
      debugPrint('ProfileBloc: Not loading following info - isLoaded=${currentStateSnapshot is ProfileLoaded}, isOwnProfile=${currentStateSnapshot is ProfileLoaded ? currentStateSnapshot.isOwnProfile : 'null'}');
      return;
    }

    // Get username from current state to load following info
    final username = currentStateSnapshot.profile.username;
    final isOwnProfile = currentStateSnapshot.isOwnProfile;
    
    // Use the sequential loading method to ensure data consistency
    await _loadFollowingInfoSequentially(event.profileId, username, isOwnProfile, emit);
  }

  Future<void> _onLikeProfilePost(LikeProfilePostEvent event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    // Prevent concurrent likes for the same post
    if (currentState.processingLikes.contains(event.postId)) {
      return;
    }

    final post = event.post;
    final processingLikes = {...currentState.processingLikes, event.postId};
    emit(currentState.copyWith(processingLikes: processingLikes));

    try {
      // Optimistic update
      final optimisticPost = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );

      List<Post> optimisticPosts = currentState.posts.map((p) => p.id == event.postId ? optimisticPost : p).toList();
      Post? optimisticPinnedPost = currentState.pinnedPost?.id == event.postId ? optimisticPost : currentState.pinnedPost;

      emit(currentState.copyWith(
        posts: optimisticPosts,
        pinnedPost: optimisticPinnedPost,
      ));

      // API call using shared LikePostUseCase
      final serverPost = await _likePostUseCase(event.postId);

      // Server response takes precedence
      final serverUpdatedPost = post.copyWith(
        isLiked: serverPost.isLiked,
        likesCount: serverPost.likesCount,
        dislikesCount: serverPost.dislikesCount,
      );

      final serverPosts = currentState.posts.map((p) => p.id == event.postId ? serverUpdatedPost : p).toList();
      final serverPinnedPost = currentState.pinnedPost?.id == event.postId ? serverUpdatedPost : currentState.pinnedPost;

      emit(currentState.copyWith(
        posts: serverPosts,
        pinnedPost: serverPinnedPost,
        processingLikes: currentState.processingLikes.where((id) => id != event.postId).toSet(),
      ));
    } catch (e) {
      // Revert on error and remove from processing
      final revertedPost = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );

      final revertedPosts = currentState.posts.map((p) => p.id == event.postId ? revertedPost : p).toList();
      final revertedPinnedPost = currentState.pinnedPost?.id == event.postId ? revertedPost : currentState.pinnedPost;

      emit(currentState.copyWith(
        posts: revertedPosts,
        pinnedPost: revertedPinnedPost,
        processingLikes: currentState.processingLikes.where((id) => id != event.postId).toSet(),
      ));
    }
  }

  void _onPushProfileStack(PushProfileStackEvent event, Emitter<ProfileState> emit) async {
    debugPrint('ProfileBloc: _onPushProfileStack called with username=${event.username}');
    
    // Prevent rapid repeated pushes for the same username (debounce)
    final now = DateTime.now();
    final lastPush = _lastPushTime[event.username];
    if (lastPush != null && now.difference(lastPush).inMilliseconds < 100) {
      debugPrint('ProfileBloc: Ignoring rapid PushProfileStackEvent for ${event.username} (debounced)');
      return;
    }
    _lastPushTime[event.username] = now;
    
    // Check if already in stack to avoid duplicates
    final existingIndex = _profileStack.indexWhere((entry) => entry.username == event.username);
    if (existingIndex != -1) {
      // Move to existing entry
      final entry = _profileStack.removeAt(existingIndex);
      _profileStack.add(entry);
      
      // Emit current state immediately for smooth transition
      final currentState = entry.state;
      if (currentState is ProfileLoaded) {
        // Validate state for this username
        if (!currentState.isValidForUsername(event.username)) {
          // State is invalid (skeleton or incomplete), reload it
          emit(currentState.copyWith(isRefreshing: true));
          debugPrint('ProfileBloc: Profile in stack is invalid for ${event.username}, will load');
          add(LoadProfileEvent(event.username, forceRefresh: false));
        } else if (currentState.isSkeleton || currentState.profile.id == 0) {
          // Skeleton state - need to load
          emit(currentState.copyWith(isRefreshing: true));
          debugPrint('ProfileBloc: Profile in stack is skeleton, will load');
          add(LoadProfileEvent(event.username, forceRefresh: false));
        } else {
          // Fully loaded profile - just emit it, no need to reload
          emit(currentState);
          debugPrint('ProfileBloc: Profile already fully loaded in stack, emitting as-is (posts=${currentState.posts.length}, followingInfo=${currentState.followingInfo != null})');
          // Update stack entry with current state
          _profileStack.last = ProfileStackEntry(username: event.username, state: currentState);
          
          // Check if posts need to be loaded
          if (currentState.posts.isEmpty && !currentState.postsError && !currentState.isLoadingPosts) {
            debugPrint('ProfileBloc: Profile loaded but posts missing, loading posts...');
            _loadProfilePostsSequentially(
              currentState.profile.id.toString(),
              false,
              emit,
            );
          }
        }
      } else {
        emit(currentState);
        // If it's not ProfileLoaded, try to load it
        if (currentState is! ProfileLoading) {
          add(LoadProfileEvent(event.username, forceRefresh: false));
        }
      }
      
      // Update stack entry with new state after a short delay to allow state to update
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_profileStack.isNotEmpty && _profileStack.last.username == event.username) {
          _profileStack.last = ProfileStackEntry(username: event.username, state: state);
        }
      });
      return;
    }

    // Create skeleton loading state for new profile
    final skeletonState = ProfileLoaded(
      profile: createSkeletonProfile(event.username),
      isOwnProfile: false,
      isSkeleton: true,
    );

    // Push to stack and emit loading state immediately
    _profileStack.add(ProfileStackEntry(username: event.username, state: skeletonState));
    emit(skeletonState);

    // Use LoadProfileEvent to load the actual profile and posts sequentially
    // This reuses the same logic and ensures consistency
    try {
      add(LoadProfileEvent(event.username, forceRefresh: false));
      
      // Update stack entry with loaded state after a short delay to allow state to update
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_profileStack.isNotEmpty && _profileStack.last.username == event.username) {
          _profileStack.last = ProfileStackEntry(username: event.username, state: state);
        }
      });
    } catch (e) {
      debugPrint('ProfileBloc: Error loading profile in _onPushProfileStack - ${e.toString()}');
      // On error, replace skeleton with error state to prevent infinite skeleton
      final errorState = ProfileError('Не удалось загрузить профиль: ${e.toString()}');
      if (_profileStack.isNotEmpty && _profileStack.last.username == event.username) {
        _profileStack.last = ProfileStackEntry(username: event.username, state: errorState);
      } else {
        // If stack was cleared or entry doesn't exist, add error state
        _profileStack.add(ProfileStackEntry(username: event.username, state: errorState));
      }
      emit(errorState);
    }
  }

  void _onPopProfileStack(PopProfileStackEvent event, Emitter<ProfileState> emit) {
    if (_profileStack.isNotEmpty) {
      _profileStack.removeLast();
      // Only emit if stack is not empty after pop
      if (_profileStack.isNotEmpty) {
        final restoredState = _currentState;
        
        // Emit state synchronously to avoid UI flickering
        emit(restoredState);
        
        // Check if restored state is valid and complete
        if (restoredState is ProfileLoaded) {
          final stackEntry = _profileStack.last;
          
          // Validate state for the username in stack
          if (!restoredState.isValidForUsername(stackEntry.username)) {
            debugPrint('ProfileBloc: Restored state is invalid for ${stackEntry.username}, reloading...');
            // State is invalid (skeleton or incomplete), reload it
            add(LoadProfileEvent(stackEntry.username, forceRefresh: false));
            return;
          }
          
          // Check if state needs posts loading
          if (restoredState.posts.isEmpty && !restoredState.postsError && !restoredState.isLoadingPosts && restoredState.profile.id != 0) {
            debugPrint('ProfileBloc: Restored state has no posts, loading posts for profile id=${restoredState.profile.id}...');
            // Posts are missing, load them using profile ID
            _loadProfilePostsSequentially(
              restoredState.profile.id.toString(),
              false,
              emit,
            );
          }
          
          // Check if state needs followingInfo loading (for other profiles only)
          if (!restoredState.isOwnProfile && 
              restoredState.followingInfo == null && 
              restoredState.profile.id != 0 &&
              _currentUserDBId != null) {
            debugPrint('ProfileBloc: Restored state has no followingInfo, loading for profile id=${restoredState.profile.id}...');
            // FollowingInfo is missing, load it
            _loadFollowingInfoSequentially(
              restoredState.profile.id.toString(),
              restoredState.profile.username,
              restoredState.isOwnProfile,
              emit,
            );
          }
        } else if (restoredState is ProfileInitial || restoredState is ProfileLoading) {
          // If state is initial or loading, trigger load
          final stackEntry = _profileStack.last;
          debugPrint('ProfileBloc: Restored state is ${restoredState.runtimeType}, loading profile for ${stackEntry.username}...');
          add(LoadProfileEvent(stackEntry.username, forceRefresh: false));
        }
      } else {
        // Stack is empty, emit initial state
        emit(ProfileInitial());
      }
    }
  }

  void _onRetryProfilePosts(RetryProfilePostsEvent event, Emitter<ProfileState> emit) {
    final currentState = state;
    if (currentState is ProfileLoaded && currentState.postsError) {
      // Reset posts error and retry loading
      emit(currentState.copyWith(postsError: false, postsErrorMessage: null, posts: []));
      add(LoadProfilePostsEvent(currentState.profile.id.toString(), forceRefresh: true));
    }
  }

  /// Helper to create skeleton profile
  UserProfile createSkeletonProfile(String username) {
    return UserProfile(
      id: 0,
      name: username,
      username: username,
      followersCount: 0,
      followingCount: 0,
      friendsCount: 0,
      postsCount: 0,
      photosCount: 0,
      profileColor: null,
      verificationStatus: 'none',
      scam: false,
      accountType: 'user',
      elementConnected: false,
      registrationDate: DateTime.now(),
      interests: const [],
      purchasedUsernames: const [],
      socials: const [],
      connectInfo: const [],
      equippedItems: const [],
    );
  }
}
