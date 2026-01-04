/// Модель данных комментария
///
/// Представляет комментарий к посту с поддержкой вложенных ответов.
/// Содержит информацию об авторе, содержимом и взаимодействиях пользователей.
class Comment {
  /// Уникальный идентификатор комментария
  final int id;

  /// Текст комментария
  final String content;

  /// Идентификатор автора комментария
  final int userId;

  /// Отображаемое имя автора
  final String userName;

  /// Реальный username автора из объекта пользователя
  final String username;

  /// URL аватара автора
  final String userAvatar;

  /// Время создания комментария (timestamp)
  final int createdAt;

  /// Количество лайков комментария
  final int likesCount;

  /// Флаг, поставил ли текущий пользователь лайк
  final bool userLiked;

  /// Список вложенных ответов на комментарий
  final List<Comment> replies;

  /// URL изображения, прикрепленного к комментарию (опционально)
  final String? image;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    required this.username,
    required this.userAvatar,
    required this.createdAt,
    required this.likesCount,
    required this.userLiked,
    this.replies = const [],
    this.image,
  });

  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return timestamp;
    } else if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return dateTime.millisecondsSinceEpoch;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    final repliesData = json['replies'] as List<dynamic>? ?? [];
    final replies = repliesData.map((replyJson) => Comment.fromJson(replyJson)).toList();

    return Comment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      userId: json['user_id'] ?? json['user']?['id'] ?? 0,
      userName: json['user_name'] ?? json['user']?['name'] ?? json['user']?['username'] ?? 'Unknown',
      username: json['username'] ?? json['user']?['username'] ?? 'Unknown',
      userAvatar: json['user_avatar'] ?? json['user']?['avatar_url'] ?? json['user']?['photo'] ?? '',
      createdAt: _parseTimestamp(json['timestamp'] ?? json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      userLiked: json['user_liked'] ?? false,
      replies: replies,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt,
      'likes_count': likesCount,
      'user_liked': userLiked,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'image': image,
    };
  }

  Comment copyWith({
    int? id,
    String? content,
    int? userId,
    String? userName,
    String? username,
    String? userAvatar,
    int? createdAt,
    int? likesCount,
    bool? userLiked,
    List<Comment>? replies,
    String? image,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      userLiked: userLiked ?? this.userLiked,
      replies: replies ?? this.replies,
      image: image ?? this.image,
    );
  }
}
