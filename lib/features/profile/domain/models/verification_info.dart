/// Информация о верификации пользователя
///
/// Хранит статус верификации аккаунта и дату верификации.
/// Статус может быть "verified", "pending", "rejected" и т.д.
class VerificationInfo {
  final String status;
  final String date;

  const VerificationInfo({
    required this.status,
    required this.date,
  });

  factory VerificationInfo.fromJson(Map<String, dynamic> json) {
    return VerificationInfo(
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'date': date,
    };
  }
}
