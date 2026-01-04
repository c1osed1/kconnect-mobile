import 'package:kconnect_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Use case для управления подписками на пользователей
///
/// Предоставляет функциональность для подписки, отписки и управления
/// уведомлениями от подписанных пользователей.
class FollowUserUseCase {
  final ProfileRepository _repository;

  FollowUserUseCase(this._repository);

  /// Выполняет подписку на пользователя
  ///
  /// [username] - имя пользователя для подписки
  Future<void> follow(String username) => _repository.followUser(username);

  /// Выполняет отписку от пользователя
  ///
  /// [username] - имя пользователя для отписки
  Future<void> unfollow(String username) => _repository.unfollowUser(username);

  /// Управляет уведомлениями от подписанного пользователя
  ///
  /// [followedUsername] - имя пользователя, от которого управляются уведомления
  /// [enabled] - включить или отключить уведомления
  Future<void> toggleNotifications(String followedUsername, bool enabled) =>
    _repository.toggleNotifications(followedUsername, enabled);
}
