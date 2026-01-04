/// Виджет иконки с бейджем счетчика
///
/// Отображает иконку с наложенным бейджем, показывающим количество.
/// Поддерживает динамическое определение цвета текста бейджа
/// для обеспечения контрастности с фоновым цветом.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/utils/theme_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Виджет иконки с бейджем уведомлений
///
/// Компонент для отображения иконок с числовыми индикаторами.
/// Автоматически определяет цвет текста бейджа для обеспечения читаемости.
class BadgeIcon extends StatelessWidget {
  /// Виджет иконки для отображения
  final Widget icon;

  /// Количество для отображения в бейдже (0 = скрыть бейдж)
  final int count;

  /// Колбэк при нажатии на иконку
  final VoidCallback? onPressed;

  /// Конструктор виджета бейджа иконки
  const BadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    this.onPressed,
  });

  /// Построение виджета иконки с бейджем
  ///
  /// Создает Stack с иконкой и наложенным бейджем (если count > 0).
  /// Бейдж использует динамический основной цвет с автоматическим
  /// подбором цвета текста для обеспечения контрастности.
  @override
  Widget build(BuildContext context) {
    final showBadge = count > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed, minimumSize: Size(32, 32),
          child: icon,
        ),
        if (showBadge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
              decoration: BoxDecoration(
                color: context.dynamicPrimaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bgDark, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _badgeTextColor(context),
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ) ??
                TextStyle(
                  fontFamily: AppFonts.poppins,
                  color: _badgeTextColor(context),
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Определение цвета текста бейджа для обеспечения контрастности
  ///
  /// Если основной цвет светлый (близок к белому), использует черный текст.
  /// В противном случае использует основной цвет текста приложения.
  Color _badgeTextColor(BuildContext context) {
    final primary = context.dynamicPrimaryColor;
    // Если основной цвет светлый (близок к белому), используем черный текст для контраста
    return primary.computeLuminance() > 0.8 ? Colors.black : AppColors.textPrimary;
  }
}
