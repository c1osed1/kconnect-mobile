/// Ответ API с постами профиля пользователя
///
/// Содержит список постов с пагинацией для профиля пользователя.
library;

import 'package:equatable/equatable.dart';
import '../../../feed/domain/models/post.dart';

/// Модель ответа с постами профиля
///
/// Хранит посты пользователя с информацией о пагинации.
class ProfilePostsResponse extends Equatable {
  final bool hasNext;
  final bool hasPrev;
  final int page;
  final int pages;
  final int perPage;
  final List<Post> posts;
  final int total;

  const ProfilePostsResponse({
    required this.hasNext,
    required this.hasPrev,
    required this.page,
    required this.pages,
    required this.perPage,
    required this.posts,
    required this.total,
  });

  factory ProfilePostsResponse.fromJson(Map<String, dynamic> json) {
    return ProfilePostsResponse(
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
      perPage: json['per_page'] ?? 10,
      posts: json['posts'] != null 
          ? List<Map<String, dynamic>>.from(json['posts'])
              .map((postJson) => Post.fromJson(postJson))
              .toList()
          : [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_next': hasNext,
      'has_prev': hasPrev,
      'page': page,
      'pages': pages,
      'per_page': perPage,
      'posts': posts.map((post) => post.toJson()).toList(),
      'total': total,
    };
  }

  @override
  List<Object?> get props => [hasNext, hasPrev, page, pages, perPage, posts, total];
}
