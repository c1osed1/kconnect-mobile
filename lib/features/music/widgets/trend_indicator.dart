/// Виджет индикатора тренда трека
///
/// Отображает стрелку вверх (рост) или вниз (падение) для популярных треков.
/// Поддерживает цветовую индикацию: зеленый для роста, красный для падения.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_text_styles.dart';

/// Виджет для отображения тренда трека
class TrendIndicator extends StatelessWidget {
  /// Тренд трека: 'up', 'down' или null
  final String? trend;

  /// Процент изменения (опционально для отображения)
  final double? changePercent;

  /// Размер иконки
  final double iconSize;

  /// Размер виджета
  final double? size;

  const TrendIndicator({
    super.key,
    this.trend,
    this.changePercent,
    this.iconSize = 14,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (trend == null || (trend != 'up' && trend != 'down')) {
      return SizedBox(width: size ?? iconSize, height: size ?? iconSize);
    }

    final isUp = trend == 'up';
    final color = isUp ? const Color(0xFF4CAF50) : const Color(0xFFF44336); // Green for up, red for down
    final icon = isUp ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down;

    return Container(
      width: size ?? iconSize + 4,
      height: size ?? iconSize + 4,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: color,
          ),
          if (changePercent != null && changePercent!.abs() > 0) ...[
            const SizedBox(width: 2),
            Text(
              '${changePercent! > 0 ? '+' : ''}${changePercent!.toStringAsFixed(0)}%',
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
