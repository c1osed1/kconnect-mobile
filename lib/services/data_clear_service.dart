/// Сервис для очистки кэшированных данных пользователя
///
/// Управляет очисткой всех пользовательских данных из BLoC состояний при выходе.
/// Гарантирует чистое состояние приложения для нового пользователя.
library;

import '../injection.dart';
import '../features/feed/presentation/blocs/feed_bloc.dart';
import '../features/feed/presentation/blocs/feed_event.dart';
import '../features/messages/presentation/blocs/messages_bloc.dart';
import '../features/messages/presentation/blocs/messages_event.dart';
import '../features/profile/presentation/blocs/profile_event.dart';
import '../features/profile/presentation/blocs/profile_bloc.dart';
import '../core/utils/cache_utils.dart';
import '../services/storage_service.dart';

/// Сервис очистки пользовательских данных
class DataClearService {
  const DataClearService();

  /// Очищает все кэшированные пользовательские данные из BLoC состояний
  /// Должен вызываться во время процесса выхода из аккаунта
  void clearAllUserData() {
    final feedBloc = locator.get<FeedBloc>();
    final messagesBloc = locator.get<MessagesBloc>();
    final profileBloc = locator.get<ProfileBloc>();

    feedBloc.add(const InitFeedEvent());

    messagesBloc.add(InitMessagesEvent());

    profileBloc.add(ClearProfileCacheEvent());
    CacheUtils.clearImageCache();

    StorageService.clearPersonalizationSettings();
  }

  /// Очищает кэш при переключении аккаунтов (исключая персонализацию)
  /// Должно вызываться во время смены аккаунта
  void clearUserDataForAccountSwitch() {
    final feedBloc = locator.get<FeedBloc>();
    final messagesBloc = locator.get<MessagesBloc>();
    final profileBloc = locator.get<ProfileBloc>();

    feedBloc.add(const InitFeedEvent());

    messagesBloc.add(InitMessagesEvent());

    profileBloc.add(ClearProfileCacheEvent());

    CacheUtils.clearImageCache();
  }
}
