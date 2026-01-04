/// Реализация репозитория аудио с использованием just_audio
///
/// Управляет воспроизведением аудио, состоянием плеера и потоками.
/// Предоставляет унифицированный интерфейс для работы с аудио.
library;

import 'dart:async';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/models/playback_state.dart';
import '../../domain/models/track.dart';
import 'package:just_audio/just_audio.dart';

/// Реализация аудио репозитория
class AudioRepositoryImpl implements AudioRepository {
  final AudioPlayer _audioPlayer;
  final StreamController<PlaybackState> _playbackStateController;
  PlaybackState _currentState;

  AudioRepositoryImpl()
      : _audioPlayer = AudioPlayer(),
        _playbackStateController = StreamController<PlaybackState>.broadcast(),
        _currentState = const PlaybackState() {
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Position stream
    _audioPlayer.positionStream.listen((position) {
      _updateState(
        _currentState.copyWith(position: position),
      );
    });

    // Player state stream (playing, buffering, etc.)
    _audioPlayer.playerStateStream.listen((playerState) {
      PlaybackStatus status;
      bool isBuffering = false;

      switch (playerState.processingState) {
        case ProcessingState.idle:
        case ProcessingState.loading:
          status = PlaybackStatus.stopped;
          break;
        case ProcessingState.buffering:
          status = _audioPlayer.playing ? PlaybackStatus.playing : PlaybackStatus.stopped;
          isBuffering = true;
          break;
        case ProcessingState.ready:
          status = _audioPlayer.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
          break;
        case ProcessingState.completed:
          status = PlaybackStatus.stopped;
          _updateState(_currentState.copyWith(position: Duration.zero));

          // Send track completed event to trigger automatic queue navigation
          // Send a special state to indicate completion
          _playbackStateController.add(_currentState.copyWith(
            status: PlaybackStatus.stopped,
            error: 'COMPLETED', // Special marker for completion
          ));
          break;
      }

      _updateState(
        _currentState.copyWith(
          status: status,
          isBuffering: isBuffering,
          duration: _audioPlayer.duration,
        ),
      );
    });
  }

  void _updateState(PlaybackState newState) {
    _currentState = newState;
    _playbackStateController.add(newState);
  }

  @override
  Stream<PlaybackState> get playbackState => _playbackStateController.stream;

  @override
  PlaybackState get currentState => _currentState;

  @override
  Future<void> playTrack(Track track) async {
    try {
      final audioUrl = _ensureFullUrl(track.filePath);

      // Original order: setUrl -> updateState -> play
      await _audioPlayer.setUrl(audioUrl);

      // Update state with the current track before playing
      _updateState(_currentState.copyWith(currentTrack: track));

      await _audioPlayer.play();
    } catch (e) {
      _updateState(PlaybackState.error(track, e.toString()));
      // Don't rethrow to prevent app crash
    }
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _updateState(const PlaybackState());
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  bool get isPlaying => _audioPlayer.playing;

  @override
  bool get isBuffering => _currentState.isBuffering;

  @override
  Duration get position => _audioPlayer.position;

  @override
  Duration? get duration => _audioPlayer.duration;

  String _ensureFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return 'https://k-connect.ru$url';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playbackStateController.close();
  }
}
