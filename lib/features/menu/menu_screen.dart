/// Экран меню настроек приложения
///
/// Предоставляет доступ к различным настройкам приложения:
/// очистка кеша, персонализация, информация о приложении, выход из аккаунта.
/// Использует Sliver для создания прокручиваемого интерфейса.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../core/utils/cache_utils.dart';
import '../../../routes/route_names.dart';
import '../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../../features/auth/presentation/blocs/auth_event.dart';
import '../../../features/auth/presentation/blocs/auth_state.dart';
import '../../../core/theme/presentation/blocs/theme_bloc.dart';
import '../../../core/theme/presentation/blocs/theme_event.dart';

/// Экран меню с настройками приложения
///
/// Содержит список опций для управления приложением:
/// - Очистка кеша изображений
/// - Персонализация интерфейса
/// - Информация о приложении
/// - Выход из аккаунта
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthUnauthenticated,
      listener: (context, state) => Navigator.pushReplacementNamed(context, RouteNames.login),
      child: SafeArea(
        child: Container(
          color: AppColors.bgDark,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Настройки',
                    style: AppTextStyles.h2,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMenuCard(
                        context,
                        'Очистить кеш изображений',
                        'Удаляет закешированные изображения для освобождения памяти и обновления обложек',
                        CupertinoIcons.trash,
                        AppColors.error,
                        () => _showCacheClearDialog(context),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        'Персонализация',
                        'Настройки персонализации интерфейса приложения',
                        CupertinoIcons.color_filter,
                        context.dynamicPrimaryColor,
                        () => _navigateToPersonalization(context),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        'О приложении',
                        'Версия приложения и информация о разработчике',
                        CupertinoIcons.info_circle,
                        context.dynamicPrimaryColor,
                        () => _showAboutDialog(context),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        'Выйти из аккаунта',
                        'Завершить текущую сессию и вернуться на страницу входа',
                        CupertinoIcons.square_arrow_right_fill,
                        AppColors.error,
                        () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Fill remaining space to ensure full height coverage
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  color: AppColors.bgDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.dynamicPrimaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.button,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showCacheClearDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Очистить кеш'),
        content: const Text(
          'Это удалит все закешированные изображения, включая обложки треков. '
          'Изображения загрузятся заново при следующем просмотре.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              CacheUtils.clearImageCache();
              Navigator.of(context).pop();
              _showSuccessDialog(context);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Кеш очищен'),
        content: const Text('Кеш изображений был успешно очищен.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('О приложении'),
        content: const Text(
          'KConnect Mobile\n'
          'Версия: 1.0.0\n\n'
          'У меня маленькие яйца',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выйти из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              // Reset theme to default immediately (like in personalization settings)
              context.read<ThemeBloc>().add(ResetThemeEvent());
              BlocProvider.of<AuthBloc>(context).add(LogoutEvent());
              Navigator.of(context).pop();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _navigateToPersonalization(BuildContext context) {
    Navigator.of(context).pushNamed(RouteNames.personalization);
  }
}
