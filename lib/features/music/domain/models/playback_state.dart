import 'package:equatable/equatable.dart';
import 'package:kconnect_mobile/features/music/domain/models/track.dart';

/// Статусы воспроизведения музыки
enum PlaybackStatus {
  /// Воспроизведение остановлено
  stopped,

  /// Музыка воспроизводится
  playing,

  /// Воспроизведение на паузе
  paused,

  /// Буферизация контента
  buffering,
}

/// Модель состояния музыкального воспроизведения
///
/// Содержит всю информацию о текущем состоянии плеера:
/// текущий трек, позиция, статус воспроизведения и т.д.
class PlaybackState extends Equatable {
  final Track? currentTrack;
  final Duration position;
  final Duration? duration;
  final PlaybackStatus status;
  final bool isBuffering;
  final String? error;
  final int speed;

  const PlaybackState({
    this.currentTrack,
    this.position = Duration.zero,
    this.duration,
    this.status = PlaybackStatus.stopped,
    this.isBuffering = false,
    this.error,
    this.speed = 1,
  });

  // Factory constructors for common states
  factory PlaybackState.stopped() {
    return const PlaybackState();
  }

  factory PlaybackState.playing(Track track, {Duration position = Duration.zero, Duration? duration}) {
    return PlaybackState(
      currentTrack: track,
      position: position,
      duration: duration,
      status: PlaybackStatus.playing,
    );
  }

  factory PlaybackState.paused(Track track, Duration position, {Duration? duration}) {
    return PlaybackState(
      currentTrack: track,
      position: position,
      duration: duration,
      status: PlaybackStatus.paused,
    );
  }

  factory PlaybackState.buffering(Track track) {
    return PlaybackState(
      currentTrack: track,
      status: PlaybackStatus.buffering,
      isBuffering: true,
    );
  }

  factory PlaybackState.error(Track track, String error) {
    return PlaybackState(
      currentTrack: track,
      status: PlaybackStatus.stopped,
      error: error,
    );
  }

  // Computed properties
  bool get hasTrack => currentTrack != null;
  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isStopped => status == PlaybackStatus.stopped;
  bool get hasError => error != null;

  // Progress calculations
  double get progress {
    if (duration == null || duration!.inSeconds == 0) return 0.0;
    return position.inSeconds / duration!.inSeconds;
  }

  // Copy with method
  PlaybackState copyWith({
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    PlaybackStatus? status,
    bool? isBuffering,
    String? error,
    int? speed,
  }) {
    return PlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      isBuffering: isBuffering ?? this.isBuffering,
      error: error ?? this.error,
      speed: speed ?? this.speed,
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        position,
        duration,
        status,
        isBuffering,
        error,
        speed,
      ];

  @override
  String toString() {
    return 'PlaybackState('
        'track: ${currentTrack?.title ?? 'null'}, '
        'status: $status, '
        'position: ${position.inSeconds}s, '
        'isBuffering: $isBuffering)';
  }
}
