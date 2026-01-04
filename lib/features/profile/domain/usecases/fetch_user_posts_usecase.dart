import 'package:kconnect_mobile/features/profile/domain/models/profile_posts_response.dart';
import 'package:kconnect_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Use case для получения постов пользователя
///
/// Отвечает за бизнес-логику загрузки постов профиля с пагинацией.
/// Делегирует работу репозиторию и обрабатывает параметры запроса.
class FetchUserPostsUseCase {
  final ProfileRepository _repository;

  FetchUserPostsUseCase(this._repository);

  Future<ProfilePostsResponse> execute({
    required String userId,
    int page = 1,
    int perPage = 10,
  }) async {
    return await _repository.fetchUserPosts(
      userId: userId,
      page: page,
      perPage: perPage,
    );
  }
}
