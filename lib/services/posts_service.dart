/// Сервис для работы с постами через API
///
/// Управляет всеми операциями с постами: загрузка, лайки, комментарии.
/// Поддерживает повторные попытки и обработку ошибок сети.
library;

import 'package:dio/dio.dart';
import 'api_client/dio_client.dart';

/// Сервис API постов
class PostsService {
  /// HTTP клиент для выполнения запросов
  final DioClient _client = DioClient();

  /// Получает список постов ленты новостей
  ///
  /// Выполняет GET запрос к API для получения постов с пагинацией.
  /// Поддерживает сортировку по времени создания и включение всех типов постов.
  Future<Map<String, dynamic>> fetchPosts({int page = 1, int perPage = 20}) async {
    return _retryRequest(() async {
      final queryParams = {
        'page': page,
        'per_page': perPage,
        'sort': 'newest',
        'include_all': 'true',
      };

      final res = await _client.get('/api/posts/feed', queryParameters: queryParams);
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось загрузить посты: ${res.statusCode}');
      }
    });
  }

  /// Ставит лайк на пост
  ///
  /// Отправляет POST запрос для установки лайка на указанный пост.
  /// Включает необходимые заголовки Origin и Referer для корректной работы API.
  Future<Map<String, dynamic>> likePost(int postId) async {
    return _retryRequest(() async {
      final res = await _client.post('/api/posts/$postId/like', null, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось поставить лайк на пост: ${res.statusCode}');
      }
    });
  }

  /// Получает комментарии к посту
  ///
  /// Выполняет GET запрос для получения списка комментариев к указанному посту.
  /// Поддерживает пагинацию для загрузки комментариев порциями.
  Future<Map<String, dynamic>> fetchComments(int postId, {int page = 1, int perPage = 20}) async {
    return _retryRequest(() async {
      final res = await _client.get('/api/posts/$postId/comments', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось загрузить комментарии: ${res.statusCode}');
      }
    });
  }

  /// Добавляет новый комментарий к посту
  ///
  /// Отправляет POST запрос для создания нового комментария.
  /// Включает необходимые заголовки Origin и Referer для корректной работы API.
  Future<Map<String, dynamic>> addComment(int postId, String text) async {
    return _retryRequest(() async {
      final res = await _client.post('/api/posts/$postId/comments', {'content': text}, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось добавить комментарий: ${res.statusCode}');
      }
    });
  }

  /// Удаляет комментарий
  ///
  /// Отправляет DELETE запрос для удаления указанного комментария.
  /// Включает необходимые заголовки Origin и Referer для корректной работы API.
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    return _retryRequest(() async {
      final res = await _client.delete('/api/comments/$commentId', headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось удалить комментарий: ${res.statusCode}');
      }
    });
  }

  /// Ставит лайк на комментарий
  ///
  /// Отправляет POST запрос для установки лайка на указанный комментарий.
  /// Включает необходимые заголовки Origin и Referer для корректной работы API.
  Future<Map<String, dynamic>> likeComment(int commentId) async {
    return _retryRequest(() async {
      final res = await _client.post('/api/comments/$commentId/like', {}, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось поставить лайк на комментарий: ${res.statusCode}');
      }
    });
  }

  /// Убирает лайк с комментария
  ///
  /// Отправляет POST запрос для снятия лайка с указанного комментария.
  /// Включает необходимые заголовки Origin и Referer для корректной работы API.
  Future<Map<String, dynamic>> unlikeComment(int commentId) async {
    return _retryRequest(() async {
      final res = await _client.post('/api/comments/$commentId/unlike', {}, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Не удалось убрать лайк с комментария: ${res.statusCode}');
      }
    });
  }

  /// Выполняет запрос с повторными попытками
  ///
  /// Реализует механизм повторных попыток для сетевых запросов.
  /// При ошибках DioException или других исключениях выполняет повторные попытки
  /// с экспоненциальной задержкой (1, 2, 4 секунды и т.д.).
  Future<T> _retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
    int retries = 0;
    while (retries <= maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        retries++;
        if (retries > maxRetries) {
          throw Exception('Не удалось выполнить запрос после $maxRetries попыток: ${e.response?.statusCode ?? 'Ошибка сети'}');
        }
        final delay = Duration(seconds: 1 << (retries - 1));
        await Future.delayed(delay);
      } catch (e) {
        retries++;
        if (retries > maxRetries) {
          rethrow;
        }
        final delay = Duration(seconds: 1 << (retries - 1));
        await Future.delayed(delay);
      }
    }
    throw Exception('Логика повторных попыток не сработала');
  }
}
