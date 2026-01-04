/// Абстрактный репозиторий для работы с профилями пользователей
///
/// Определяет интерфейс для всех операций с профилями:
/// загрузка, обновление, подписки, управление контентом.
/// Поддерживает кэширование и пагинацию.
library;

import 'package:equatable/equatable.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import '../models/profile_posts_response.dart';
import '../models/following_info.dart';
import '../../../feed/domain/models/post.dart';

/// Параметры пагинации для запросов
class PaginationParams extends Equatable {
  final int page;
  final int perPage;

  const PaginationParams({
    this.page = 1,
    this.perPage = 20,
  });

  @override
  List<Object?> get props => [page, perPage];
}

/// Абстрактный репозиторий профилей
///
/// Определяет контракт для всех операций с профилями пользователей.
/// Включает методы для загрузки данных, обновления профиля,
/// управления подписками и кэшем.
abstract class ProfileRepository {
  // Profile fetching
  Future<UserProfile> fetchUserProfile(String userIdentifier, {bool forceRefresh = false});
  Future<UserProfile> fetchCurrentUserProfile({bool forceRefresh = false});
  Future<String?> fetchCurrentUserProfileColor();
  Future<UserStats> fetchUserStats(String userIdentifier);
  Future<Post?> fetchPinnedPost(String username);
  Future<ProfilePostsResponse> fetchUserPosts({
    required String userId,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  });
  Future<FollowingInfo?> fetchFollowingInfo({
    required String profileId,
    required String currentUserId,
  });
  Future<FollowingInfo> fetchFollowingInfoWithFollowers({
    required String profileId,
    required String currentUserId,
  });

  // Profile editing
  Future<void> updateProfileName(String name);
  Future<void> updateProfileUsername(String username);
  Future<void> updateProfileAbout(String about);
  Future<void> updateProfileAvatar(String avatarPath);
  Future<void> deleteProfileAvatar();
  Future<void> updateProfileBanner(String bannerPath);
  Future<void> deleteProfileBanner();
  Future<void> updateProfileBackground(String backgroundPath);
  Future<void> deleteProfileBackground();
  Future<void> updateProfileStatus(String statusText, String statusColor);
  Future<void> addSocialLink(String name, String link);
  Future<void> deleteSocialLink(String name);

  // Social interactions
  Future<void> followUser(String username);
  Future<void> unfollowUser(String username);
  Future<void> toggleNotifications(String followedUsername, bool enabled);

  // Cache management
  Future<void> clearCache();
  Future<void> clearUserCache(String userIdentifier);
}
