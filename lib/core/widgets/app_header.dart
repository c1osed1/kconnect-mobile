/// Заголовок приложения с логотипом, названием и уведомлениями
///
/// Адаптивный заголовок, который изменяется в зависимости от текущего таба
/// и состояния приложения. Включает специальные заголовки для музыкальных секций
/// с кнопками возврата.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/utils/theme_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/bloc/notifications_state.dart';
import 'badge_icon.dart';

/// Виджет заголовка приложения
class AppHeader extends StatelessWidget {
  /// Индекс текущего активного таба
  final int currentTabIndex;

  /// Флаг нахождения в секции любимых треков музыки
  final bool isInMusicFavoritesSection;

  /// Колбэк для возврата из секции любимых треков
  final VoidCallback? onMusicFavoritesBack;

  /// Флаг нахождения в секции плейлистов музыки
  final bool isInMusicPlaylistsSection;

  /// Колбэк для возврата из секции плейлистов
  final VoidCallback? onMusicPlaylistsBack;

  /// Флаг нахождения в секции всех треков музыки
  final bool isInMusicAllTracksSection;

  /// Колбэк для возврата из секции всех треков
  final VoidCallback? onMusicAllTracksBack;

  /// Флаг нахождения в секции поиска музыки
  final bool isInMusicSearchSection;

  /// Колбэк для возврата из секции поиска музыки
  final VoidCallback? onMusicSearchBack;

  /// Колбэк при нажатии на иконку уведомлений
  final VoidCallback? onNotificationsTap;

  /// Флаг открытого состояния уведомлений
  final bool isNotificationsOpen;

  /// Флаг скрытия бейджа уведомлений
  final bool hideNotificationsBadge;

  const AppHeader({
    super.key,
    required this.currentTabIndex,
    this.isInMusicFavoritesSection = false,
    this.onMusicFavoritesBack,
    this.isInMusicPlaylistsSection = false,
    this.onMusicPlaylistsBack,
    this.isInMusicAllTracksSection = false,
    this.onMusicAllTracksBack,
    this.isInMusicSearchSection = false,
    this.onMusicSearchBack,
    this.onNotificationsTap,
    this.isNotificationsOpen = false,
    this.hideNotificationsBadge = false,
  });

  /// Возвращает название текущего таба
  String _getTabTitle() {
    switch (currentTabIndex) {
      case 0:
        return 'Профиль';
      case 1:
        return 'Музыка';
      case 2:
        return 'Лента';
      case 3:
        return 'Сообщения';
      case 4:
        return 'Меню';
      default:
        return 'K-Connect';
    }
  }

  /// Создает список виджетов действий для заголовка
  List<Widget> _getActions(BuildContext context) {
    return [
      BlocSelector<NotificationsBloc, NotificationsState, int>(
        selector: (state) => state.unreadCount,
        builder: (context, unreadCount) => BadgeIcon(
          count: hideNotificationsBadge ? 0 : unreadCount,
          onPressed: onNotificationsTap,
          icon: Icon(
            isNotificationsOpen ? CupertinoIcons.xmark : CupertinoIcons.bell,
            color: context.dynamicPrimaryColor,
            size: 26,
          ),
        ),
      ),
    ];
  }

  /// Построение виджета заголовка в зависимости от состояния
  @override
  Widget build(BuildContext context) {
    // Специальный заголовок для секции любимых треков музыки
    if (isInMusicFavoritesSection && onMusicFavoritesBack != null) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withValues(alpha: 0.8),
          border: Border(
            bottom: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Кнопка со стрелкой назад (позиционирована как логотип)
            Transform.translate(
              offset: const Offset(0, 0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onMusicFavoritesBack,
                child: const Icon(
                  CupertinoIcons.arrow_left,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 0),
            Text(
              'Мои любимые',
              style: AppTextStyles.postAuthor.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ..._getActions(context),
          ],
        ),
      );
    }

    // Специальный заголовок для секции плейлистов музыки
    if (isInMusicPlaylistsSection && onMusicPlaylistsBack != null) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withValues(alpha: 0.8),
          border: Border(
            bottom: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Кнопка со стрелкой назад (позиционирована как логотип)
            Transform.translate(
              offset: const Offset(0, 0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onMusicPlaylistsBack,
                child: const Icon(
                  CupertinoIcons.arrow_left,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 0),
            Text(
              'Плейлисты',
              style: AppTextStyles.postAuthor.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ..._getActions(context),
          ],
        ),
      );
    }

    // Специальный заголовок для секции всех треков музыки
    if (isInMusicAllTracksSection && onMusicAllTracksBack != null) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withValues(alpha: 0.8),
          border: Border(
            bottom: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Transform.translate(
              offset: const Offset(0, 0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onMusicAllTracksBack,
                child: const Icon(
                  CupertinoIcons.arrow_left,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 0),
            Text(
              'Все треки',
              style: AppTextStyles.postAuthor.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ..._getActions(context),
          ],
        ),
      );
    }

    // Специальный заголовок для секции поиска музыки
    if (isInMusicSearchSection && onMusicSearchBack != null) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withValues(alpha: 0.8),
          border: Border(
            bottom: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Transform.translate(
              offset: const Offset(0, 0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onMusicSearchBack,
                child: const Icon(
                  CupertinoIcons.arrow_left,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 0),
            Text(
              'Поиск музыки',
              style: AppTextStyles.postAuthor.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ..._getActions(context),
          ],
        ),
      );
    }

    // Стандартный заголовок
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'lib/assets/icons/logo.svg',
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(context.dynamicPrimaryColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Text(
            isNotificationsOpen ? 'Уведомления' : _getTabTitle(),
            style: AppTextStyles.postAuthor.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ..._getActions(context),
        ],
      ),
    );
  }
}
