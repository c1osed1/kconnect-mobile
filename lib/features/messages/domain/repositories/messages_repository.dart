import 'package:kconnect_mobile/features/messages/domain/models/chat.dart';
import 'package:kconnect_mobile/features/messages/domain/models/message.dart';

/// Интерфейс репозитория для операций с сообщениями и чатами
///
/// Определяет контракт для работы с чатами, сообщениями и их состоянием.
/// Обеспечивает доступ к данным мессенджера через стандартизированный интерфейс.
abstract class MessagesRepository {
  /// Получает список чатов пользователя
  ///
  /// Returns: список всех чатов пользователя с последними сообщениями
  Future<List<Chat>> fetchChats();

  /// Создает новый чат с пользователем
  ///
  /// [userId] - ID пользователя для создания чата
  /// [encrypted] - включить шифрование для чата
  /// Returns: ID созданного чата
  Future<int> createChat(int userId, {bool encrypted = false});

  /// Получает сообщения из чата
  ///
  /// [chatId] - ID чата для получения сообщений
  /// Returns: список сообщений из указанного чата
  Future<List<Message>> fetchMessages(int chatId);

  /// Отправляет сообщение в чат
  ///
  /// [chatId] - ID чата для отправки сообщения
  /// [content] - текст сообщения
  /// [messageType] - тип сообщения ('text', 'image', 'video')
  Future<void> sendMessage(int chatId, String content, {String messageType = 'text'});

  /// Отмечает чат как прочитанный
  ///
  /// [chatId] - ID чата для отметки как прочитанного
  /// Returns: количество отмеченных сообщений
  Future<int> markChatAsRead(int chatId);
}
