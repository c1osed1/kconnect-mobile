/// Темы приложения
///
/// Определяет светлую и темную темы приложения для Material и Cupertino.
/// Настраивает цвета, шрифты и общие параметры интерфейса.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_fonts.dart';

class AppTheme {
  static CupertinoThemeData get light => CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryPurple,
        scaffoldBackgroundColor: AppColors.bgWhite,
        textTheme: CupertinoTextThemeData(
          textStyle: AppTextStyles.body,
          navTitleTextStyle: AppTextStyles.h3,
          navLargeTitleTextStyle: AppTextStyles.h1,
          pickerTextStyle: AppTextStyles.body,
        ),
      );

  static CupertinoThemeData get dark => CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryPurple,
        scaffoldBackgroundColor: AppColors.bgDark,
        textTheme: CupertinoTextThemeData(
          textStyle: AppTextStyles.body,
          navTitleTextStyle: AppTextStyles.h3,
          navLargeTitleTextStyle: AppTextStyles.h1,
          pickerTextStyle: AppTextStyles.body,
        ),
      );

  static ThemeData materialDarkTheme(MaterialColor accentColor) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: AppFonts.poppins,
      textTheme: TextTheme(
        bodyLarge: AppTextStyles.body,
        headlineSmall: AppTextStyles.h3,
        headlineMedium: AppTextStyles.h2,
        headlineLarge: AppTextStyles.h1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.mplus,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
