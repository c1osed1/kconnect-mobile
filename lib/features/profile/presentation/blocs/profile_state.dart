import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/models/profile_posts_response.dart';
import '../../domain/models/following_info.dart';
import '../../../feed/domain/models/post.dart';

/// Базовый класс состояний ProfileBloc
///
/// Определяет общий интерфейс для всех состояний профиля.
/// Все состояния наследуются от этого абстрактного класса.
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final UserStats? stats;
  final bool isOwnProfile;
  final List<Post> posts;
  final bool hasNextPosts;
  final bool isLoadingPosts;
  final int currentPostsPage;
  final int postsPerPage;
  final Post? pinnedPost;
  final FollowingInfo? followingInfo;
  final bool isSkeleton;
  final bool postsError;
  final String? postsErrorMessage;
  final bool isRefreshing;

  // Processing states for likes
  final Set<int> processingLikes;

  const ProfileLoaded({
    required this.profile,
    this.stats,
    this.isOwnProfile = false,
    this.posts = const [],
    this.hasNextPosts = true,
    this.isLoadingPosts = false,
    this.currentPostsPage = 1,
    this.postsPerPage = 10,
    this.pinnedPost,
    this.followingInfo,
    this.isSkeleton = false,
    this.postsError = false,
    this.postsErrorMessage,
    this.isRefreshing = false,
    this.processingLikes = const {},
  });

  @override
  List<Object?> get props => [
        profile,
        stats,
        isOwnProfile,
        posts,
        hasNextPosts,
        isLoadingPosts,
        currentPostsPage,
        postsPerPage,
        pinnedPost,
        followingInfo,
        isSkeleton,
        postsError,
        postsErrorMessage,
        isRefreshing,
        processingLikes,
      ];

  ProfileLoaded copyWith({
    UserProfile? profile,
    UserStats? stats,
    bool? isOwnProfile,
    List<Post>? posts,
    bool? hasNextPosts,
    bool? isLoadingPosts,
    int? currentPostsPage,
    int? postsPerPage,
    Post? pinnedPost,
    FollowingInfo? followingInfo,
    bool? isSkeleton,
    bool? postsError,
    String? postsErrorMessage,
    bool? isRefreshing,
    Set<int>? processingLikes,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      isOwnProfile: isOwnProfile ?? this.isOwnProfile,
      posts: posts ?? this.posts,
      hasNextPosts: hasNextPosts ?? this.hasNextPosts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      currentPostsPage: currentPostsPage ?? this.currentPostsPage,
      postsPerPage: postsPerPage ?? this.postsPerPage,
      pinnedPost: pinnedPost ?? this.pinnedPost,
      followingInfo: followingInfo ?? this.followingInfo,
      isSkeleton: isSkeleton ?? this.isSkeleton,
      postsError: postsError ?? this.postsError,
      postsErrorMessage: postsErrorMessage ?? this.postsErrorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      processingLikes: processingLikes ?? this.processingLikes,
    );
  }

  ProfileLoaded addPosts(ProfilePostsResponse response) {
    return copyWith(
      posts: [...posts, ...response.posts],
      hasNextPosts: response.hasNext,
      currentPostsPage: response.page,
    );
  }

  ProfileLoaded setPosts(ProfilePostsResponse response) {
    return copyWith(
      posts: response.posts,
      hasNextPosts: response.hasNext,
      currentPostsPage: response.page,
    );
  }

  /// Check if this state is valid for the given username
  /// Returns true if the profile matches and has complete data
  bool isValidForUsername(String username) {
    // Check if profile username matches
    if (profile.username != username && username != 'current') {
      return false;
    }
    
    // Check if state is skeleton (incomplete)
    if (isSkeleton) {
      return false;
    }
    
    // Check if profile has valid ID (not placeholder)
    if (profile.id == 0) {
      return false;
    }
    
    return true;
  }

  /// Check if state has complete data (profile loaded, posts may be empty but state is valid)
  bool get hasCompleteData {
    return !isSkeleton && profile.id != 0;
  }
}

class ProfileUpdating extends ProfileState {
  final UserProfile currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileUpdated extends ProfileState {
  final UserProfile profile;
  final String message;

  const ProfileUpdated(this.profile, [this.message = 'Профиль обновлен']);

  @override
  List<Object?> get props => [profile, message];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileStatsLoaded extends ProfileState {
  final UserStats stats;

  const ProfileStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// Stack entry for profile navigation
class ProfileStackEntry {
  final String username;
  final ProfileState state;

  const ProfileStackEntry({
    required this.username,
    required this.state,
  });
}

class ProfileFollowSuccess extends ProfileState {
  final String message;
  final bool isFollowing;

  const ProfileFollowSuccess(this.message, this.isFollowing);

  @override
  List<Object?> get props => [message, isFollowing];
}

// Helper extension for state checking
extension ProfileStateExtensions on ProfileState {
  bool get isLoading => this is ProfileLoading;
  bool get isLoaded => this is ProfileLoaded;
  bool get isError => this is ProfileError;
  bool get isUpdating => this is ProfileUpdating;
  bool get isUpdated => this is ProfileUpdated;

  ProfileLoaded? get asLoaded => this is ProfileLoaded ? this as ProfileLoaded : null;
  ProfileError? get asError => this is ProfileError ? this as ProfileError : null;
  ProfileUpdated? get asUpdated => this is ProfileUpdated ? this as ProfileUpdated : null;
}
