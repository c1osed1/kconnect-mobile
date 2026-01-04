import 'package:flutter/cupertino.dart';
import '../../../routes/route_names.dart';

/// Утилитарный класс для обработки навигации по профилям с кастомными переходами
abstract class ProfileNavigationUtils {
  /// Навигация к профилю с использованием именованного маршрута
  static void navigateToProfile(BuildContext context, String username) {
    Navigator.of(context).pushNamed(
      RouteNames.profile,
      arguments: username,
    );
  }

  /// Обертка для навигации по профилю, которая может быть передана как void callback
  static void Function()? createProfileNavigationCallback(
    BuildContext context,
    String? username,
  ) {
    if (username == null || username.isEmpty) return null;

    return () => navigateToProfile(context, username);
  }

  /// Навигация с hero-анимацией для аватаров профиля
  static void navigateToProfileWithHero({
    required BuildContext context,
    required String username,
    required String heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SizedBox(); // Placeholder
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Навигация с модальным нижним листом для предварительного просмотра профиля
  static void showProfileModal(BuildContext context, String username) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Профиль: $username',
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            CupertinoButton.filled(
              onPressed: () => navigateToProfile(context, username),
              child: const Text('Посмотреть полный профиль'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
