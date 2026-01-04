import 'package:kconnect_mobile/features/messages/domain/models/chat_member.dart';
import 'package:kconnect_mobile/features/messages/domain/models/message.dart';

/// Типы чатов в системе
enum ChatType {
  /// Личный чат между двумя пользователями
  personal,

  /// Групповой чат с несколькими участниками
  group,
}

/// Модель данных чата
///
/// Представляет чат с информацией об участниках, сообщениях и настройках.
/// Поддерживает как личные, так и групповые чаты.
class Chat {
  final int id;
  final ChatType chatType;
  final String title;
  final String? avatar;
  final bool isEncrypted;
  final bool isGroup;
  final Message? lastMessage;
  final List<ChatMember> members;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.chatType,
    required this.title,
    required this.avatar,
    required this.isEncrypted,
    required this.isGroup,
    required this.lastMessage,
    required this.members,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int,
      chatType: ChatType.values.firstWhere(
        (type) => type.name == json['chat_type'] as String,
        orElse: () => ChatType.personal,
      ),
      title: json['title'] as String,
      avatar: () {
        final rawAvatar = json['avatar'] as String?;
        if (rawAvatar != null && rawAvatar.startsWith('/api')) {
          final fullAvatar = 'https://k-connect.ru$rawAvatar';
          return fullAvatar;
        }
        return rawAvatar;
      }(),
      isEncrypted: json['is_encrypted'] == 1,
      isGroup: json['is_group'] == true || json['is_group'] == 1,
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChatMember.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_type': chatType.name,
      'title': title,
      'avatar': avatar,
      'is_encrypted': isEncrypted ? 1 : 0,
      'is_group': isGroup,
      'last_message': lastMessage?.toJson(),
      'members': members.map((e) => e.toJson()).toList(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Chat copyWith({
    int? id,
    ChatType? chatType,
    String? title,
    String? avatar,
    bool? isEncrypted,
    bool? isGroup,
    Message? lastMessage,
    List<ChatMember>? members,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      chatType: chatType ?? this.chatType,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isGroup: isGroup ?? this.isGroup,
      lastMessage: lastMessage ?? this.lastMessage,
      members: members ?? this.members,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
