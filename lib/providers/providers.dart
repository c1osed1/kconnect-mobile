/// Фабричные методы и провайдеры для всех зависимостей приложения
///
/// Создает и настраивает все сервисы, репозитории, use cases и BLoC состояния.
/// Обеспечивает чистую архитектуру с разделением зависимостей.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../services/api_client/dio_client.dart';
import '../services/data_clear_service.dart';
import '../services/music_service.dart';
import '../services/posts_service.dart';
import '../services/users_service.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/repositories/account_repository_impl.dart';
import '../features/auth/domain/usecases/check_auth_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/register_profile_usecase.dart';
import '../features/auth/presentation/blocs/auth_bloc.dart';
import '../features/feed/domain/usecases/fetch_posts_usecase.dart';
import '../features/feed/data/repositories/feed_repository_impl.dart';
import '../features/feed/presentation/blocs/feed_bloc.dart';
import '../features/music/data/repositories/audio_repository_impl.dart';
import '../features/music/data/repositories/music_repository_impl.dart';
import '../features/music/domain/usecases/play_track_usecase.dart';
import '../features/music/domain/usecases/pause_usecase.dart';
import '../features/music/domain/usecases/seek_usecase.dart';
import '../features/music/domain/usecases/resume_usecase.dart';
import '../features/music/presentation/blocs/playback_bloc.dart';
import '../features/music/presentation/blocs/music_bloc.dart';

import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/usecases/fetch_user_profile_usecase.dart';
import '../features/profile/domain/usecases/fetch_user_posts_usecase.dart';
import '../features/profile/domain/usecases/fetch_pinned_post_usecase.dart';
import '../features/profile/domain/usecases/update_profile_usecase.dart';
import '../features/profile/domain/usecases/follow_user_usecase.dart';
import '../features/profile/presentation/blocs/profile_bloc.dart';
import '../features/messages/data/services/messages_service.dart';
import '../features/messages/data/repositories/messages_repository_impl.dart';
import '../features/messages/domain/usecases/fetch_chats_usecase.dart';
import '../features/messages/presentation/blocs/messages_bloc.dart';
import '../services/messenger_websocket_service.dart';
import '../core/theme/presentation/blocs/theme_bloc.dart';
import '../core/theme/presentation/blocs/theme_event.dart';

// Авторизация
DioClient _createDioClient() => DioClient();
DataClearService _createDataClearService() => const DataClearService();
AuthRepositoryImpl _createAuthRepository() => AuthRepositoryImpl(_createDioClient(), _createDataClearService());
CheckAuthUseCase _createCheckAuthUseCase() => CheckAuthUseCase(_createAuthRepository());
LogoutUseCase _createLogoutUseCase() => LogoutUseCase(_createAuthRepository());
LoginUseCase _createLoginUseCase() => LoginUseCase(_createAuthRepository());
RegisterUseCase _createRegisterUseCase() => RegisterUseCase(_createAuthRepository());
RegisterProfileUseCase _createRegisterProfileUseCase() => RegisterProfileUseCase(_createAuthRepository());
    AuthBloc _createAuthBloc() => AuthBloc(
      _createCheckAuthUseCase(),
      _createLogoutUseCase(),
      _createLoginUseCase(),
      _createRegisterUseCase(),
      _createRegisterProfileUseCase(),
      AccountRepositoryImpl(),
      _createProfileRepository(),
      _createDataClearService(),
      _createDioClient(),
      _createThemeBloc(),
    );

    ThemeBloc _createThemeBloc() => ThemeBloc()..add(LoadThemeEvent());

// Лента
PostsService _createPostsService() => PostsService();
UsersService _createUsersService() => UsersService();
FeedRepositoryImpl _createFeedRepository() => FeedRepositoryImpl(_createPostsService());
UsersRepositoryImpl _createUsersRepository() => UsersRepositoryImpl(_createUsersService());
FetchPostsUseCase _createFetchPostsUseCase() => FetchPostsUseCase(_createFeedRepository());
LikePostUseCase _createLikePostUseCase() => LikePostUseCase(_createFeedRepository());
FetchOnlineUsersUseCase _createFetchOnlineUsersUseCase() => FetchOnlineUsersUseCase(_createUsersRepository());
FetchCommentsUseCase _createFetchCommentsUseCase() => FetchCommentsUseCase(_createFeedRepository());
AddCommentUseCase _createAddCommentUseCase() => AddCommentUseCase(_createFeedRepository());
DeleteCommentUseCase _createDeleteCommentUseCase() => DeleteCommentUseCase(_createFeedRepository());
LikeCommentUseCase _createLikeCommentUseCase() => LikeCommentUseCase(_createFeedRepository());
FeedBloc _createFeedBloc(AuthBloc authBloc) => FeedBloc(
      _createFetchPostsUseCase(),
      _createLikePostUseCase(),
      _createFetchOnlineUsersUseCase(),
      _createFetchCommentsUseCase(),
      _createAddCommentUseCase(),
      _createDeleteCommentUseCase(),
      _createLikeCommentUseCase(),
      authBloc,
    );

