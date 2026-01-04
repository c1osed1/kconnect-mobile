/// Сервис для работы с профилями через API
///
/// Предоставляет методы для загрузки и обновления профилей пользователей.
/// Управляет всеми операциями с профилями: чтение, запись, подписки.
/// Поддерживает загрузку файлов (аватары, баннеры).
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import '../../../../services/api_client/dio_client.dart';
import '../../../../services/api_client/interceptors/auth_interceptor.dart';
import '../../../../services/api_client/interceptors/logging_interceptor.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/models/profile_posts_response.dart';
import '../../domain/models/following_info.dart';
import '../../../feed/domain/models/post.dart';

/// Сервис для работы с API профилей
///
/// Реализует все сетевые операции с профилями пользователей:
/// загрузка данных, обновление информации, управление подписками.
/// Поддерживает повторные попытки и обработку ошибок.
class ProfileService {
  final DioClient _client = DioClient();

  // Separate Dio instance for FormData requests
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

  ProfileService() {
    // Apply same interceptors to the form data dio
    _formDataDio.interceptors.add(CookieManager(CookieJar()));
    _formDataDio.interceptors.add(LoggingInterceptor());
    _formDataDio.interceptors.add(AuthInterceptor(DioClient()));
  }

  // Profile fetching methods

  Future<UserProfile> fetchUserProfile(String userIdentifier) async {
    final response = await _client.get('/api/profile/$userIdentifier');

    if (response.statusCode == 200) {
      return UserProfile.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<UserProfile> fetchCurrentUserProfile() async {
    try {
      // Get basic current user data
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
      return profile;

    } catch (e) {
      rethrow;
    }
  }

  Future<String?> fetchCurrentUserProfileColor() async {
    try {
      // Get basic current user data to get username
      final currentResponse = await _client.get('/api/profile/current');

      if (currentResponse.statusCode != 200) {
        return null;
      }

      final currentJson = currentResponse.data;
      if (currentJson['success'] != true || currentJson['user'] == null) {
        return null;
      }

      final basicUser = currentJson['user'];
      final username = basicUser['username'];

      // Get profile data to extract profile_color
      final profileResponse = await _client.get('/api/profile/$username');

      if (profileResponse.statusCode != 200) {
        return null;
      }

      final profileJson = profileResponse.data;
      if (profileJson['user'] != null && profileJson['user']['profile_color'] != null) {
        return profileJson['user']['profile_color'].toString();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserStats> fetchUserStats(String userIdentifier) async {
    try {
      final response = await _client.get('/api/profile/$userIdentifier/stats');

      if (response.statusCode == 200) {
        final stats = UserStats.fromJson(response.data);
        return stats;
      } else {
        throw Exception('Failed to fetch user stats');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Profile editing methods

  Future<void> updateProfileName(String name) async {
    final response = await _client.post(
      '/api/profile/name',
      {'name': name},
      headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update name');
    }
  }

  Future<void> updateProfileUsername(String username) async {
    final response = await _client.post(
      '/api/profile/username',
      {'username': username},
      headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update username');
    }
  }

  Future<void> updateProfileAbout(String about) async {
    final response = await _client.post(
      '/api/profile/about',
      {'about': about},
      headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update about');
    }
  }

  Future<void> updateProfileAvatar(String avatarPath) async {
    final file = File(avatarPath);
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        avatarPath,
        filename: file.path.split('/').last,
      ),
    });

    // Use form data Dio client
    final response = await _formDataDio.post(
      '/api/profile/avatar',
      data: formData,
      options: Options(
        headers: {
          'Origin': 'https://k-connect.ru',
          'Referer': 'https://k-connect.ru/',
        },
        extra: {'withCredentials': true}
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update avatar');
    }
  }

  Future<void> deleteProfileAvatar() async {
    final response = await _client.post('/api/profile/avatar/delete', null);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete avatar');
    }
  }

  Future<void> updateProfileBanner(String bannerPath) async {
    final file = File(bannerPath);
    final formData = FormData.fromMap({
      'banner': await MultipartFile.fromFile(
        bannerPath,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _formDataDio.post(
      '/api/profile/banner',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update banner');
    }
  }

  Future<void> deleteProfileBanner() async {
    final response = await _client.post('/api/profile/banner/delete', null);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete banner');
    }
  }

  Future<void> updateProfileBackground(String backgroundPath) async {
    final file = File(backgroundPath);
    final formData = FormData.fromMap({
      'background': await MultipartFile.fromFile(
        backgroundPath,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _client.postFormData('/api/profile/background', formData);

    if (response.statusCode != 200) {
      throw Exception('Failed to update background');
    }
  }

  Future<void> deleteProfileBackground() async {
    final response = await _client.post('/api/profile/background/delete', null);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete background');
    }
  }

  Future<void> updateProfileStatus(String statusText, String statusColor, {bool isChannel = false}) async {
    final response = await _client.post(
      '/api/profile/status/v2',
      {
        'status_text': statusText,
        'status_color': statusColor,
        'is_channel': isChannel,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<void> addSocialLink(String name, String link) async {
    final response = await _client.post(
      '/api/profile/social',
      {
        'name': name,
        'link': link,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add social link');
    }
  }

  Future<void> deleteSocialLink(String name) async {
    final response = await _client.post(
      '/api/profile/social/delete',
      {'name': name},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete social link');
    }
  }

  // Social interactions

  Future<void> followUser(String username) async {
    final response = await _client.post('/api/profile/follow/$username', null);

    if (response.statusCode != 200) {
      throw Exception('Failed to follow user');
    }
  }

  Future<void> unfollowUser(String username) async {
    final response = await _client.post('/api/profile/unfollow/$username', null);

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user');
    }
  }

  Future<void> toggleNotifications(String followedId, bool enabled) async {
    final response = await _client.post(
      '/api/profile/notifications/toggle',
      {'followed_id': int.tryParse(followedId) ?? 0},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle notifications');
    }
  }

  Future<Post?> fetchPinnedPost(String username) async {
    try {
      // Получаем аутентификационные headers как в PostsService
      final authHeaders = await _client.getAuthHeaders();

      final response = await _client.get(
        '/api/profile/pinned_post/$username',
        headers: {
          'Origin': 'https://k-connect.ru',
          'Referer': 'https://k-connect.ru/',
          ...authHeaders, // Добавляем Authorization и Cookie
        },
      );

      if (response.statusCode == 200) {
        final json = response.data;
        if (json.containsKey('post') && json['post'] != null) {
          final postData = json['post'] as Map<String, dynamic>;
          return Post.fromJson(postData);
        } else {
          return null; // No pinned post
        }
      } else {
        return null; // Assume no pinned post if error
      }
    } catch (e) {
      return null; // Exceptions typically mean no pinned post
    }
  }

  Future<ProfilePostsResponse> fetchUserPosts({
    required String userId,
    int page = 1,
    int perPage = 10,
    int retryCount = 3,
  }) async {
    Exception? lastError;

    for (int attempt = 0; attempt < retryCount; attempt++) {
      try {
        // Получаем аутентификационные headers как в PostsService
        final authHeaders = await _client.getAuthHeaders();

        final response = await _client.get(
          '/api/profile/$userId/posts',
          queryParameters: {'page': page, 'per_page': perPage},
          headers: {
            'Origin': 'https://k-connect.ru',
            'Referer': 'https://k-connect.ru/',
            ...authHeaders, // Добавляем Authorization и Cookie
          },
        );

        if (response.statusCode == 200) {
          final postsResponse = ProfilePostsResponse.fromJson(response.data);
          return postsResponse;
        } else {
          throw Exception('Failed to fetch user posts: HTTP ${response.statusCode}');
        }
      } catch (e) {
        lastError = e as Exception;
        // Log the error
        debugPrint('❌ ProfileService fetchUserPosts attempt ${attempt + 1}/$retryCount failed: $e');

        // Wait before retry (exponential backoff: 500ms, 1s, 2s)
        if (attempt < retryCount - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
        }
      }
    }

    // All retries failed
    throw lastError ?? Exception('Failed to fetch user posts after $retryCount attempts');
  }

  Future<FollowingInfo?> fetchFollowingInfo({
    required String profileId,
    required String currentUserId,
  }) async {
    
    try {
      final response = await _client.get('/api/profile/$profileId/following');

      if (response.statusCode == 200) {

        final data = response.data;
        if (data is Map<String, dynamic>) {
          final followingList = data['following'] as List?;
          if (followingList != null) {
            // Find current user's relationship in following list
            for (var userData in followingList) {
              final user = userData as Map<String, dynamic>;
              final userId = user['id']?.toString();
              if (userId == currentUserId) {
                return FollowingInfo.fromJson(user);
              }
            }
          }
        }
        // If current user is not in following list, no relationship means isFollowing=false, isFriend=false, followsBack=false
  
        return FollowingInfo(currentUserFollows: false, currentUserIsFriend: false, followsBack: false);
      } else {

        return null;
      }
    } catch (e) {
      return FollowingInfo(currentUserFollows: false, currentUserIsFriend: false, followsBack: false);
    }
  }

  Future<FollowingInfo> fetchFollowingInfoWithFollowers({
    required String profileId,
    required String currentUserId,
  }) async {
    try {
      // Get authentication headers
      final authHeaders = await _client.getAuthHeaders();

      final response = await _client.get(
        '/api/profile/$profileId/follow/status',
        headers: {
          'Origin': 'https://k-connect.ru',
          'Referer': 'https://k-connect.ru/',
          ...authHeaders, // Include authentication headers (Authorization and Cookie)
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return FollowingInfo(
            currentUserFollows: data['is_following'] ?? false,
            currentUserIsFriend: data['is_friend'] ?? false,
            followsBack: data['is_followed_by'] ?? false,
          );
        } else {
          throw Exception('Invalid follow status response');
        }
      } else {
        throw Exception('Failed to fetch follow status');
      }
    } catch (e) {
      // Return default values on error
      return FollowingInfo(
        currentUserFollows: false,
        currentUserIsFriend: false,
        followsBack: false,
      );
    }
  }
}
