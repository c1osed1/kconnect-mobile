/// Виджет кнопки для генерации персонализированного плейлиста "Vibe"
///
/// Отображает привлекательную кнопку с градиентом для запуска
/// сервиса генерации музыки на основе предпочтений пользователя.
/// Поддерживает состояние загрузки и персонализированные цвета.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/theme_extensions.dart';

/// Виджет кнопки Vibe
class VibeButton extends StatelessWidget {
  final VoidCallback onGenerateVibe;
  final bool isLoading;

  const VibeButton({
    super.key,
    required this.onGenerateVibe,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isLoading ? null : onGenerateVibe,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.dynamicGradientStart, context.dynamicGradientEnd],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon section
              const Padding(
                padding: EdgeInsets.only(left: 24, right: 16),
                child: Icon(
                  CupertinoIcons.wand_stars,
                  size: 48,
                  color: AppColors.bgWhite,
                ),
              ),
              // Text section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Мой вайб',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.bgWhite,
                      ),
                    ),
                    Text(
                      'Сервис сам подберёт треки для тебя',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.bgWhite.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow section
              Padding(
                padding: const EdgeInsets.all(24),
                child: isLoading
                    ? const CupertinoActivityIndicator(
                        color: AppColors.bgWhite,
                      )
                    : const Icon(
                        CupertinoIcons.chevron_right,
                        size: 24,
                        color: AppColors.bgWhite,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
