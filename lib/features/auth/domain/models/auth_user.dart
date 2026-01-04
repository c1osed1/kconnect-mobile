/// Модель данных аутентифицированного пользователя
///
/// Содержит основную информацию о пользователе после успешной аутентификации.
/// Используется для отображения данных пользователя в UI и для сессионного управления.
class AuthUser {
  /// Уникальный идентификатор пользователя
  final String id;

  /// Имя пользователя (username)
  final String username;

  /// Email адрес пользователя (может быть null)
  final String? email;

  /// URL аватара пользователя (может быть null)
  final String? avatarUrl;

  AuthUser({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
  });

  /// Создает объект AuthUser из JSON данных от API
  ///
  /// [json] - JSON объект с данными пользователя
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email'],
      avatarUrl: json['photo'],
    );
  }

  /// Преобразует объект AuthUser в JSON для сериализации
  ///
  /// Returns: Map с данными пользователя в формате JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}
