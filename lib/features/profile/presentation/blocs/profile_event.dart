import '../../../feed/domain/models/post.dart';

/// Базовый класс для всех событий профиля
///
/// Определяет интерфейс событий, которые могут быть отправлены в ProfileBloc.
/// Все события наследуются от этого абстрактного класса.
abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {
  final String userIdentifier;
  final bool forceRefresh;

  LoadProfileEvent(this.userIdentifier, {this.forceRefresh = false});
}

class LoadCurrentProfileEvent extends ProfileEvent {
  final bool forceRefresh;

  LoadCurrentProfileEvent({this.forceRefresh = false});
}

class LoadProfileStatsEvent extends ProfileEvent {
  final String userIdentifier;

  LoadProfileStatsEvent(this.userIdentifier);
}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String username;
  final String about;

  UpdateProfileEvent({
    required this.name,
    required this.username,
    required this.about,
  });
}

class UpdateProfileStatusEvent extends ProfileEvent {
  final String statusText;
  final String statusColor;

  UpdateProfileStatusEvent({
    required this.statusText,
    required this.statusColor,
  });
}

class UpdateProfileAvatarEvent extends ProfileEvent {
  final String avatarPath;

  UpdateProfileAvatarEvent(this.avatarPath);
}

class DeleteProfileAvatarEvent extends ProfileEvent {}

class AddSocialLinkEvent extends ProfileEvent {
  final String name;
  final String link;

  AddSocialLinkEvent({required this.name, required this.link});
}

class DeleteSocialLinkEvent extends ProfileEvent {
  final String name;

  DeleteSocialLinkEvent(this.name);
}

class FollowUserEvent extends ProfileEvent {
  final String username;

  FollowUserEvent(this.username);
}

class UnfollowUserEvent extends ProfileEvent {
  final String username;

  UnfollowUserEvent(this.username);
}

class ToggleNotificationsEvent extends ProfileEvent {
  final String followedUsername;
  final bool enabled;

  ToggleNotificationsEvent({
    required this.followedUsername,
    required this.enabled,
  });
}

class RefreshProfileEvent extends ProfileEvent {
  final bool forceRefresh;

  RefreshProfileEvent({this.forceRefresh = true});
}

class ClearProfileCacheEvent extends ProfileEvent {}

class LoadProfilePostsEvent extends ProfileEvent {
  final String userId;
  final bool forceRefresh;

  LoadProfilePostsEvent(this.userId, {this.forceRefresh = true}); // CHANGED: forceRefresh = true by default
}

class FetchMoreProfilePostsEvent extends ProfileEvent {
  final String userId;
  final int page;
  final int perPage;

  FetchMoreProfilePostsEvent({
    required this.userId,
    required this.page,
    required this.perPage,
  });
}

class LoadFollowingInfoEvent extends ProfileEvent {
  final String profileId;
  final String currentUserId;

  LoadFollowingInfoEvent({
    required this.profileId,
    required this.currentUserId,
  });
}

class LoadFollowingInfoWithFollowersEvent extends ProfileEvent {
  final String profileId;
  final String currentUserId;

  LoadFollowingInfoWithFollowersEvent({
    required this.profileId,
    required this.currentUserId,
  });
}

class LikeProfilePostEvent extends ProfileEvent {
  final int postId;
  final Post post;

  LikeProfilePostEvent(this.postId, this.post);

  List<Object?> get props => [postId, post];
}

class RetryProfilePostsEvent extends ProfileEvent {}

/// Push profile to navigation stack
class PushProfileStackEvent extends ProfileEvent {
  final String username;

  PushProfileStackEvent(this.username);

  List<Object?> get props => [username];
}

/// Pop profile from navigation stack
class PopProfileStackEvent extends ProfileEvent {}
