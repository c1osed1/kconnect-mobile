/// Статистика активности пользователя
///
/// Содержит агрегированные данные о взаимодействиях пользователя с контентом,
/// включая общее количество лайков, постов и дней активности.
/// Используется для отображения статистики в профиле пользователя.
class UserStats {
  /// Общее количество лайков, полученных пользователем
  final int totalLikes;

  /// Общее количество опубликованных постов
  final int postsCount;

  /// Количество дней, существования пользователя
  final int daysActive;

  /// Среднее количество лайков на пост
  final double avgLikesPerPost;

  const UserStats({
    required this.totalLikes,
    required this.postsCount,
    required this.daysActive,
    required this.avgLikesPerPost,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalLikes: json['total_likes'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      daysActive: json['days_active'] ?? 0,
      avgLikesPerPost: (json['avg_likes_per_post'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_likes': totalLikes,
      'posts_count': postsCount,
      'days_active': daysActive,
      'avg_likes_per_post': avgLikesPerPost,
    };
  }
}
