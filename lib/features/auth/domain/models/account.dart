/// Модель аккаунта пользователя
///
/// Представляет учетную запись пользователя с информацией для аутентификации.
/// Содержит чувствительные данные (логин, пароль) для автологина.
/// Данные должны храниться в защищенном хранилище и шифроваться.
///
/// ВАЖНО ПО БЕЗОПАСНОСТИ:
/// - Пароли хранятся в открытом виде только для автологина
/// - При хранении данные должны быть зашифрованы
/// - Не логировать чувствительные поля в продакшене
class Account {
  final int index;
  final String id;
  final String username;
  final String? avatarUrl;
  final String? sessionKey;
  final String? login; // Для автологина
  final String? password; // Для автологина
  final DateTime lastLogin;

  Account({
    required this.index,
    required this.id,
    required this.username,
    this.avatarUrl,
    this.sessionKey,
    this.login,
    this.password,
    required this.lastLogin,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      index: json['index'] as int? ?? 1,
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      sessionKey: json['sessionKey'] as String?,
      login: json['login'] as String?, // Для автологина
      password: json['password'] as String?, // Для автологина
      lastLogin: DateTime.parse(json['lastLogin'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'sessionKey': sessionKey,
      'login': login, // Для автологина
      'password': password, // Для автологина
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  Account copyWith({
    int? index,
    String? id,
    String? username,
    String? avatarUrl,
    String? sessionKey,
    String? login,
    String? password,
    DateTime? lastLogin,
  }) {
    return Account(
      index: index ?? this.index,
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sessionKey: sessionKey ?? this.sessionKey,
      login: login ?? this.login,
      password: password ?? this.password,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, username: $username, avatarUrl: $avatarUrl, lastLogin: $lastLogin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
