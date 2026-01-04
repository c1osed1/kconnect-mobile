/// Информация о купленном имени пользователя
///
/// Хранит данные о купленных юзернеймах пользователя.
class PurchasedUsername {
  final int id;
  final String username;
  final int pricePaid;
  final DateTime purchaseDate;
  final bool isActive;

  const PurchasedUsername({
    required this.id,
    required this.username,
    required this.pricePaid,
    required this.purchaseDate,
    required this.isActive,
  });

  factory PurchasedUsername.fromJson(Map<String, dynamic> json) {
    return PurchasedUsername(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      pricePaid: json['price_paid'] ?? 0,
      purchaseDate: DateTime.parse(json['purchase_date'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'price_paid': pricePaid,
      'purchase_date': purchaseDate.toIso8601String(),
      'is_active': isActive,
    };
  }
}
