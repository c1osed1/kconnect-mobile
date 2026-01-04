import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/blocs/auth_bloc.dart';
import '../services/posts_service.dart';
import '../services/users_service.dart';
import '../features/feed/data/repositories/feed_repository_impl.dart';
import '../features/feed/domain/usecases/fetch_posts_usecase.dart';
import '../features/feed/presentation/blocs/feed_bloc.dart';

/// Провайдеры BLoC для модуля ленты новостей
///
/// Предоставляет фабричные методы для создания всех зависимостей
/// модуля ленты с соблюдением принципов Clean Architecture.
class FeedBlocProviders {
  // Фабричные методы - каждый вызов создает новый экземпляр
  // Нет статических переменных кэширования - чистая архитектура

  /// Создает сервис для работы с постами
  static PostsService createPostsService() {
    return PostsService();
  }

  /// Создает сервис для работы с пользователями
  static UsersService createUsersService() {
    return UsersService();
  }

  /// Создает репозиторий ленты новостей
  static FeedRepositoryImpl createFeedRepository() {
    return FeedRepositoryImpl(createPostsService());
  }

  /// Создает репозиторий пользователей
  static UsersRepositoryImpl createUsersRepository() {
    return UsersRepositoryImpl(createUsersService());
  }

  /// Создает use case для получения постов
  static FetchPostsUseCase createFetchPostsUseCase() {
    return FetchPostsUseCase(createFeedRepository());
  }

  /// Создает use case для установки лайка на пост
  static LikePostUseCase createLikePostUseCase() {
    return LikePostUseCase(createFeedRepository());
  }

  /// Создает use case для получения списка онлайн пользователей
  static FetchOnlineUsersUseCase createFetchOnlineUsersUseCase() {
    return FetchOnlineUsersUseCase(createUsersRepository());
  }

  /// Создает use case для получения комментариев к посту
  static FetchCommentsUseCase createFetchCommentsUseCase() {
    return FetchCommentsUseCase(createFeedRepository());
  }

  /// Создает use case для добавления комментария к посту
  static AddCommentUseCase createAddCommentUseCase() {
    return AddCommentUseCase(createFeedRepository());
  }

  /// Создает use case для удаления комментария
  static DeleteCommentUseCase createDeleteCommentUseCase() {
    return DeleteCommentUseCase(createFeedRepository());
  }

  /// Создает use case для установки лайка на комментарий
  static LikeCommentUseCase createLikeCommentUseCase() {
    return LikeCommentUseCase(createFeedRepository());
  }

  /// Создает основной BLoC для управления лентой новостей
  ///
  /// [authBloc] - BLoC аутентификации для проверки состояния пользователя
  static FeedBloc createFeedBloc(AuthBloc authBloc) {
    return FeedBloc(
      createFetchPostsUseCase(),
      createLikePostUseCase(),
      createFetchOnlineUsersUseCase(),
      createFetchCommentsUseCase(),
      createAddCommentUseCase(),
      createDeleteCommentUseCase(),
      createLikeCommentUseCase(),
      authBloc,
    );
  }

  /// Список провайдеров BLoC для ленты новостей
  static List<BlocProvider> get providers => [
    BlocProvider<FeedBloc>(
      create: (context) {
        final authBloc = BlocProvider.of<AuthBloc>(context);
        return createFeedBloc(authBloc);
      },
    ),
  ];
}
