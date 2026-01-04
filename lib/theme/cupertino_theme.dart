/// Функции создания тем Cupertino
///
/// Создает настроенные темы Cupertino с динамическими акцентными цветами.
/// Используется для персонализации интерфейса на основе цвета профиля.
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

CupertinoThemeData buildCupertinoTheme(MaterialColor accentColor) {
  return CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: accentColor,
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        fontFamily: AppFonts.poppins,
        fontSize: 16,
        color: CupertinoColors.white,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: AppFonts.mplus,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: accentColor,
      ),
      actionTextStyle: TextStyle(
        fontFamily: AppFonts.poppins,
        fontSize: 16,
        color: accentColor,
      ),
    ),
  );
}
