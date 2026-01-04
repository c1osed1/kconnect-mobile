/// Use case для перемотки аудио к определенной позиции
///
/// Отвечает за бизнес-логику изменения позиции воспроизведения.
/// Инкапсулирует вызов метода seek в аудио репозитории.
library;

import '../repositories/audio_repository.dart';

/// Use case для выполнения перемотки аудио
///
/// Принимает желаемую позицию воспроизведения и выполняет перемотку.
/// Возвращает результат операции перемотки.
class SeekUseCase {
  final AudioRepository _audioRepository;

  SeekUseCase(this._audioRepository);

  Future<void> call(Duration position) async {
    await _audioRepository.seek(position);
  }
}
