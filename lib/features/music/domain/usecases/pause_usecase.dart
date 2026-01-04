/// Use case для приостановки воспроизведения музыки
///
/// Отвечает за бизнес-логику приостановки текущего трека.
/// Инкапсулирует вызов метода паузы в аудио репозитории.
library;

import '../repositories/audio_repository.dart';

/// Use case для выполнения паузы воспроизведения
///
/// Выполняет приостановку текущего музыкального трека.
/// Возвращает результат операции приостановки.
class PauseUseCase {
  final AudioRepository _audioRepository;

  PauseUseCase(this._audioRepository);

  Future<void> call() async {
    await _audioRepository.pause();
  }
}
