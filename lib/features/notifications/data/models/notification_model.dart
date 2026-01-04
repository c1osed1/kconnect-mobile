/// Модели данных для системы уведомлений
///
/// Определяет структуры данных для уведомлений, отправителей,
/// связанных постов и комментариев.
/// Поддерживает различные типы уведомлений с полной информацией.
library;

import 'package:equatable/equatable.dart';

/// Информация об отправителе уведомления
class NotificationSender extends Equatable {
  final int id;
  final String name;
  final String? avatarUrl;

  const NotificationSender({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, avatarUrl];
}

class NotificationPostData extends Equatable {
  final int id;
  final String? title;
  final String? preview;
  final String? text;
  final String? imageUrl;

  const NotificationPostData({
    required this.id,
    this.title,
    this.preview,
    this.text,
    this.imageUrl,
  });

  factory NotificationPostData.fromJson(Map<String, dynamic> json) {
    return NotificationPostData(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString(),
      preview: json['preview']?.toString(),
      text: json['text']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, preview, text, imageUrl];
}

class NotificationCommentData extends Equatable {
  final int id;
  final int postId;
  final String? preview;
  final String? text;
  final String? authorName;
  final String? authorAvatarUrl;

  const NotificationCommentData({
    required this.id,
    required this.postId,
    this.preview,
    this.text,
    this.authorName,
    this.authorAvatarUrl,
  });

  factory NotificationCommentData.fromJson(Map<String, dynamic> json) {
    return NotificationCommentData(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      postId: json['post_id'] is int ? json['post_id'] as int : int.tryParse('${json['post_id']}') ?? 0,
      preview: json['preview']?.toString(),
      text: json['text']?.toString(),
      authorName: json['author']?['name']?.toString(),
      authorAvatarUrl: json['author']?['avatar_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, postId, preview, text, authorName, authorAvatarUrl];
}

class NotificationItem extends Equatable {
  final int id;
  final String contentType;
  final String message;
  final String? link;
  final DateTime createdAt;
  final bool isRead;
  final String type;
  final int? senderId;
  final NotificationSender? senderUser;
  final String? postContent;
  final NotificationPostData? postData;
  final String? commentContent;
  final NotificationCommentData? commentData;

  const NotificationItem({
    required this.id,
    required this.contentType,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.link,
    this.senderId,
    this.senderUser,
    this.postContent,
    this.postData,
    this.commentContent,
    this.commentData,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAtString = json['created_at']?.toString();
    return NotificationItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      contentType: json['content_type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      link: json['link']?.toString(),
      createdAt: createdAtString != null ? DateTime.tryParse(createdAtString)?.toLocal() ?? DateTime.now() : DateTime.now(),
      isRead: json['is_read'] == true,
      type: json['type']?.toString() ?? '',
      senderId: json['sender_id'] is int ? json['sender_id'] as int : int.tryParse('${json['sender_id']}'),
      senderUser: json['sender_user'] is Map<String, dynamic> ? NotificationSender.fromJson(json['sender_user'] as Map<String, dynamic>) : null,
      postContent: json['post_content']?.toString(),
      postData: json['post_data'] is Map<String, dynamic> ? NotificationPostData.fromJson(json['post_data'] as Map<String, dynamic>) : null,
      commentContent: json['comment_content']?.toString(),
      commentData: json['comment_data'] is Map<String, dynamic> ? NotificationCommentData.fromJson(json['comment_data'] as Map<String, dynamic>) : null,
    );
  }

  NotificationItem copyWith({
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      contentType: contentType,
      message: message,
      link: link,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
      senderId: senderId,
      senderUser: senderUser,
      postContent: postContent,
      postData: postData,
      commentContent: commentContent,
      commentData: commentData,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentType,
        message,
        link,
        createdAt,
        isRead,
        type,
        senderId,
        senderUser,
        postContent,
        postData,
        commentContent,
        commentData,
      ];
}

class NotificationsResponse extends Equatable {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool success;

  const NotificationsResponse({
    required this.notifications,
    required this.unreadCount,
    required this.success,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['notifications'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();

    return NotificationsResponse(
      notifications: list,
      unreadCount: json['unread_count'] is int ? json['unread_count'] as int : int.tryParse('${json['unread_count']}') ?? 0,
      success: json['success'] == true,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, success];
}
