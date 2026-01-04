import '../repositories/profile_repository.dart';

/// Use case для обновления профиля пользователя
///
/// Предоставляет унифицированный интерфейс для всех операций обновления профиля.
/// Делегирует вызовы методам репозитория с соответствующей логикой.
class UpdateProfileUseCase {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  // Name and basic info
  Future<void> updateName(String name) => _repository.updateProfileName(name);
  Future<void> updateUsername(String username) => _repository.updateProfileUsername(username);
  Future<void> updateAbout(String about) => _repository.updateProfileAbout(about);

  // Media updates
  Future<void> updateAvatar(String avatarPath) => _repository.updateProfileAvatar(avatarPath);
  Future<void> deleteAvatar() => _repository.deleteProfileAvatar();

  Future<void> updateBanner(String bannerPath) => _repository.updateProfileBanner(bannerPath);
  Future<void> deleteBanner() => _repository.deleteProfileBanner();

  Future<void> updateBackground(String backgroundPath) => _repository.updateProfileBackground(backgroundPath);
  Future<void> deleteBackground() => _repository.deleteProfileBackground();

  // Status updates
  Future<void> updateStatus(String statusText, String statusColor) =>
    _repository.updateProfileStatus(statusText, statusColor);

  // Social links
  Future<void> addSocialLink(String name, String link) => _repository.addSocialLink(name, link);
  Future<void> deleteSocialLink(String name) => _repository.deleteSocialLink(name);
}
