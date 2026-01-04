import '../../../../core/utils/boolean_utils.dart';

/// Информация о связи между пользователями
///
/// Хранит данные о типе связи, статусе, взаимности и дате соединения.
class ConnectionInfo {
  final String username;
  final String type;
  final String status;
  final bool isMutual;
  final DateTime connectionDate;
  final int days;

  const ConnectionInfo({
    required this.username,
    required this.type,
    required this.status,
    required this.isMutual,
    required this.connectionDate,
    required this.days,
  });

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      username: json['username'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      isMutual: BooleanUtils.toBool(json['is_mutual']),
      connectionDate: DateTime.parse(json['connection_date'] ?? DateTime.now().toIso8601String()),
      days: json['days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'type': type,
      'status': status,
      'is_mutual': isMutual,
      'connection_date': connectionDate.toIso8601String(),
      'days': days,
    };
  }
}
