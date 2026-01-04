/// Кнопка прокрутки наверх с эффектом жидкого стекла
///
/// Плавающая кнопка для быстрой прокрутки к началу списка.
/// Использует эффект liquid glass для стильного внешнего вида.
library;

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Виджет кнопки для прокрутки к началу списка
///
/// Создает плавающую кнопку с эффектом жидкого стекла.
/// Располагается в правом нижнем углу экрана и содержит иконку стрелки вверх.
class ScrollToTopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScrollToTopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 20,
      child: SizedBox(
        width: 50,
        height: 50,
        child: LiquidGlassLayer(
          fake: true,
          settings: const LiquidGlassSettings(
            blur: 4,
            glassColor: Color(0x33FFFFFF),
          ),
          child: LiquidGlass(
            shape: LiquidRoundedSuperellipse(borderRadius: 25),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              child: const Icon(
                CupertinoIcons.up_arrow,
                color: CupertinoColors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
