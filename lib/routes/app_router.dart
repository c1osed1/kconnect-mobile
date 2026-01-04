/// Маршрутизатор приложения для навигации между экранами
///
/// Определяет все маршруты приложения и обрабатывает их генерацию.
/// Поддерживает именованные маршруты и передачу аргументов между экранами.
library;

import 'package:flutter/cupertino.dart';
import 'package:kconnect_mobile/bootstrap/splash_screen.dart';
import 'package:kconnect_mobile/features/auth/login_screen.dart';
import 'package:kconnect_mobile/features/auth/register_screen.dart';
import 'package:kconnect_mobile/features/auth/add_account_screen.dart';
import 'package:kconnect_mobile/features/core/main_tabs.dart'; // <--- импортируем
import 'package:kconnect_mobile/features/profile/other_profile_screen.dart';
import 'package:kconnect_mobile/features/personalization/personalization_screen.dart';
import 'package:kconnect_mobile/core/widgets/media_viewer.dart';
import 'package:kconnect_mobile/core/media_item.dart';
import 'route_names.dart';

/// Основной маршрутизатор приложения
class AppRouter {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return CupertinoPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.login:
        return CupertinoPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return CupertinoPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.addAccount:
        debugPrint('AppRouter: Navigating to AddAccountScreen');
        return CupertinoPageRoute(builder: (_) => const AddAccountScreen());
      case RouteNames.mainTabs:
        return CupertinoPageRoute(builder: (_) => const MainTabs());
      case RouteNames.profile:
        final username = settings.arguments as String;
        return CupertinoPageRoute(builder: (_) => OtherProfileScreen(username: username));
      case RouteNames.personalization:
        return CupertinoPageRoute(builder: (_) => const PersonalizationScreen());
      case RouteNames.mediaViewer:
        final args = settings.arguments as Map<String, dynamic>;
        final items = args['items'] as List<MediaItem>;
        final initialIndex = args['initialIndex'] as int? ?? 0;
        return CupertinoPageRoute(
          builder: (_) => MediaViewer(
            items: items,
            initialIndex: initialIndex,
          ),
        );
      default:
        return CupertinoPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
