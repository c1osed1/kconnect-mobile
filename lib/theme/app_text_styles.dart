/// Стили текста приложения
///
/// Определяет все текстовые стили, используемые в приложении.
/// Разделены по назначению: заголовки, основной текст, кнопки, посты.
library;

import 'package:flutter/cupertino.dart';
import 'app_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Заголовки — Mplus
  static final TextStyle h1 = TextStyle(
    fontFamily: AppFonts.mplus,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static final TextStyle h2 = TextStyle(
    fontFamily: AppFonts.mplus,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static final TextStyle h3 = TextStyle(
    fontFamily: AppFonts.mplus,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  // Основной текст — Poppins
  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static final TextStyle bodySecondary = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
  );

  static final TextStyle button = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.bgWhite,
    decoration: TextDecoration.none,
  );

  static final TextStyle buttonWhite = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.bgWhite,
    decoration: TextDecoration.none,
  );

  static final bodyMedium = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.bgWhite,
    decoration: TextDecoration.none,
  );

  // Стили для постов
  static final postAuthor = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static final postUsername = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
  );

  static final postContent = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 14,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static final postStats = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
  );

  // Стили для времени постов
  static final postTime = TextStyle(
    fontFamily: AppFonts.poppins,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
  );
}
