/// Модель данных информации о подписке пользователя
///
/// Содержит информацию о типе подписки, датах активации и истечения,
/// общей длительности и статусе активности.
class SubscriptionInfo {
  final String type;
  final DateTime subscriptionDate;
  final DateTime expiresAt;
  final double totalDurationMonths;
  final bool active;

  const SubscriptionInfo({
    required this.type,
    required this.subscriptionDate,
    required this.expiresAt,
    required this.totalDurationMonths,
    required this.active,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      type: json['type'] ?? '',
      subscriptionDate: DateTime.parse(json['subscription_date'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
      totalDurationMonths: (json['total_duration_months'] ?? 0).toDouble(),
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'subscription_date': subscriptionDate.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'total_duration_months': totalDurationMonths,
      'active': active,
    };
  }
}
