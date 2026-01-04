import 'package:flutter/material.dart';
import 'package:kconnect_mobile/features/profile/domain/models/user_profile.dart';
import 'package:kconnect_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Use case для получения профиля пользователя
///
/// Загружает профиль пользователя по его идентификатору (ID или username).
/// Поддерживает принудительное обновление данных с сервера.
class FetchUserProfileUseCase {
  final ProfileRepository _repository;

  FetchUserProfileUseCase(this._repository);

  /// Выполняет загрузку профиля пользователя
  ///
  /// [userIdentifier] - ID или username пользователя
  /// [forceRefresh] - принудительно обновить данные с сервера (игнорируя кэш)
  /// Returns: объект UserProfile с полной информацией о профиле
  Future<UserProfile> execute(String userIdentifier, {bool forceRefresh = false}) {
    debugPrint('FetchUserProfileUseCase: execute called with userIdentifier=$userIdentifier, forceRefresh=$forceRefresh');
    return _repository.fetchUserProfile(userIdentifier, forceRefresh: forceRefresh).then((profile) {
      debugPrint('FetchUserProfileUseCase: profile loaded successfully - id=${profile.id}, username=${profile.username}, name=${profile.name}');
      return profile;
    }).catchError((e) {
      debugPrint('FetchUserProfileUseCase: error fetching profile - $e');
      throw e;
    });
  }
}
