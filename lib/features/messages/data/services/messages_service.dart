/// Сервис для работы с API системы сообщений
///
/// Предоставляет методы для взаимодействия с сервером сообщений:
/// получение чатов, сообщений, создание чатов, отправка сообщений.
/// Обрабатывает сетевые запросы и преобразование данных.
library;

import 'package:dio/dio.dart';
import '../../../../services/api_client/dio_client.dart';
import '../../domain/models/chat.dart';
import '../../domain/models/message.dart';

/// Сервис API для системы сообщений
class MessagesService {
  final DioClient _client = DioClient();

  /// Получает список чатов пользователя
  ///
  /// Выполняет GET запрос к API для получения всех чатов текущего пользователя.
  /// Преобразует полученные данные в объекты Chat.
  ///
  /// Returns: Список объектов Chat
  /// Throws: Exception при ошибке сети или сервера
  Future<List<Chat>> fetchChats() async {
    try {
      final res = await _client.get('/apiMes/messenger/chats');

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final chatsData = List<Map<String, dynamic>>.from(data['chats'] ?? []);
        return chatsData.map((chatJson) => Chat.fromJson(chatJson)).toList();
      } else {
        throw Exception('Не удалось загрузить чаты: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Не удалось загрузить чаты: ${e.response?.statusCode ?? 'Ошибка сети'}');
    } catch (e) {
      rethrow;
    }
  }

  /// Создает новый персональный чат с пользователем
  ///
  /// Выполняет POST запрос для создания нового чата с указанным пользователем.
  /// Поддерживает опцию шифрования чата.
  ///
  /// [userId] - ID пользователя, с которым нужно создать чат
  /// [encrypted] - флаг шифрования чата (по умолчанию false)
  /// Returns: ID созданного чата
  /// Throws: Exception при ошибке создания чата
  Future<int> createChat(int userId, {bool encrypted = false}) async {
    try {
      final res = await _client.post('/apiMes/messenger/chats/personal', {
        'user_id': userId,
        'encrypted': encrypted,
      });

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['chat_id'] as int;
        } else {
          throw Exception('Не удалось создать чат: ${data['message'] ?? 'Неизвестная ошибка'}');
        }
      } else {
        throw Exception('Не удалось создать чат: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Не удалось создать чат: ${e.response?.statusCode ?? 'Ошибка сети'}');
    } catch (e) {
      rethrow;
    }
  }

  /// Получает список сообщений чата
  ///
  /// Выполняет GET запрос для получения всех сообщений указанного чата.
  /// Сортирует сообщения по времени создания (новые первыми).
  ///
  /// [chatId] - ID чата, сообщения которого нужно получить
  /// Returns: Список объектов Message, отсортированный по времени (новые первыми)
  /// Throws: Exception при ошибке сети или сервера
  Future<List<Message>> fetchMessages(int chatId) async {
    try {
      final res = await _client.get('/apiMes/messenger/chats/$chatId/messages');

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final messagesData = List<Map<String, dynamic>>.from(data['messages'] ?? []);
        final messages = messagesData.map((messageJson) => Message.fromJson(messageJson)).toList();

        // Сортировка сообщений по времени создания (новые первыми)
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return messages;
      } else {
        throw Exception('Не удалось загрузить сообщения: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Не удалось загрузить сообщения: ${e.response?.statusCode ?? 'Ошибка сети'}');
    } catch (e) {
      rethrow;
    }
  }

  /// Отправляет сообщение в чат
  ///
  /// Выполняет POST запрос для отправки нового сообщения в указанный чат.
  /// Поддерживает различные типы сообщений (текст, изображения и т.д.).
  ///
  /// [chatId] - ID чата, в который отправляется сообщение
  /// [content] - содержимое сообщения
  /// [messageType] - тип сообщения ('text', 'image' и т.д.)
  /// Throws: Exception при ошибке отправки сообщения
  Future<void> sendMessage(int chatId, String content, {String messageType = 'text'}) async {
    try {
      final res = await _client.post('/apiMes/messenger/chats/$chatId/messages', {
        'content': content,
        'message_type': messageType,
      });

      if (res.statusCode != 200) {
        throw Exception('Не удалось отправить сообщение: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Не удалось отправить сообщение: ${e.response?.statusCode ?? 'Ошибка сети'}');
    } catch (e) {
      rethrow;
    }
  }

  /// Отмечает все сообщения чата как прочитанные
  ///
  /// Выполняет POST запрос для отметки всех сообщений в чате как прочитанные.
  /// Возвращает количество отмеченных сообщений.
  ///
  /// [chatId] - ID чата, сообщения которого нужно отметить как прочитанные
  /// Returns: Количество отмеченных сообщений
  /// Throws: Exception при ошибке отметки сообщений
  Future<int> markChatAsRead(int chatId) async {
    try {
      final res = await _client.post('/apiMes/messenger/chats/$chatId/read-all', {});

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['marked_count'] as int? ?? 0;
        } else {
          throw Exception('Не удалось отметить чат как прочитанный: ${data['message'] ?? 'Неизвестная ошибка'}');
        }
      } else {
        throw Exception('Не удалось отметить чат как прочитанный: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Не удалось отметить чат как прочитанный: ${e.response?.statusCode ?? 'Ошибка сети'}');
    } catch (e) {
      rethrow;
    }
  }
}
