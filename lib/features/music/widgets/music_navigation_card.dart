/// Навигационные карточки для музыкальных разделов
///
/// Переиспользуемые карточки для навигации по разделам музыки:
/// избранные треки, плейлисты и другие музыкальные функции.
/// Поддерживают разные цвета и иконки для визуального различения.
library;

import 'package:flutter/cupertino.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../theme/app_colors.dart';

/// Карточка навигации для музыкальных разделов
///
/// Отображает иконку, заголовок и поддерживает нажатие.
/// Используется для создания навигации по разделам музыки.
class MusicNavigationCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const MusicNavigationCard({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? context.dynamicPrimaryColor;

    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    size: 24,
                    color: accentColor,
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: icon != null ? EdgeInsets.zero : const EdgeInsets.all(8),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation cards row widget for consistent layout
class MusicNavigationCardsRow extends StatelessWidget {
  final MusicNavigationCard leftCard;
  final MusicNavigationCard rightCard;

  const MusicNavigationCardsRow({
    super.key,
    required this.leftCard,
    required this.rightCard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          leftCard,
          const SizedBox(width: 8),
          rightCard,
        ],
      ),
    );
  }
}
