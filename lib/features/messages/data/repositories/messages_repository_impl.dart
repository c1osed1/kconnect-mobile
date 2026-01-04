import '../../domain/models/chat.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../services/messages_service.dart';

/// Реализация репозитория сообщений
///
/// Предоставляет унифицированный интерфейс для работы с данными сообщений.
/// Делегирует выполнение операций сервису MessagesService.
/// Реализует паттерн Repository для абстракции работы с данными.
class MessagesRepositoryImpl implements MessagesRepository {
  final MessagesService _messagesService;

  /// Конструктор репозитория сообщений
  ///
  /// [messagesService] - сервис для работы с API сообщений
  MessagesRepositoryImpl(this._messagesService);

  /// Получает список чатов пользователя
  ///
  /// Делегирует вызов сервису MessagesService для получения чатов
  @override
  Future<List<Chat>> fetchChats() async {
    return await _messagesService.fetchChats();
  }

  /// Создает новый персональный чат
  ///
  /// Делегирует вызов сервису для создания чата с указанным пользователем
  @override
  Future<int> createChat(int userId, {bool encrypted = false}) async {
    return await _messagesService.createChat(userId, encrypted: encrypted);
  }

  /// Получает сообщения чата
  ///
  /// Делегирует вызов сервису для получения всех сообщений указанного чата
  @override
  Future<List<Message>> fetchMessages(int chatId) async {
    return await _messagesService.fetchMessages(chatId);
  }

  /// Отправляет сообщение в чат
  ///
  /// Делегирует вызов сервису для отправки сообщения в указанный чат
  @override
  Future<void> sendMessage(int chatId, String content, {String messageType = 'text'}) async {
    return await _messagesService.sendMessage(chatId, content, messageType: messageType);
  }

  /// Отмечает чат как прочитанный
  ///
  /// Делегирует вызов сервису для отметки всех сообщений чата как прочитанные
  @override
  Future<int> markChatAsRead(int chatId) async {
    return await _messagesService.markChatAsRead(chatId);
  }
}
