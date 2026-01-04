/// Провайдеры BLoC для музыкальной системы
///
/// Создает и настраивает все зависимости для работы с музыкой,
/// включая репозитории, use cases и BLoC состояния.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/music_service.dart';
import '../features/music/data/repositories/audio_repository_impl.dart';
import '../features/music/data/repositories/music_repository_impl.dart';
import '../features/music/domain/usecases/play_track_usecase.dart';
import '../features/music/domain/usecases/pause_usecase.dart';
import '../features/music/domain/usecases/seek_usecase.dart';
import '../features/music/domain/usecases/resume_usecase.dart';
import '../features/music/presentation/blocs/playback_bloc.dart';
import '../features/music/presentation/blocs/queue_bloc.dart';
import '../features/music/presentation/blocs/music_bloc.dart';

/// Провайдеры для BLoC музыкальной системы
class MusicBlocProviders {

  static MusicService createMusicService() {
    return MusicService();
  }

  static AudioRepositoryImpl createAudioRepository() {
    return AudioRepositoryImpl();
  }

  static MusicRepositoryImpl createMusicRepository() {
    return MusicRepositoryImpl(createMusicService());
  }

  static PlayTrackUseCase createPlayTrackUseCase() {
    return PlayTrackUseCase(createAudioRepository(), createMusicRepository());
  }

  static PauseUseCase createPauseUseCase() {
    return PauseUseCase(createAudioRepository());
  }

  static SeekUseCase createSeekUseCase() {
    return SeekUseCase(createAudioRepository());
  }

  static ResumeUseCase createResumeUseCase() {
    return ResumeUseCase(createAudioRepository());
  }

  static PlaybackBloc createPlaybackBloc() {
    return PlaybackBloc(
      audioRepository: createAudioRepository(),
      playTrackUseCase: createPlayTrackUseCase(),
      pauseUseCase: createPauseUseCase(),
      seekUseCase: createSeekUseCase(),
      resumeUseCase: createResumeUseCase(),
    );
  }

  static QueueBloc createQueueBloc() {
    return QueueBloc(
      musicRepository: createMusicRepository(),
    );
  }

  static MusicBloc createMusicBloc() {
    return MusicBloc(
      musicRepository: createMusicRepository(),
    );
  }

  static List<BlocProvider> get providers => [
    BlocProvider<PlaybackBloc>(
      create: (_) => createPlaybackBloc(),
      lazy: false,
    ),
    BlocProvider<QueueBloc>(
      create: (_) => createQueueBloc(),
      lazy: true,
    ),
    BlocProvider<MusicBloc>(
      create: (_) => createMusicBloc(),
      lazy: true,
    ),
  ];
}
