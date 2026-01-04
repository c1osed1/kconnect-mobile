import 'package:equatable/equatable.dart';
import '../../domain/models/track.dart';

/// Базовый класс для всех событий управления очередью воспроизведения
abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class QueueInitialized extends QueueEvent {
  const QueueInitialized();
}

class QueuePlayTracksRequested extends QueueEvent {
  final List<Track> tracks;
  final String context;
  final int startIndex;

  const QueuePlayTracksRequested(this.tracks, this.context, {this.startIndex = 0});

  @override
  List<Object?> get props => [tracks, context, startIndex];
}

class QueueNextRequested extends QueueEvent {
  const QueueNextRequested();
}

class QueuePreviousRequested extends QueueEvent {
  const QueuePreviousRequested();
}

class QueueLoadNextPageRequested extends QueueEvent {
  const QueueLoadNextPageRequested();
}

class QueueAddPage extends QueueEvent {
  final List<Track> tracks;
  final int pageNumber;

  const QueueAddPage(this.tracks, this.pageNumber);

  @override
  List<Object?> get props => [tracks, pageNumber];
}

class QueueAddVibeBatch extends QueueEvent {
  final List<Track> tracks;

  const QueueAddVibeBatch(this.tracks);

  @override
  List<Object?> get props => [tracks];
}

class QueueShuffleRequested extends QueueEvent {
  const QueueShuffleRequested();
}

class QueueClearRequested extends QueueEvent {
  const QueueClearRequested();
}

class QueueErrorOccurred extends QueueEvent {
  final String error;

  const QueueErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}
