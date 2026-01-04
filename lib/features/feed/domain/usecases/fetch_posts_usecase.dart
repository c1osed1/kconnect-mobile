import '../models/post.dart';
import '../models/comment.dart';
import '../repositories/feed_repository.dart';

/// Use case для получения постов ленты новостей
///
/// Загружает посты для отображения в ленте с поддержкой пагинации.
/// Используется для первоначальной загрузки и догрузки контента.
class FetchPostsUseCase {
  final FeedRepository _repository;

  FetchPostsUseCase(this._repository);

  /// Выполняет загрузку постов
  ///
  /// [page] - номер страницы для пагинации
  /// Returns: список постов для указанной страницы
  Future<List<Post>> call({int page = 1}) {
    return _repository.fetchPosts(page: page);
  }
}

/// Use case для установки/снятия лайка с поста
///
/// Управляет взаимодействием пользователя с постами через систему лайков.
/// Автоматически переключает состояние лайка (лайк/анлайк).
class LikePostUseCase {
  final FeedRepository _repository;

  LikePostUseCase(this._repository);

  /// Выполняет операцию лайка поста
  ///
  /// [postId] - идентификатор поста
  /// Returns: обновленный объект поста с новым состоянием лайка
  Future<Post> call(int postId) {
    return _repository.likePost(postId);
  }
}

/// Use case для получения списка онлайн пользователей
///
/// Получает актуальную информацию о пользователях, находящихся онлайн.
/// Используется для отображения списка активных пользователей.
class FetchOnlineUsersUseCase {
  final UsersRepository _repository;

  FetchOnlineUsersUseCase(this._repository);

  /// Выполняет получение списка онлайн пользователей
  ///
  /// Returns: список пользователей с информацией об их статусе
  Future<List<Map<String, dynamic>>> call() {
    return _repository.fetchOnlineUsers();
  }
}

/// Use case для получения комментариев к посту
///
/// Загружает комментарии для конкретного поста с поддержкой пагинации.
/// Используется для отображения дерева комментариев.
class FetchCommentsUseCase {
  final FeedRepository _repository;

  FetchCommentsUseCase(this._repository);

  /// Выполняет загрузку комментариев к посту
  ///
  /// [postId] - идентификатор поста
  /// [page] - номер страницы для пагинации комментариев
  /// Returns: список комментариев к указанному посту
  Future<List<Comment>> call(int postId, {int page = 1}) {
    return _repository.fetchComments(postId, page: page);
  }
}

/// Use case для добавления нового комментария
///
/// Создает новый комментарий к посту от имени текущего пользователя.
/// Валидирует содержимое перед отправкой на сервер.
class AddCommentUseCase {
  final FeedRepository _repository;

  AddCommentUseCase(this._repository);

  /// Выполняет добавление комментария к посту
  ///
  /// [postId] - идентификатор поста
  /// [content] - текст комментария
  /// Returns: созданный объект комментария
  Future<Comment> call(int postId, String content) {
    return _repository.addComment(postId, content);
  }
}

/// Use case для удаления комментария
///
/// Удаляет комментарий пользователя. Доступно только для комментариев
/// самого пользователя или модераторов.
class DeleteCommentUseCase {
  final FeedRepository _repository;

  DeleteCommentUseCase(this._repository);

  /// Выполняет удаление комментария
  ///
  /// [commentId] - идентификатор комментария для удаления
  Future<void> call(int commentId) {
    return _repository.deleteComment(commentId);
  }
}

/// Use case для установки лайка на комментарий
///
/// Добавляет лайк к комментарию от имени текущего пользователя.
/// Используется для оценки качества комментариев.
class LikeCommentUseCase {
  final FeedRepository _repository;

  LikeCommentUseCase(this._repository);

  /// Выполняет установку лайка на комментарий
  ///
  /// [commentId] - идентификатор комментария
  Future<void> call(int commentId) {
    return _repository.likeComment(commentId);
  }
}
