part of 'playback_bloc.dart';

/// Базовый класс для всех событий воспроизведения музыки
abstract class PlaybackEvent extends Equatable {
  const PlaybackEvent();

  @override
  List<Object?> get props => [];
}

class PlaybackInitialized extends PlaybackEvent {
  const PlaybackInitialized();
}

class PlaybackPlayRequested extends PlaybackEvent {
  final Track track;

  const PlaybackPlayRequested(this.track);

  @override
  List<Object?> get props => [track];
}

class PlaybackPauseRequested extends PlaybackEvent {
  const PlaybackPauseRequested();
}

class PlaybackResumeRequested extends PlaybackEvent {
  const PlaybackResumeRequested();
}

class PlaybackStopRequested extends PlaybackEvent {
  const PlaybackStopRequested();
}

class PlaybackSeekRequested extends PlaybackEvent {
  final Duration position;

  const PlaybackSeekRequested(this.position);

  @override
  List<Object?> get props => [position];
}

class PlaybackToggleRequested extends PlaybackEvent {
  const PlaybackToggleRequested();
}

class PlaybackStateUpdated extends PlaybackEvent {
  final PlaybackState newState;

  const PlaybackStateUpdated(this.newState);

  @override
  List<Object?> get props => [newState];
}

class PlaybackQueueChanged extends PlaybackEvent {
  final Track currentTrack;

  const PlaybackQueueChanged(this.currentTrack);

  @override
  List<Object?> get props => [currentTrack];
}