// Музыка
MusicService _createMusicService() => MusicService();
AudioRepositoryImpl _createAudioRepository() => AudioRepositoryImpl();
MusicRepositoryImpl _createMusicRepository() => MusicRepositoryImpl(_createMusicService());
PlayTrackUseCase _createPlayTrackUseCase() => PlayTrackUseCase(_createAudioRepository(), _createMusicRepository());
PauseUseCase _createPauseUseCase() => PauseUseCase(_createAudioRepository());
SeekUseCase _createSeekUseCase() => SeekUseCase(_createAudioRepository());
ResumeUseCase _createResumeUseCase() => ResumeUseCase(_createAudioRepository());
PlaybackBloc _createPlaybackBloc() => PlaybackBloc(
      audioRepository: _createAudioRepository(),
      playTrackUseCase: _createPlayTrackUseCase(),
      pauseUseCase: _createPauseUseCase(),
      seekUseCase: _createSeekUseCase(),
      resumeUseCase: _createResumeUseCase(),
    );
MusicBloc _createMusicBloc() => MusicBloc(musicRepository: _createMusicRepository());


// Профиль
ProfileRepositoryImpl _createProfileRepository() => ProfileRepositoryImpl.create();
FetchUserProfileUseCase _createFetchProfileUseCase() => FetchUserProfileUseCase(_createProfileRepository());
UpdateProfileUseCase _createUpdateProfileUseCase() => UpdateProfileUseCase(_createProfileRepository());
FollowUserUseCase _createFollowUserUseCase() => FollowUserUseCase(_createProfileRepository());
FetchUserPostsUseCase _createFetchUserPostsUseCase() => FetchUserPostsUseCase(_createProfileRepository());
FetchPinnedPostUseCase _createFetchPinnedPostUseCase() => FetchPinnedPostUseCase(_createProfileRepository());
ProfileBloc _createProfileBloc(AuthBloc authBloc) => ProfileBloc(
      authBloc: authBloc,
      fetchProfileUseCase: _createFetchProfileUseCase(),
      fetchUserPostsUseCase: _createFetchUserPostsUseCase(),
      fetchPinnedPostUseCase: _createFetchPinnedPostUseCase(),
      updateProfileUseCase: _createUpdateProfileUseCase(),
      followUserUseCase: _createFollowUserUseCase(),
      likePostUseCase: _createLikePostUseCase(),
      repository: _createProfileRepository(),
    );

// Сообщения
MessengerWebSocketService _createWebSocketService(DioClient dioClient) => MessengerWebSocketService(dioClient);
MessagesRepositoryImpl _createMessagesRepository() => MessagesRepositoryImpl(_createMessagesService());
MessagesService _createMessagesService() => MessagesService();
FetchChatsUseCase _createFetchChatsUseCase() => FetchChatsUseCase(_createMessagesRepository());
MessagesBloc _createMessagesBloc(AuthBloc authBloc, DioClient dioClient) => MessagesBloc(
      _createFetchChatsUseCase(),
      authBloc,
      _createMessagesRepository(),
      _createWebSocketService(dioClient),
    );

final List<BlocProvider<dynamic>> blocProviders = [

  BlocProvider<AuthBloc>(
    create: (_) => _createAuthBloc(),
    lazy: false,
  ),

  BlocProvider<PlaybackBloc>(
    create: (_) => _createPlaybackBloc(),
    lazy: false,
  ),
  BlocProvider<MusicBloc>(
    create: (_) => _createMusicBloc(),
    lazy: true,
  ),

  BlocProvider<FeedBloc>(
    create: (context) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      return _createFeedBloc(authBloc);
    },
  ),

  BlocProvider<ProfileBloc>(
    create: (context) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      return _createProfileBloc(authBloc);
    },
    lazy: true,
  ),
  
  BlocProvider<MessagesBloc>(
    create: (context) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      final dioClient = _createDioClient();
      return _createMessagesBloc(authBloc, dioClient);
    },
  ),
];

// Вебсокет
MessengerWebSocketService _createWebSocketServiceProvider() => MessengerWebSocketService(_createDioClient());

final messengerWebSocketServiceProvider = Provider<MessengerWebSocketService>(
  create: (_) => _createWebSocketServiceProvider(),
);
