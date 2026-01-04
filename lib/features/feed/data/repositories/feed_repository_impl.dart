/// Реализация репозитория данных для системы ленты новостей
///
/// Предоставляет унифицированный интерфейс для работы с данными постов,
/// комментариев и онлайн-пользователей. Делегирует выполнение операций
/// сервисам PostsService и UsersService. Реализует паттерн Repository
/// для абстракции работы с внешними источниками данных.
library;

import '../../../../../services/posts_service.dart';
import '../../../../../services/users_service.dart';
import '../../domain/models/post.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/feed_repository.dart';

/// Реализация репозитория ленты новостей
///
/// Содержит бизнес-логику для работы с постами, комментариями и пользователями.
/// Преобразует данные из внешних сервисов в объекты доменной модели.
class FeedRepositoryImpl implements FeedRepository {
  /// Сервис для работы с API постов
  final PostsService _postsService;

  /// Конструктор репозитория постов
  ///
  /// [postsService] - сервис для выполнения операций с постами
  FeedRepositoryImpl(this._postsService);

  /// Получает список постов с пагинацией
  ///
  /// Выполняет запрос к API для получения постов указанной страницы.
  /// Преобразует полученные данные в объекты Post.
  ///
  /// [page] - номер страницы для загрузки (по умолчанию 1)
  /// Returns: Список объектов Post
  /// Throws: Exception при ошибке загрузки постов
  @override
  Future<List<Post>> fetchPosts({int page = 1}) async {
    try {
      final data = await _postsService.fetchPosts(page: page);
      final postsData = List<Map<String, dynamic>>.from(data['posts'] ?? []);
      return postsData.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Не удалось загрузить посты: $e');
    }
  }

  /// Ставит лайк на пост
  ///
  /// Отправляет запрос на сервер для изменения статуса лайка поста.
  /// Возвращает обновленный объект Post с актуальными счетчиками.
  ///
  /// [postId] - ID поста для лайка
  /// Returns: Обновленный объект Post
  /// Throws: Exception при ошибке установки лайка
  @override
  Future<Post> likePost(int postId) async {
    try {
      final data = await _postsService.likePost(postId);
      return Post.fromJson(data);
    } catch (e) {
      throw Exception('Не удалось поставить лайк на пост: $e');
    }
  }

  /// Получает комментарии к посту
  ///
  /// Загружает комментарии для указанного поста с поддержкой пагинации.
  /// Преобразует данные в объекты Comment.
  ///
  /// [postId] - ID поста, комментарии которого нужно получить
  /// [page] - номер страницы комментариев (по умолчанию 1)
  /// Returns: Список объектов Comment
  /// Throws: Exception при ошибке загрузки комментариев
  @override
  Future<List<Comment>> fetchComments(int postId, {int page = 1}) async {
    try {
      final data = await _postsService.fetchComments(postId, page: page);
      final commentsData = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      return commentsData.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Не удалось загрузить комментарии: $e');
    }
  }

  /// Добавляет новый комментарий к посту
  ///
  /// Отправляет запрос на создание нового комментария.
  /// Возвращает созданный объект Comment.
  ///
  /// [postId] - ID поста, к которому добавляется комментарий
  /// [content] - текст комментария
  /// Returns: Созданный объект Comment
  /// Throws: Exception при ошибке добавления комментария
  @override
  Future<Comment> addComment(int postId, String content) async {
    try {
      final data = await _postsService.addComment(postId, content);
      return Comment.fromJson(data['comment'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Не удалось добавить комментарий: $e');
    }
  }

  /// Удаляет комментарий
  ///
  /// Отправляет запрос на удаление комментария по его ID.
  ///
  /// [commentId] - ID комментария для удаления
  /// Throws: Exception при ошибке удаления комментария
  @override
  Future<void> deleteComment(int commentId) async {
    try {
      await _postsService.deleteComment(commentId);
    } catch (e) {
      throw Exception('Не удалось удалить комментарий: $e');
    }
  }

  /// Ставит лайк на комментарий
  ///
  /// Отправляет запрос на установку лайка комментарию.
  ///
  /// [commentId] - ID комментария для лайка
  /// Throws: Exception при ошибке установки лайка
  @override
  Future<void> likeComment(int commentId) async {
    try {
      await _postsService.likeComment(commentId);
    } catch (e) {
      throw Exception('Не удалось поставить лайк на комментарий: $e');
    }
  }

  /// Убирает лайк с комментария
  ///
  /// Отправляет запрос на снятие лайка с комментария.
  ///
  /// [commentId] - ID комментария для снятия лайка
  /// Throws: Exception при ошибке снятия лайка
  @override
  Future<void> unlikeComment(int commentId) async {
    try {
      await _postsService.unlikeComment(commentId);
    } catch (e) {
      throw Exception('Не удалось убрать лайк с комментария: $e');
    }
  }

}

/// Реализация репозитория пользователей
///
/// Предоставляет доступ к данным пользователей, включая список онлайн-пользователей.
/// Делегирует выполнение операций сервису UsersService.
class UsersRepositoryImpl implements UsersRepository {
  /// Сервис для работы с API пользователей
  final UsersService _usersService;

  /// Конструктор репозитория пользователей
  ///
  /// [usersService] - сервис для выполнения операций с пользователями
  UsersRepositoryImpl(this._usersService);

  /// Получает список онлайн-пользователей
  ///
  /// Выполняет запрос к API для получения списка пользователей,
  /// которые находятся в сети в данный момент.
  ///
  /// Returns: Список данных онлайн-пользователей в формате Map
  /// Throws: Exception при ошибке загрузки пользователей
  @override
  Future<List<Map<String, dynamic>>> fetchOnlineUsers() async {
    try {
      final data = await _usersService.fetchOnlineUsers();
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Не удалось загрузить онлайн-пользователей: $e');
    }
  }
}
