/// Реализация репозитория профиля с кэшированием
///
/// Предоставляет доступ к данным профиля с локальным кэшированием.
/// Управляет загрузкой профилей, статистики, постов и взаимодействиями.
/// Поддерживает кэширование для оптимизации производительности.
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_client/dio_client.dart';
import '../../../../services/api_client/interceptors/auth_interceptor.dart';
import '../../../../services/api_client/interceptors/logging_interceptor.dart';
import '../../data/services/profile_service.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/models/profile_posts_response.dart';
import '../../domain/models/following_info.dart';
import '../../../feed/domain/models/post.dart';

/// Реализация репозитория профиля с кэшированием данных
///
/// Управляет всеми операциями с профилями пользователей: загрузка,
/// обновление, подписки. Включает локальное кэширование для
/// улучшения производительности и оффлайн-доступа.
class ProfileRepositoryImpl implements ProfileRepository {
  final DioClient _client = DioClient();
  late final Dio _formDataDio = Dio(BaseOptions(
    baseUrl: 'https://k-connect.ru',
    headers: {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'Mozilla/5.0 (Flutter)',
    },
    followRedirects: true,
    validateStatus: (status) => status != null && status < 500,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 10),
  ));

  SharedPreferences? _prefs;

  final ProfileService _profileService = ProfileService();

  // Cache keys
  static const String _profileCacheKey = 'profile_cache_';
  static const String _currentProfileCacheKey = 'current_profile_cache';
  static const String _statsCacheKey = 'stats_cache_';
  static const String _postsCacheKey = 'posts_cache_';
  static const String _cacheTimestampKey = 'cache_timestamp_';

  // Cache duration (in minutes)
  static const int _profileCacheDuration = 30; // 30 minutes for profiles
  static const int _statsCacheDuration = 30; // 30 minutes for stats
  static const int _postsCacheDuration = 30; // 30 minutes for posts

  ProfileRepositoryImpl() {
    // Apply same interceptors to the form data dio
    _formDataDio.interceptors.add(CookieManager(CookieJar()));
    _formDataDio.interceptors.add(LoggingInterceptor());
    _formDataDio.interceptors.add(AuthInterceptor(DioClient()));
  }

  factory ProfileRepositoryImpl.create() {
    return ProfileRepositoryImpl();
  }

  // Helper method to get preferences asynchronously
  Future<SharedPreferences> get _getPrefs async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<String?> fetchCurrentUserProfileColor() async {
    return await _profileService.fetchCurrentUserProfileColor();
  }

  @override
  Future<UserProfile> fetchCurrentUserProfile({bool forceRefresh = false}) async {
    final prefs = await _getPrefs;
    final cacheKey = _currentProfileCacheKey;
    final timestampKey = '$_cacheTimestampKey$cacheKey';

    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = _profileCacheDuration * 60 * 1000; // minutes to milliseconds

        if (cacheAge < maxAge) {
          try {
            final data = jsonDecode(cached);
            return UserProfile.fromJson(data);
          } catch (e) {
            // Invalid cache, fetch fresh data
          }
        }
      }
    }

    try {
      final currentResponse = await _client.get('/api/profile/current');

      if (currentResponse.statusCode != 200) {
        throw Exception('Failed to fetch current user');
      }

      final currentJson = currentResponse.data;
      if (currentJson['success'] != true || currentJson['user'] == null) {
        throw Exception('Invalid current user data');
      }

      final basicUser = currentJson['user'];
      final username = basicUser['username'];

      // Get full profile data for the same user
      final fullResponse = await _client.get('/api/profile/$username');

      if (fullResponse.statusCode != 200) {
        throw Exception('Failed to fetch full user profile');
      }

      final fullJson = fullResponse.data;

      // Merge: take fullJson as base, override/add user fields with basicUser (to get is_online etc.)
      final mergedJson = <String, dynamic>{
        ...(fullJson as Map<String, dynamic>),
        'user': <String, dynamic>{
          ...(fullJson['user'] as Map<String, dynamic>),
          ...(basicUser as Map<String, dynamic>),
        }
      };

      final profile = UserProfile.fromJson(mergedJson);

      // Cache the result
      await _cacheData(cacheKey, timestampKey, profile.toJson());

      return profile;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserProfile> fetchUserProfile(String userIdentifier, {bool forceRefresh = false}) async {
    debugPrint('ProfileRepositoryImpl: fetchUserProfile called with userIdentifier=$userIdentifier, forceRefresh=$forceRefresh');

    final prefs = await _getPrefs;
    final cacheKey = '$_profileCacheKey$userIdentifier';
    final timestampKey = '$_cacheTimestampKey$cacheKey';

    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = _profileCacheDuration * 60 * 1000; // minutes to milliseconds

        if (cacheAge < maxAge) {
          debugPrint('ProfileRepositoryImpl: returning cached profile for $userIdentifier');
          try {
            final data = jsonDecode(cached);
            return UserProfile.fromJson(data);
          } catch (e) {
            debugPrint('ProfileRepositoryImpl: invalid cache data for $userIdentifier');
            // Invalid cache, fetch fresh data
          }
        } else {
          debugPrint('ProfileRepositoryImpl: cache expired for $userIdentifier');
        }
      } else {
        debugPrint('ProfileRepositoryImpl: no cache found for $userIdentifier');
      }
    }

    try {
      debugPrint('ProfileRepositoryImpl: fetching profile from service for $userIdentifier');
      final profile = await _profileService.fetchUserProfile(userIdentifier);

      debugPrint('ProfileRepositoryImpl: profile fetched successfully - id=${profile.id}, username=${profile.username}, name=${profile.name}');

      // Cache the result
      await _cacheData(cacheKey, timestampKey, profile.toJson());

      return profile;
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: error fetching profile from service for $userIdentifier - $e');
      // Try to return cached data even if expired
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        debugPrint('ProfileRepositoryImpl: returning expired cache for $userIdentifier');
        try {
          final data = jsonDecode(cached);
          return UserProfile.fromJson(data);
        } catch (e) {
          debugPrint('ProfileRepositoryImpl: invalid expired cache for $userIdentifier');
          // Invalid cache
        }
      }
      rethrow;
    }
  }

  @override
  Future<UserStats> fetchUserStats(String userIdentifier) async {
    final prefs = await _getPrefs;
    final cacheKey = '$_statsCacheKey$userIdentifier';
    final timestampKey = '$_cacheTimestampKey$cacheKey';

    final cached = prefs.getString(cacheKey);
    final timestamp = prefs.getInt(timestampKey);

    if (cached != null && timestamp != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAge = _statsCacheDuration * 60 * 1000;

      if (cacheAge < maxAge) {
        try {
          final data = jsonDecode(cached);
          return UserStats.fromJson(data);
        } catch (e) {
          // Invalid cache
        }
      }
    }

    try {
      final stats = await _profileService.fetchUserStats(userIdentifier);

      // Cache the result
      await _cacheData(cacheKey, timestampKey, stats.toJson());

      return stats;
    } catch (e) {
      // Try to return cached data even if expired
      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          return UserStats.fromJson(data);
        } catch (e) {
          // Invalid cache
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> updateProfileName(String name) async {
    await _profileService.updateProfileName(name);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> updateProfileUsername(String username) async {
    await _profileService.updateProfileUsername(username);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> updateProfileAbout(String about) async {
    await _profileService.updateProfileAbout(about);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> updateProfileAvatar(String avatarPath) async {
    await _profileService.updateProfileAvatar(avatarPath);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> deleteProfileAvatar() async {
    await _profileService.deleteProfileAvatar();
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> updateProfileBanner(String bannerPath) async {
    await _profileService.updateProfileBanner(bannerPath);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> deleteProfileBanner() async {
    await _profileService.deleteProfileBanner();
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> updateProfileBackground(String backgroundPath) async {
    await _profileService.updateProfileBackground(backgroundPath);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> deleteProfileBackground() async {
    await _profileService.deleteProfileBackground();
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> updateProfileStatus(String statusText, String statusColor) async {
    await _profileService.updateProfileStatus(statusText, statusColor);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> addSocialLink(String name, String link) async {
    await _profileService.addSocialLink(name, link);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> deleteSocialLink(String name) async {
    await _profileService.deleteSocialLink(name);
    // Clear current user profile cache
    final prefs = await _getPrefs;
    await prefs.remove(_currentProfileCacheKey);
    await prefs.remove('$_cacheTimestampKey$_currentProfileCacheKey');
  }

  @override
  Future<void> followUser(String username) async {
    await _profileService.followUser(username);
    // Clear profile caches that might be affected
    final prefs = await _getPrefs;
    await prefs.remove('$_profileCacheKey$username');
    await prefs.remove('$_cacheTimestampKey$_profileCacheKey$username');
  }

  @override
  Future<void> unfollowUser(String username) async {
    await _profileService.unfollowUser(username);
    // Clear profile caches that might be affected
    final prefs = await _getPrefs;
    await prefs.remove('$_profileCacheKey$username');
    await prefs.remove('$_cacheTimestampKey$_profileCacheKey$username');
  }

  @override
  Future<void> toggleNotifications(String followedUsername, bool enabled) async {
    await _profileService.toggleNotifications(followedUsername, enabled);
  }

  @override
  Future<Post?> fetchPinnedPost(String username) async {
    try {
      final post = await _profileService.fetchPinnedPost(username);
      return post;
    } catch (e) {
      // Pinned post might not exist or there might be an error
      // Return null to indicate no pinned post
      return null;
    }
  }

  @override
  Future<ProfilePostsResponse> fetchUserPosts({
    required String userId,
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final prefs = await _getPrefs;
    final cacheKey = '$_postsCacheKey${userId}_page$page';
    final timestampKey = '$_cacheTimestampKey$cacheKey';

    final cached = prefs.getString(cacheKey);

    if (!forceRefresh) {
      final timestamp = prefs.getInt(timestampKey);

      if (cached != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = _postsCacheDuration * 60 * 1000;

        if (cacheAge < maxAge) {
          try {
            final data = jsonDecode(cached);
            return ProfilePostsResponse.fromJson(data);
          } catch (e) {
            // Invalid cache
          }
        }
      }
    }

    try {
      final postsResponse = await _profileService.fetchUserPosts(
        userId: userId,
        page: page,
        perPage: perPage,
      );

      // Cache the result
      await _cacheData(cacheKey, timestampKey, postsResponse.toJson());

      return postsResponse;
    } catch (e) {
      // Try to return cached data even if expired
      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          return ProfilePostsResponse.fromJson(data);
        } catch (e) {
          // Invalid cache, throw original error
        }
      }
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  @override
  Future<FollowingInfo?> fetchFollowingInfo({
    required String profileId,
    required String currentUserId,
  }) async {
    try {
      final followingInfo = await _profileService.fetchFollowingInfo(
        profileId: profileId,
        currentUserId: currentUserId,
      );
      return followingInfo;
    } catch (e) {
      // Return null if there's an error fetching following info
      return null;
    }
  }

  @override
  Future<FollowingInfo> fetchFollowingInfoWithFollowers({
    required String profileId,
    required String currentUserId,
  }) async {
    final followingInfo = await _profileService.fetchFollowingInfoWithFollowers(
      profileId: profileId,
      currentUserId: currentUserId,
    );
    return followingInfo;
  }

  @override
  Future<void> clearCache() async {
    final prefs = await _getPrefs;
    final keys = prefs.getKeys();

    // Remove all profile-related cache
    for (final key in keys) {
      if (key.startsWith(_profileCacheKey) ||
          key.startsWith(_currentProfileCacheKey) ||
          key.startsWith(_statsCacheKey) ||
          key.startsWith(_postsCacheKey) ||
          key.startsWith(_cacheTimestampKey)) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<void> clearUserCache(String userIdentifier) async {
    final prefs = await _getPrefs;
    await prefs.remove('$_profileCacheKey$userIdentifier');
    await prefs.remove('$_cacheTimestampKey$_profileCacheKey$userIdentifier');
    await prefs.remove('$_statsCacheKey$userIdentifier');
    await prefs.remove('$_cacheTimestampKey$_statsCacheKey$userIdentifier');

    // Remove all posts cache for this user
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('$_postsCacheKey$userIdentifier') ||
          key.startsWith('$_cacheTimestampKey$_postsCacheKey$userIdentifier')) {
        await prefs.remove(key);
      }
    }
  }

  // Private helper methods

  Future<void> _cacheData(String cacheKey, String timestampKey, Map<String, dynamic> data) async {
    final prefs = await _getPrefs;
    await prefs.setString(cacheKey, jsonEncode(data));
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }
}
