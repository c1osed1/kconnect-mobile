/// Информация об достижениях пользователя
///
/// Хранит данные о значке достижения, изображении, уровне и цвете.
class AchievementInfo {
  final String badge;
  final String imagePath;
  final int upgrade;
  final String colorUpgrade;

  const AchievementInfo({
    required this.badge,
    required this.imagePath,
    required this.upgrade,
    required this.colorUpgrade,
  });

  factory AchievementInfo.fromJson(Map<String, dynamic> json) {
    return AchievementInfo(
      badge: json['bage']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      upgrade: json['upgrade'] is int ? json['upgrade'] : 0,
      colorUpgrade: json['color_upgrade']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bage': badge,
      'image_path': imagePath,
      'upgrade': upgrade,
      'color_upgrade': colorUpgrade,
    };
  }
}
