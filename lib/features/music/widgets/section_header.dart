/// Заголовок секции с опциональной кнопкой "Посмотреть всё"
///
/// Переиспользуемый компонент для заголовков секций в музыкальном интерфейсе.
/// Может содержать кнопку для просмотра полного списка элементов секции.
library;

import 'package:flutter/cupertino.dart';
import '../../../theme/app_text_styles.dart';

/// Виджет заголовка секции с опциональной кнопкой действия
///
/// Отображает название секции и опциональную кнопку "Посмотреть всё"
/// для навигации к полному списку элементов.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.h3,
          ),
          if (onSeeAll != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onSeeAll,
              child: Text(
                'Посмотреть всё',
                style: AppTextStyles.bodySecondary.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
