/// Цветовая палитра приложения K-Connect
///
/// Предоставляет централизованную систему цветов для всего приложения.
/// Поддерживает динамическое обновление цветов на основе выбранной темы.
library;

import 'package:flutter/material.dart';

class AppColors {
  // ValueNotifier для реактивного обновления цветов
  static final ValueNotifier<Color> _primaryColorNotifier = ValueNotifier(const Color(0xFFD0BCFF));
  static final ValueNotifier<Color> _gradientStartNotifier = ValueNotifier(const Color(0xFFB69DF8));
  static final ValueNotifier<Color> _gradientEndNotifier = ValueNotifier(const Color(0xFFD0BCFF));

  // Текущие динамические цвета (изменяются от темы)
  static Color _currentPrimaryColor = const Color(0xFFD0BCFF);
  static Color _currentGradientStart = const Color(0xFFB69DF8);
  static Color _currentGradientEnd = const Color(0xFFD0BCFF);

  /// Обновляет динамические цвета на основе выбранного MaterialColor темы
  ///
  /// [themeColor] - цвет темы из MaterialColor, может быть null
  static void updateFromMaterialColor(MaterialColor? themeColor) {
    if (themeColor == null) {
      // Если передан null, сбрасываем к дефолтным цветам
      resetToDefault();
      return;
    }

    _currentPrimaryColor = themeColor;
    _currentGradientStart = themeColor.shade100; // Более светлый оттенок градиента
    _currentGradientEnd = themeColor; // Основной цвет градиента

    // Уведомляем слушателей об изменении цветов
    _primaryColorNotifier.value = _currentPrimaryColor;
    _gradientStartNotifier.value = _currentGradientStart;
    _gradientEndNotifier.value = _currentGradientEnd;
  }

  /// Сбрасывает цвета к значениям по умолчанию
  ///
  /// Примечание: не используется, но сохранено для консистентности
  static void resetToDefault() {
    _currentPrimaryColor = const Color(0xFFD0BCFF);
    _currentGradientStart = const Color(0xFFB69DF8);
    _currentGradientEnd = const Color(0xFFD0BCFF);

    // Уведомляем слушателей об изменении
    _primaryColorNotifier.value = _currentPrimaryColor;
    _gradientStartNotifier.value = _currentGradientStart;
    _gradientEndNotifier.value = _currentGradientEnd;
  }

  // Основные брендовые цвета (динамические)

  /// Основной фиолетовый цвет (динамический, изменяется от темы)
  static Color get primaryPurple => _currentPrimaryColor;

  /// Начальный цвет градиента (динамический)
  static Color get gradientStart => _currentGradientStart;

  /// Конечный цвет градиента (динамический)
  static Color get gradientEnd => _currentGradientEnd;

  // Фоновые цвета (статические)

  /// Белый фон
  static const Color bgWhite = Color(0xFFFFFFFF);

  /// Темный фон основного интерфейса
  static const Color bgDark = Color(0xFF1C1C1C);

  /// Фон карточек и элементов
  static const Color bgCard = Color(0xFF171717);

  // Текстовые цвета (статические)

  /// Основной цвет текста
  static const Color textPrimary = Color(0xFFEAEAEA);

  /// Вторичный цвет текста
  static const Color textSecondary = Color(0xFFB0B0B0);

  // Цвета состояний (статические)

  /// Цвет успешных операций
  static const Color success = Color(0xFF50C878);

  /// Цвет ошибок и неудачных операций
  static const Color error = Color(0xFFFF5C5C);

  /// Цвет предупреждений
  static const Color warning = Color(0xFFFFD700);

  // Полупрозрачные цвета (статические)

  /// Темный полупрозрачный оверлей
  static const Color overlayDark = Color(0xAA000000);
}
