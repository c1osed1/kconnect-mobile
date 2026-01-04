import 'package:flutter/material.dart';
import '../../core/utils/theme_extensions.dart';

/// InheritedWidget для автоматической передачи акцентного цвета профиля вниз по дереву виджетов.
/// Поддерживает вложенность - ближайший Provider имеет приоритет.
class ProfileAccentColorProvider extends InheritedWidget {
  /// Акцентный цвет профиля пользователя
  final Color? accentColor;

  /// Конструктор провайдера акцентного цвета профиля
  const ProfileAccentColorProvider({
    super.key,
    required super.child,
    this.accentColor,
  });

  /// Получает экземпляр провайдера из контекста (может вернуть null)
  static ProfileAccentColorProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProfileAccentColorProvider>();
  }

  /// Определяет необходимость обновления виджета при изменении состояния
  @override
  bool updateShouldNotify(ProfileAccentColorProvider oldWidget) {
    return oldWidget.accentColor != accentColor;
  }
}

/// Extension для удобного доступа к акцентному цвету профиля
extension ProfileAccentColorExtension on BuildContext {
  /// Получает акцентный цвет профиля из ближайшего провайдера
  ///
  /// Если провайдер не найден или цвет не установлен,
  /// возвращает динамический основной цвет.
  Color get profileAccentColor {
    final provider = ProfileAccentColorProvider.maybeOf(this);
    if (provider?.accentColor != null) {
      return provider!.accentColor!;
    }
    // Возврат к динамическому основному цвету, если нет провайдера или null акцентного цвета
    return dynamicPrimaryColor;
  }
}
