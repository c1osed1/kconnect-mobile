import 'package:kconnect_mobile/features/music/domain/models/playback_state.dart';
import 'package:kconnect_mobile/features/music/domain/models/track.dart';

/// Репозиторий для управления аудио воспроизведением
///
/// Определяет интерфейс для работы с аудио плеером, включая управление
/// воспроизведением, получение состояния и обработку ошибок.
/// Абстрагирует конкретную реализацию аудио движка.
abstract class AudioRepository {
  // Stream of playback state updates
  Stream<PlaybackState> get playbackState;

  // Playback control
  Future<void> playTrack(Track track);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);

  // State getters
  PlaybackState get currentState;
  bool get isPlaying;
  bool get isBuffering;
  Duration get position;
  Duration? get duration;

  // Lifecycle
  void dispose();
}
