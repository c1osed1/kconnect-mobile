/// Социальная ссылка профиля пользователя
///
/// Представляет ссылку на социальную сеть или внешний ресурс.
/// Используется для отображения ссылок в профиле пользователя.
class SocialLink {
  /// Название социальной сети или платформы (например, "Instagram", "Twitter")
  final String name;

  /// URL ссылки на профиль пользователя в социальной сети
  final String link;

  const SocialLink({
    required this.name,
    required this.link,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      name: json['name'] ?? '',
      link: json['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'link': link,
    };
  }
}
