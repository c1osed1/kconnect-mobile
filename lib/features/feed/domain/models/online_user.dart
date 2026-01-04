/// Модель онлайн-пользователя
///
/// Представляет пользователя, который находится в сети.
/// Содержит основную информацию для отображения в списке онлайн-пользователей.
class OnlineUser {
  final int id;
  final String name;
  final String username;
  final String avatar;

  const OnlineUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
  });

  factory OnlineUser.fromJson(Map<String, dynamic> json) {
    return OnlineUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      username: json['username'] ?? '',
      avatar: json['avatar_url'] ?? json['photo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatar_url': avatar,
    };
  }
}
