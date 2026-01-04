import 'package:audio_session/audio_session.dart';

class AppBootstrap {

  static Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }
}
