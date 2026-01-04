import 'package:flutter/material.dart';
import '../../../core/utils/theme_extensions.dart';
import '../domain/models/user_profile.dart';

/// Утилитарный класс для операций с цветами профиля
class ProfileColorUtils {
  /// Получает акцентный цвет профиля, возвращаясь к динамическому основному цвету
  static Color getProfileAccentColor(UserProfile profile, BuildContext context) {
    if (profile.profileColor != null && profile.profileColor!.isNotEmpty) {
      try {
        final colorStr = profile.profileColor!.replaceFirst('#', '');
        final colorInt = int.parse(colorStr, radix: 16);
        return Color(colorInt | 0xFF000000);
      } catch (e) {
        // Некорректный цвет, возвращаемся к значению по умолчанию
      }
    }
    return context.dynamicPrimaryColor;
  }

  /// Проверяет, считается ли цвет белым (достаточно светлым)
  static bool isAccentWhite(Color accentColor) => accentColor.computeLuminance() > 0.85;
}
