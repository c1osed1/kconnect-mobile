
import 'comment.dart';
import '../../../music/domain/models/track.dart';

/// Модель данных поста в социальной сети
///
/// Представляет пост с текстом, медиа контентом, комментариями и статистикой взаимодействия.
/// Поддерживает обычные посты и репосты (с оригинальным постом).
class Post {
  final int id;
  final String content;
  final int userId;
  final String userName;
  final String userAvatar;
  final int createdAt;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isDisliked;
  final bool isBookmarked;
  final List<String> attachments;
  final List<Comment> comments;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? lastComment;
  final int? viewsCount;
  final List<String>? images;
  final String? image;
  final String? video;
  final String? videoPoster;
  final List<Track>? music;
  final String? type;
  final Post? originalPost;
  final bool isPinned;

  Post({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.likesCount,
    required this.dislikesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isDisliked,
    required this.isBookmarked,
    required this.attachments,
    required this.comments,
    this.user,
    this.lastComment,
    this.viewsCount,
    this.images,
    this.image,
    this.video,
    this.videoPoster,
    this.music,
    this.type,
    this.originalPost,
    this.isPinned = false,
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

  static List<String>? _parseImages(dynamic value) {
    if (value is List<dynamic>) {
      return value.whereType<String>().toList();
    }
    return null;
  }

  static String? _parseStringField(dynamic value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final timestamp = _parseTimestamp(json['timestamp'] ?? json['created_at']);

    final originalPostData = json['original_post'] as Map<String, dynamic>?;
    final originalPost = originalPostData != null ? Post.fromJson(originalPostData) : null;

    List<Track>? music;
    if (json['music'] is List) {
      music = (json['music'] as List).map((trackJson) => Track.fromJson(trackJson)).toList();
    }

    return Post(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'] ?? '',
      createdAt: timestamp,
      likesCount: json['likes_count'] ?? 0,
      dislikesCount: json['dislikes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isDisliked: json['is_disliked'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
      comments: (json['comments'] as List<dynamic>? ?? []).map((e) => Comment.fromJson(e)).toList(),
      user: json['user'] as Map<String, dynamic>?,
      lastComment: json['last_comment'] as Map<String, dynamic>?,
      viewsCount: json['views_count'] as int?,
      images: _parseImages(json['images']),
      image: _parseStringField(json['image']),
      video: _parseStringField(json['video']),
      videoPoster: _parseStringField(json['video_poster']),
      music: music,
      type: json['type'] as String?,
      originalPost: originalPost,
      isPinned: json['is_pinned'] ?? false,
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
      'dislikes_count': dislikesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_disliked': isDisliked,
      'is_bookmarked': isBookmarked,
      'attachments': attachments,
      'comments': comments.map((e) => e.toJson()).toList(),
      'user': user,
      'last_comment': lastComment,
      'views_count': viewsCount,
      'images': images,
      'image': image,
      'video': video,
      'video_poster': videoPoster,
      'music': music?.map((track) => track.toJson()).toList(),
      'type': type,
      'original_post': originalPost?.toJson(),
      'is_pinned': isPinned,
    };
  }

  Post copyWith({
    int? id,
    String? content,
    int? userId,
    String? userName,
    String? userAvatar,
    int? createdAt,
    int? likesCount,
    int? dislikesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isDisliked,
    bool? isBookmarked,
    List<String>? attachments,
    List<Comment>? comments,
    Map<String, dynamic>? user,
    Map<String, dynamic>? lastComment,
    int? viewsCount,
    List<String>? images,
    String? image,
    String? video,
    String? videoPoster,
    List<Track>? music,
    String? type,
    Post? originalPost,
    bool? isPinned,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      user: user ?? this.user,
      lastComment: lastComment ?? this.lastComment,
      viewsCount: viewsCount ?? this.viewsCount,
      images: images ?? this.images,
      image: image ?? this.image,
      video: video ?? this.video,
      videoPoster: videoPoster ?? this.videoPoster,
      music: music ?? this.music,
      type: type ?? this.type,
      originalPost: originalPost ?? this.originalPost,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
