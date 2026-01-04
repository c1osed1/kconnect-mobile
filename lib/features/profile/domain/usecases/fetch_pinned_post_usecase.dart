import '../../../feed/domain/models/post.dart';
import '../repositories/profile_repository.dart';

/// Use case для получения закрепленного поста пользователя
///
/// Отвечает за логику получения закрепленного поста профиля.
/// Возвращает null, если закрепленный пост отсутствует.
class FetchPinnedPostUseCase {
  final ProfileRepository _repository;

  FetchPinnedPostUseCase(this._repository);

  Future<Post?> execute(String username) {
    return _repository.fetchPinnedPost(username);
  }
}
