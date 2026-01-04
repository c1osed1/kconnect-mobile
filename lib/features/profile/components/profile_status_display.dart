/// Компонент отображения статуса пользователя с иконкой и цветом
///
/// Парсит текстовый статус пользователя, извлекает иконку и цвет,
/// отображает статус в стилизованном контейнере.
library;

import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_colors.dart';

/// Виджет отображения статуса пользователя
///
/// Поддерживает разные иконки и цвета для статуса.
/// Формат статуса: {icon}text или просто text.
class ProfileStatusDisplay extends StatelessWidget {
  final String statusText;

  const ProfileStatusDisplay({
    super.key,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    if (statusText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final displayData = _parseStatusText(statusText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: displayData.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: displayData.icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(displayData.icon, color: displayData.textColor, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  displayData.text,
                  style: AppTextStyles.body.copyWith(color: displayData.textColor),
                ),
              ],
            )
          : Text(
              displayData.text,
              style: AppTextStyles.body.copyWith(color: displayData.textColor),
              textAlign: TextAlign.center,
            ),
    );
  }

  StatusDisplayData _parseStatusText(String statusText) {
    final backgroundColor = _parseColor(statusText);
    final isBgLight = backgroundColor.computeLuminance() > 0.85;
    final textColor = isBgLight ? Colors.black : AppColors.textPrimary;

    // Parse icon and text: {icon}text
    if (statusText.startsWith('{')) {
      final closeBraceIndex = statusText.indexOf('}');
      if (closeBraceIndex > 1) {
        final iconName = statusText.substring(1, closeBraceIndex);
        final icon = _getStatusIcon(iconName);
        final text = statusText.substring(closeBraceIndex + 1).trim();

        return StatusDisplayData(
          text: text,
          icon: icon,
          backgroundColor: backgroundColor,
          textColor: textColor,
        );
      }
    }

    return StatusDisplayData(
      text: statusText,
      icon: null,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  Color _parseColor(String statusText) {
    try {
      final colorStr = statusText.contains('}') ? 'FFFFFF' : 'FFFFFF';
      final colorInt = int.parse(colorStr, radix: 16);
      return Color(colorInt | 0xFF000000);
    } catch (e) {
      return const Color(0xFFFFFFFF);
    }
  }

  IconData? _getStatusIcon(String iconName) {
    switch (iconName) {
      case 'info':
        return Icons.info_outline;
      case 'cloud':
        return Icons.cloud_outlined;
      case 'minion':
        return Icons.people_outline;
      case 'heart':
        return Icons.favorite_border;
      case 'star':
        return Icons.star_border;
      case 'music':
        return Icons.music_note;
      case 'location':
        return Icons.location_on;
      case 'cake':
        return Icons.cake;
      case 'chat':
        return Icons.chat_bubble_outline;
      default:
        return null;
    }
  }
}

class StatusDisplayData {
  final String text;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  const StatusDisplayData({
    required this.text,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
  });
}
