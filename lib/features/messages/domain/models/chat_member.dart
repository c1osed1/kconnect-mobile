/// Модель участника чата
///
/// Представляет пользователя, участвующего в чате.
/// Содержит информацию о роли, статусе онлайн и типе аккаунта.
class ChatMember {
  final int userId;
  final String role;
  final String name;
  final String? username;
  final String? avatar;
  final bool isOnline;
  final DateTime joinedAt;
  final DateTime lastActive;
  final String accountType;

  const ChatMember({
    required this.userId,
    required this.role,
    required this.name,
    required this.username,
    required this.avatar,
    required this.isOnline,
    required this.joinedAt,
    required this.lastActive,
    required this.accountType,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      userId: json['user_id'] as int,
      role: json['role'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      isOnline: json['is_online'] == 1,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastActive: DateTime.parse(json['last_active'] as String),
      accountType: json['account_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role,
      'name': name,
      'username': username,
      'avatar': avatar,
      'is_online': isOnline ? 1 : 0,
      'joined_at': joinedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'account_type': accountType,
    };
  }
}
