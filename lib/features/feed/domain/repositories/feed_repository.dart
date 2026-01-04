import '../models/post.dart';
import '../models/comment.dart';

/// Интерфейс репозитория для операций с лентой новостей
///
/// Определяет контракт для работы с постами, комментариями и взаимодействием пользователей.
/// Обеспечивает доступ к данным ленты через стандартизированный интерфейс.
abstract class FeedRepository {
  /// Получает список постов для ленты новостей
  ///
  /// [page] - номер страницы для пагинации (начиная с 1)
  /// Returns: список постов для указанной страницы
  Future<List<Post>> fetchPosts({int page = 1});

  /// Ставит или убирает лайк с поста
  ///
  /// [postId] - идентификатор поста
  /// Returns: обновленный объект поста с новым состоянием лайка
  Future<Post> likePost(int postId);

  /// Получает комментарии к посту
  ///
  /// [postId] - идентификатор поста
  /// [page] - номер страницы для пагинации комментариев
  /// Returns: список комментариев к посту
  Future<List<Comment>> fetchComments(int postId, {int page = 1});

  /// Добавляет новый комментарий к посту
  ///
  /// [postId] - идентификатор поста
  /// [content] - текст комментария
  /// Returns: созданный объект комментария
  Future<Comment> addComment(int postId, String content);

  /// Удаляет комментарий
  ///
  /// [commentId] - идентификатор комментария для удаления
  Future<void> deleteComment(int commentId);

  /// Ставит лайк на комментарий
  ///
  /// [commentId] - идентификатор комментария
  Future<void> likeComment(int commentId);

  /// Убирает лайк с комментария
  ///
  /// [commentId] - идентификатор комментария
  Future<void> unlikeComment(int commentId);
}

/// Интерфейс репозитория для операций с пользователями
///
/// Предоставляет доступ к данным пользователей, таким как онлайн статус.
abstract class UsersRepository {
  /// Получает список онлайн пользователей
  ///
  /// Returns: список пользователей с информацией об их онлайн статусе
  Future<List<Map<String, dynamic>>> fetchOnlineUsers();
}
