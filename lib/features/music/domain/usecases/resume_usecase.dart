import 'package:kconnect_mobile/features/music/domain/repositories/audio_repository.dart';

/// Use case для возобновления воспроизведения музыки
///
/// Продолжает воспроизведение текущего трека после паузы.
/// Используется для управления состоянием музыкального плеера.
class ResumeUseCase {
  final AudioRepository _audioRepository;

  ResumeUseCase(this._audioRepository);

  /// Выполняет возобновление воспроизведения
  ///
  /// Продолжает воспроизведение с текущей позиции в треке.
  Future<void> call() async {
    await _audioRepository.resume();
  }
}
