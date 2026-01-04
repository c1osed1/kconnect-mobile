import 'package:get_it/get_it.dart';
import 'core/theme/presentation/blocs/theme_bloc.dart';
import 'core/theme/presentation/blocs/theme_event.dart';
import 'services/api_client/dio_client.dart';
import 'services/data_clear_service.dart';
import 'services/music_service.dart';
import 'services/posts_service.dart';
import 'services/users_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/register_profile_usecase.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/feed/domain/usecases/fetch_posts_usecase.dart';
import 'features/feed/data/repositories/feed_repository_impl.dart';
import 'features/feed/presentation/blocs/feed_bloc.dart';
import 'features/music/data/repositories/audio_repository_impl.dart';
import 'features/music/data/repositories/music_repository_impl.dart';
import 'features/music/domain/usecases/play_track_usecase.dart';
import 'features/music/domain/usecases/pause_usecase.dart';
import 'features/music/domain/usecases/seek_usecase.dart';
import 'features/music/domain/usecases/resume_usecase.dart';
import 'features/music/presentation/blocs/playback_bloc.dart';
import 'features/music/presentation/blocs/queue_bloc.dart';
import 'features/music/presentation/blocs/music_bloc.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/usecases/fetch_user_profile_usecase.dart';
import 'features/profile/domain/usecases/fetch_user_posts_usecase.dart';
import 'features/profile/domain/usecases/fetch_pinned_post_usecase.dart';
import 'features/profile/domain/usecases/update_profile_usecase.dart';
import 'features/profile/domain/usecases/follow_user_usecase.dart';
import 'features/profile/presentation/blocs/profile_bloc.dart';
import 'features/messages/data/services/messages_service.dart';
import 'features/messages/data/repositories/messages_repository_impl.dart';
import 'features/messages/domain/usecases/fetch_chats_usecase.dart';
import 'features/messages/presentation/blocs/messages_bloc.dart';
import 'services/messenger_websocket_service.dart';
import 'features/auth/data/repositories/account_repository_impl.dart';
import 'features/auth/presentation/blocs/account_bloc.dart';
import 'features/notifications/data/notifications_remote_data_source.dart';
import 'features/notifications/data/notifications_repository_impl.dart';
import 'features/notifications/domain/notifications_repository.dart';

final GetIt locator = GetIt.instance;

