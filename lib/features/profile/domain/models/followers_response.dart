/// Ответ API с информацией о подписчиках пользователя
///
/// Содержит список подписчиков с пагинацией и информацией о каждом подписчике.
class FollowersResponse {
  final List<FollowerUser> followers;
  final bool hasNext;
  final bool hasPrev;
  final int page;
  final int pages;
  final int perPage;
  final int total;

  const FollowersResponse({
    required this.followers,
    required this.hasNext,
    required this.hasPrev,
    required this.page,
    required this.pages,
    required this.perPage,
    required this.total,
  });

  factory FollowersResponse.fromJson(Map<String, dynamic> json) {
    final followersList = json['followers'] as List<dynamic>? ?? [];
    final followers = followersList.map((e) => FollowerUser.fromJson(e as Map<String, dynamic>)).toList();

    return FollowersResponse(
      followers: followers,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers': followers.map((e) => e.toJson()).toList(),
      'has_next': hasNext,
      'has_prev': hasPrev,
      'page': page,
      'pages': pages,
      'per_page': perPage,
      'total': total,
    };
  }
}

class FollowerUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final Map<String, dynamic>? achievement;
  final bool isFollowing;
  final bool isFriend;
  final Map<String, dynamic>? verification;

  const FollowerUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.achievement,
    required this.isFollowing,
    required this.isFriend,
    this.verification,
  });

  factory FollowerUser.fromJson(Map<String, dynamic> json) {
    return FollowerUser(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      achievement: json['achievement'] as Map<String, dynamic>?,
      isFollowing: json['is_following'] ?? false,
      isFriend: json['is_friend'] ?? false,
      verification: json['verification'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatar_url': avatarUrl,
      'achievement': achievement,
      'is_following': isFollowing,
      'is_friend': isFriend,
      'verification': verification,
    };
  }
}
