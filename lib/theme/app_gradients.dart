/// Градиенты приложения
///
/// Определяет градиентные цвета, используемые в интерфейсе приложения.
/// Основной градиент для акцентных элементов и кнопок.
library;

import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

class AppGradients {
  static LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientEnd,
    ],
  );
}