/// Настройка всех зависимостей приложения
///
/// Регистрирует все сервисы, репозитории, use cases и BLoC состояния.
/// Вызывается при запуске приложения для инициализации зависимостей.
void setupLocator() {
  // API Client - HTTP клиент для всех сетевых запросов
  locator.registerLazySingleton<DioClient>(() => DioClient());

  // Services - бизнес-логика и сетевые сервисы
  locator.registerLazySingleton<MusicService>(() => MusicService());
  locator.registerLazySingleton<PostsService>(() => PostsService());
  locator.registerLazySingleton<UsersService>(() => UsersService());
  locator.registerLazySingleton<MessagesService>(() => MessagesService());
  locator.registerLazySingleton<MessengerWebSocketService>(() => MessengerWebSocketService(locator<DioClient>()));
  locator.registerLazySingleton<DataClearService>(() => const DataClearService());
  locator.registerLazySingleton<NotificationsRemoteDataSource>(() => NotificationsRemoteDataSource(locator<DioClient>()));

  // Repositories
  locator.registerLazySingleton<AuthRepositoryImpl>(() => AuthRepositoryImpl(locator<DioClient>(), locator<DataClearService>()));
  locator.registerLazySingleton<AuthRepository>(() => locator<AuthRepositoryImpl>());
  locator.registerLazySingleton<AccountRepositoryImpl>(() => AccountRepositoryImpl());
  locator.registerLazySingleton<FeedRepositoryImpl>(() => FeedRepositoryImpl(locator<PostsService>()));
  locator.registerLazySingleton<UsersRepositoryImpl>(() => UsersRepositoryImpl(locator<UsersService>()));
  locator.registerLazySingleton<AudioRepositoryImpl>(() => AudioRepositoryImpl());
  locator.registerLazySingleton<MusicRepositoryImpl>(() => MusicRepositoryImpl(locator<MusicService>()));
  locator.registerLazySingleton<ProfileRepositoryImpl>(() => ProfileRepositoryImpl.create());
  locator.registerLazySingleton<MessagesRepositoryImpl>(() => MessagesRepositoryImpl(locator<MessagesService>()));
  locator.registerLazySingleton<NotificationsRepositoryImpl>(() => NotificationsRepositoryImpl(locator<NotificationsRemoteDataSource>()));
  locator.registerLazySingleton<NotificationsRepository>(() => locator<NotificationsRepositoryImpl>());



  // Use Cases
  locator.registerFactory<CheckAuthUseCase>(() => CheckAuthUseCase(locator<AuthRepositoryImpl>()));
  locator.registerFactory<LogoutUseCase>(() => LogoutUseCase(locator<AuthRepositoryImpl>()));
  locator.registerFactory<LoginUseCase>(() => LoginUseCase(locator<AuthRepositoryImpl>()));
  locator.registerFactory<RegisterUseCase>(() => RegisterUseCase(locator<AuthRepositoryImpl>()));
  locator.registerFactory<RegisterProfileUseCase>(() => RegisterProfileUseCase(locator<AuthRepositoryImpl>()));
  locator.registerFactory<FetchPostsUseCase>(() => FetchPostsUseCase(locator<FeedRepositoryImpl>()));
  locator.registerFactory<LikePostUseCase>(() => LikePostUseCase(locator<FeedRepositoryImpl>()));
  locator.registerFactory<FetchOnlineUsersUseCase>(() => FetchOnlineUsersUseCase(locator<UsersRepositoryImpl>()));
  locator.registerFactory<FetchCommentsUseCase>(() => FetchCommentsUseCase(locator<FeedRepositoryImpl>()));
  locator.registerFactory<AddCommentUseCase>(() => AddCommentUseCase(locator<FeedRepositoryImpl>()));
  locator.registerFactory<DeleteCommentUseCase>(() => DeleteCommentUseCase(locator<FeedRepositoryImpl>()));
  locator.registerFactory<LikeCommentUseCase>(() => LikeCommentUseCase(locator<FeedRepositoryImpl>()));
  locator.registerFactory<PlayTrackUseCase>(() => PlayTrackUseCase(locator<AudioRepositoryImpl>(), locator<MusicRepositoryImpl>()));
  locator.registerFactory<PauseUseCase>(() => PauseUseCase(locator<AudioRepositoryImpl>()));
  locator.registerFactory<SeekUseCase>(() => SeekUseCase(locator<AudioRepositoryImpl>()));
  locator.registerFactory<ResumeUseCase>(() => ResumeUseCase(locator<AudioRepositoryImpl>()));
  locator.registerFactory<FetchUserProfileUseCase>(() => FetchUserProfileUseCase(locator<ProfileRepositoryImpl>()));
  locator.registerFactory<FetchUserPostsUseCase>(() => FetchUserPostsUseCase(locator<ProfileRepositoryImpl>()));
  locator.registerFactory<FetchPinnedPostUseCase>(() => FetchPinnedPostUseCase(locator<ProfileRepositoryImpl>()));
  locator.registerFactory<UpdateProfileUseCase>(() => UpdateProfileUseCase(locator<ProfileRepositoryImpl>()));
  locator.registerFactory<FollowUserUseCase>(() => FollowUserUseCase(locator<ProfileRepositoryImpl>()));
  locator.registerFactory<FetchChatsUseCase>(() => FetchChatsUseCase(locator<MessagesRepositoryImpl>()));

  // Blocs
  locator.registerLazySingleton<ThemeBloc>(() => ThemeBloc()..add(LoadThemeEvent()));
  locator.registerLazySingleton<AuthBloc>(() => AuthBloc(
        locator<CheckAuthUseCase>(),
        locator<LogoutUseCase>(),
        locator<LoginUseCase>(),
        locator<RegisterUseCase>(),
        locator<RegisterProfileUseCase>(),
        locator<AccountRepositoryImpl>(),
        locator<ProfileRepositoryImpl>(),
        locator<DataClearService>(),
        locator<DioClient>(),
        locator<ThemeBloc>(),
      ));
  locator.registerLazySingleton<AccountBloc>(() => AccountBloc(
        locator<AccountRepositoryImpl>(),
        locator<DataClearService>(),
        locator<DioClient>(),
        locator<ThemeBloc>(),
        locator<LogoutUseCase>(),
      ));
  locator.registerFactory<FeedBloc>(() => FeedBloc(
        locator<FetchPostsUseCase>(),
        locator<LikePostUseCase>(),
        locator<FetchOnlineUsersUseCase>(),
        locator<FetchCommentsUseCase>(),
        locator<AddCommentUseCase>(),
        locator<DeleteCommentUseCase>(),
        locator<LikeCommentUseCase>(),
        locator<AuthBloc>(),
      ));
  locator.registerFactory<PlaybackBloc>(() => PlaybackBloc(
        audioRepository: locator<AudioRepositoryImpl>(),
        playTrackUseCase: locator<PlayTrackUseCase>(),
        pauseUseCase: locator<PauseUseCase>(),
        seekUseCase: locator<SeekUseCase>(),
        resumeUseCase: locator<ResumeUseCase>(),
      ));
  locator.registerFactory<QueueBloc>(() => QueueBloc(musicRepository: locator<MusicRepositoryImpl>()));
  locator.registerFactory<MusicBloc>(() => MusicBloc(musicRepository: locator<MusicRepositoryImpl>()));
  locator.registerFactory<ProfileBloc>(() => ProfileBloc(
        authBloc: locator<AuthBloc>(),
        fetchProfileUseCase: locator<FetchUserProfileUseCase>(),
        fetchUserPostsUseCase: locator<FetchUserPostsUseCase>(),
        fetchPinnedPostUseCase: locator<FetchPinnedPostUseCase>(),
        updateProfileUseCase: locator<UpdateProfileUseCase>(),
        followUserUseCase: locator<FollowUserUseCase>(),
        likePostUseCase: locator<LikePostUseCase>(),
        repository: locator<ProfileRepositoryImpl>(),
      ));
  locator.registerFactory<MessagesBloc>(() => MessagesBloc(
        locator<FetchChatsUseCase>(),
        locator<AuthBloc>(),
        locator<MessagesRepositoryImpl>(),
        MessengerWebSocketService(locator<DioClient>()),
      ));
}
