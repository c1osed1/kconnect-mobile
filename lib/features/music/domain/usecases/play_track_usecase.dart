/// Use case для воспроизведения музыкального трека
///
/// Отвечает за бизнес-логику начала воспроизведения трека.
/// Определяет, нужно ли начать новый трек или возобновить текущий.
/// Инкапсулирует логику выбора действия воспроизведения.
library;

import 'dart:developer' as developer;
import '../repositories/audio_repository.dart';
import '../repositories/music_repository.dart';
import '../models/track.dart';

/// Use case для выполнения воспроизведения трека
///
/// Принимает трек для воспроизведения, определяет текущее состояние плеера
/// и выполняет соответствующее действие: начало нового трека или возобновление.
/// Возвращает результат операции воспроизведения.
class PlayTrackUseCase {
  final AudioRepository _audioRepository;

  PlayTrackUseCase(this._audioRepository, MusicRepository _);

  Future<void> call(Track track) async {
    try {
      final currentState = _audioRepository.currentState;
      final isCurrentlyPlaying = _audioRepository.isPlaying;

      if (currentState.currentTrack?.id == track.id && isCurrentlyPlaying) {
        // Same track already playing - do nothing to avoid restart
        return;
      } else if (currentState.currentTrack?.id == track.id &&
                 currentState.currentTrack != null &&
                 currentState.position.inSeconds > 0) {
        // Resume the currently paused track
        await _audioRepository.resume();
      } else {
        // Start playing a new or different track
        await _audioRepository.playTrack(track);
      }
    } catch (e, stackTrace) {
      developer.log('PlayTrackUseCase: Error playing track ${track.title}', name: 'USECASE', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
