/// Типы сообщений в чате
enum MessageType {
  /// Текстовое сообщение
  text,

  /// Сообщение с изображением
  image,

  /// Сообщение с видео
  video,
  // другие типы сообщений в будущем
}

/// Статус доставки сообщения
enum MessageDeliveryStatus {
  /// Сообщение отправляется
  sending,

  /// Сообщение отправлено
  sent,

  /// Сообщение доставлено
  delivered,

  /// Сообщение прочитано
  read,

  /// Ошибка отправки сообщения
  failed,
}

/// Модель данных сообщения в чате
///
/// Представляет сообщение со всей необходимой информацией
/// об отправителе, содержимом и статусе доставки.
class Message {
  final int? id;
  final int? senderId;
  final String? senderName;
  final String? senderUsername;
  final MessageType messageType;
  final String content;
  final DateTime createdAt;
  final String? clientMessageId;
  final String? tempId;
  final MessageDeliveryStatus deliveryStatus;
  final String? deviceId;

  const Message({
    this.id,
    this.senderId,
    this.senderName,
    this.senderUsername,
    required this.messageType,
    required this.content,
    required this.createdAt,
    this.clientMessageId,
    this.tempId,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.deviceId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String?,
      senderUsername: json['sender_username'] as String?,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == json['message_type'] as String,
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      clientMessageId: json['clientMessageId'] as String?,
      tempId: json['tempId'] as String?,
      deliveryStatus: MessageDeliveryStatus.values.firstWhere(
        (status) => status.name == json['delivery_status'] as String?,
        orElse: () => MessageDeliveryStatus.sent,
      ),
      deviceId: json['device_id'] as String?,
    );
  }

  factory Message.fromWebSocketMessage(Map<String, dynamic> wsData) {
    return Message(
      id: wsData['messageId'] as int?,
      senderId: null, // Will be set from context
      messageType: MessageType.text, // Default for now
      content: wsData['content'] as String? ?? '',
      createdAt: wsData['timestamp'] != null
          ? DateTime.parse(wsData['timestamp'] as String).toLocal()
          : DateTime.now(),
      clientMessageId: wsData['clientMessageId'] as String?,
      tempId: wsData['tempId'] as String?,
      deliveryStatus: MessageDeliveryStatus.sent,
      deviceId: wsData['device_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'message_type': messageType.name,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'clientMessageId': clientMessageId,
      'tempId': tempId,
      'delivery_status': deliveryStatus.name,
      'device_id': deviceId,
    };
  }

  Message copyWith({
    int? id,
    int? senderId,
    MessageType? messageType,
    String? content,
    DateTime? createdAt,
    String? clientMessageId,
    String? tempId,
    MessageDeliveryStatus? deliveryStatus,
    String? deviceId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      tempId: tempId ?? this.tempId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
