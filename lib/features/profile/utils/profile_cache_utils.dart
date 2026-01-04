import 'dart:async';
import 'package:flutter/widgets.dart';

/// Миксин для управления кэшем профиля и жизненным циклом приложения
mixin ProfileCacheManager<T extends StatefulWidget> on State<T> {
  DateTime? _lastResumeTime;
  static const Duration _cacheRefreshThreshold = Duration(minutes: 30);

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastResumeTime = DateTime.now();
      onAppResumed();
    }
  }

  /// Вызывается при возобновлении работы приложения, переопределите в реализации
  void onAppResumed() {}

  /// Проверяет, нужно ли обновить кэш на основе временного порога
  Future<bool> shouldRefreshCache(int? postsCount, DateTime? lastCacheTime) async {
    if (postsCount == null || postsCount == 0) return false;

    if (lastCacheTime == null || _lastResumeTime == null) return false;

    final timeSinceAppResume = DateTime.now().difference(_lastResumeTime!);
    return timeSinceAppResume >= _cacheRefreshThreshold;
  }

  /// Вызывается для обновления кэша, переопределите в реализации
  void refreshCache() {}

  void initCacheManager() {
    WidgetsBinding.instance.addObserver(
      AppLifecycleObserver(onResume: () => didChangeAppLifecycleState(AppLifecycleState.resumed))
    );
  }

  void disposeCacheManager() {
    // Очистка будет здесь, если потребуется удаление наблюдателя WidgetsBinding.removeObserver
    // но в этом случае нам не нужно удалять наблюдателя
  }
}

/// Простой наблюдатель для обработки событий жизненного цикла приложения
class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
    super.didChangeAppLifecycleState(state);
  }
}
