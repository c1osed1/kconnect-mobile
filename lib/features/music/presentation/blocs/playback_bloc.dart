/// BLoC для управления воспроизведением музыки
///
/// Управляет состоянием аудио-плеера, включая воспроизведение, паузу,
/// перемотку, и интеграцию с очередью воспроизведения.
/// Синхронизируется с AudioRepository для отслеживания состояния.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/play_track_usecase.dart';
import '../../domain/usecases/pause_usecase.dart';
import '../../domain/usecases/seek_usecase.dart';
import '../../domain/usecases/resume_usecase.dart';
import '../../domain/models/playback_state.dart';
import '../../domain/models/track.dart';

part 'playback_event.dart';

/// BLoC класс для управления воспроизведением музыки
///
/// Обрабатывает все операции воспроизведения: начало трека, паузу, возобновление,
/// перемотку, и реагирует на завершение треков для автоматического перехода к следующему.
/// Поддерживает различные режимы воспроизведения и интеграцию с очередью.
class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackState> {
  final AudioRepository _audioRepository;
  final PlayTrackUseCase _playTrackUseCase;
  final PauseUseCase _pauseUseCase;
  final SeekUseCase _seekUseCase;
  final ResumeUseCase _resumeUseCase;

  PlaybackBloc({
    required AudioRepository audioRepository,
    required PlayTrackUseCase playTrackUseCase,
    required PauseUseCase pauseUseCase,
    required SeekUseCase seekUseCase,
    required ResumeUseCase resumeUseCase,
  }) : _audioRepository = audioRepository,
       _playTrackUseCase = playTrackUseCase,
       _pauseUseCase = pauseUseCase,
       _seekUseCase = seekUseCase,
       _resumeUseCase = resumeUseCase,
       super(audioRepository.currentState) {
    on<PlaybackInitialized>(_onInitialized);
    on<PlaybackPlayRequested>(_onPlayRequested);
    on<PlaybackPauseRequested>(_onPauseRequested);
    on<PlaybackResumeRequested>(_onResumeRequested);
    on<PlaybackStopRequested>(_onStopRequested);
    on<PlaybackSeekRequested>(_onSeekRequested);
    on<PlaybackToggleRequested>(_onToggleRequested);
    on<PlaybackStateUpdated>(_onStateUpdated);
    on<PlaybackQueueChanged>(_onQueueChanged);

    _audioRepository.playbackState.listen((audioState) {
      add(PlaybackStateUpdated(audioState));
    });
  }

  /// Обработчик инициализации воспроизведения
  ///
  /// Устанавливает начальное состояние из аудио-репозитория.
  /// Вызывается при первом запуске BLoC.
  void _onInitialized(PlaybackInitialized event, Emitter<PlaybackState> emit) {
    emit(_audioRepository.currentState);
  }

  /// Обработчик запроса на воспроизведение трека
  ///
  /// Начинает воспроизведение указанного трека.
  /// Устанавливает состояние буферизации и обновляет текущий трек.
  /// Обрабатывает ошибки воспроизведения и логирует их.
  void _onPlayRequested(PlaybackPlayRequested event, Emitter<PlaybackState> emit) async {
    developer.log('PlaybackBloc: Play requested for ${event.track.title}', name: 'PLAYBACK');

    try {
      emit(state.copyWith(
        currentTrack: event.track,
        status: PlaybackStatus.buffering,
        error: null,
      ));

      await _playTrackUseCase.call(event.track);
    } catch (e, stackTrace) {
      developer.log('PlaybackBloc: Error during playback', name: 'PLAYBACK', error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        status: PlaybackStatus.stopped,
        error: e.toString(),
      ));
    }
  }

  /// Обработчик запроса на паузу
  ///
  /// Приостанавливает текущее воспроизведение.
  /// Обрабатывает ошибки и обновляет состояние при необходимости.
  void _onPauseRequested(PlaybackPauseRequested event, Emitter<PlaybackState> emit) async {
    try {
      await _pauseUseCase.call();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик запроса на возобновление воспроизведения
  ///
  /// Продолжает воспроизведение после паузы.
  /// Обрабатывает ошибки возобновления.
  void _onResumeRequested(PlaybackResumeRequested event, Emitter<PlaybackState> emit) async {
    try {
        await _resumeUseCase.call();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик запроса на остановку воспроизведения
  ///
  /// Полностью останавливает воспроизведение и очищает текущий трек.
  /// Обрабатывает ошибки остановки.
  void _onStopRequested(PlaybackStopRequested event, Emitter<PlaybackState> emit) async {
    try {
      await _audioRepository.stop();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик запроса на перемотку
  ///
  /// Перематывает воспроизведение на указанную позицию.
  /// Обрабатывает ошибки перемотки.
  void _onSeekRequested(PlaybackSeekRequested event, Emitter<PlaybackState> emit) async {
    try {
      await _seekUseCase.call(event.position);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Обработчик запроса на переключение воспроизведения
  ///
  /// Переключает между воспроизведением и паузой в зависимости от текущего состояния.
  /// Если трек воспроизводится - ставит на паузу, иначе возобновляет.
  void _onToggleRequested(PlaybackToggleRequested event, Emitter<PlaybackState> emit) async {
    final isActuallyPlaying = _audioRepository.isPlaying;
    if (isActuallyPlaying) {
      await _pauseUseCase.call();
    } else if (state.hasTrack) {
      await _resumeUseCase.call();
    }
  }

  /// Обработчик обновления состояния воспроизведения
  ///
  /// Принимает новое состояние от аудио-репозитория.
  /// Логирует завершение треков для отладки.
  void _onStateUpdated(PlaybackStateUpdated event, Emitter<PlaybackState> emit) {
    if (event.newState.error == 'COMPLETED' && event.newState.currentTrack != null) {
      developer.log('PlaybackBloc: Track completed, should trigger next track', name: 'PLAYBACK');
    }

    emit(event.newState);
  }

  /// Обработчик изменения очереди воспроизведения
  ///
  /// Вызывается когда очередь треков изменилась.
  /// Начинает воспроизведение нового текущего трека.
  void _onQueueChanged(PlaybackQueueChanged event, Emitter<PlaybackState> emit) {
    add(PlaybackPlayRequested(event.currentTrack));
  }

  /// Текущее состояние воспроизведения
  PlaybackState get currentPlaybackState => _audioRepository.currentState;

  /// Поток состояний воспроизведения для подписки
  Stream<PlaybackState> get playbackStateStream => _audioRepository.playbackState;

  /// Флаг активного воспроизведения
  bool get isPlaying => _audioRepository.isPlaying;

  /// Флаг состояния буферизации
  bool get isBuffering => _audioRepository.isBuffering;

  /// Текущая позиция воспроизведения
  Duration get position => _audioRepository.position;

  /// Общая продолжительность текущего трека
  Duration? get duration => _audioRepository.duration;

  /// Освобождает ресурсы BLoC
  ///
  /// Вызывается при уничтожении BLoC для корректной очистки ресурсов.
  /// Освобождает ресурсы аудио-репозитория.
  void dispose() {
    _audioRepository.dispose();
  }
}
