/// Провайдеры BLoC для системы профилей
///
/// Создает и настраивает все зависимости для работы с профилями пользователей,
/// включая репозитории, use cases и BLoC состояния.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/usecases/fetch_user_profile_usecase.dart';
import '../features/profile/domain/usecases/fetch_user_posts_usecase.dart';
import '../features/profile/domain/usecases/fetch_pinned_post_usecase.dart';
import '../features/profile/domain/usecases/update_profile_usecase.dart';
import '../features/profile/domain/usecases/follow_user_usecase.dart';
import '../features/profile/presentation/blocs/profile_bloc.dart';
import '../features/auth/presentation/blocs/auth_bloc.dart';
import 'feed_bloc_providers.dart';

/// Провайдеры для BLoC системы профилей
class ProfileBlocProviders {

  static ProfileRepositoryImpl createProfileRepository() {
    return ProfileRepositoryImpl.create();
  }

  static FetchUserProfileUseCase createFetchProfileUseCase() {
    return FetchUserProfileUseCase(createProfileRepository());
  }

  static UpdateProfileUseCase createUpdateProfileUseCase() {
    return UpdateProfileUseCase(createProfileRepository());
  }

  static FollowUserUseCase createFollowUserUseCase() {
    return FollowUserUseCase(createProfileRepository());
  }

  static FetchUserPostsUseCase createFetchUserPostsUseCase() {
    return FetchUserPostsUseCase(createProfileRepository());
  }

  static FetchPinnedPostUseCase createFetchPinnedPostUseCase() {
    return FetchPinnedPostUseCase(createProfileRepository());
  }

  static ProfileBloc createProfileBloc(AuthBloc authBloc) {
    return ProfileBloc(
      authBloc: authBloc,
      fetchProfileUseCase: createFetchProfileUseCase(),
      fetchUserPostsUseCase: createFetchUserPostsUseCase(),
      fetchPinnedPostUseCase: createFetchPinnedPostUseCase(),
      updateProfileUseCase: createUpdateProfileUseCase(),
      followUserUseCase: createFollowUserUseCase(),
      likePostUseCase: FeedBlocProviders.createLikePostUseCase(),
      repository: createProfileRepository(),
    );
  }

  static BlocProvider<ProfileBloc> get profileBlocProvider => BlocProvider<ProfileBloc>(
    create: (context) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      return createProfileBloc(authBloc);
    },
    lazy: true,
  );

  static List<BlocProvider> get providers => [
    profileBlocProvider,
  ];
}
