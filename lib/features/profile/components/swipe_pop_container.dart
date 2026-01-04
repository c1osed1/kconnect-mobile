/// Контейнер с поддержкой swipe-to-pop жестов для навигации
///
/// Обрабатывает жесты swipe для возврата назад.
/// Поддерживает как горизонтальный swipe, так и tap для закрытия.
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// Виджет контейнера с поддержкой swipe-to-pop
///
/// Обрабатывает горизонтальные свайпы для навигации назад.
/// Используется для создания интерактивных панелей и модальных окон.
class SwipePopContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPop;

  const SwipePopContainer({
    super.key,
    required this.child,
    this.onPop,
  });

  @override
  State<SwipePopContainer> createState() => _SwipePopContainerState();
}

class _SwipePopContainerState extends State<SwipePopContainer> {
  double _dragDistance = 0;
  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer()
      ..onStart = (details) {
        _dragDistance = 0;
      }
      ..onUpdate = (details) {
        _dragDistance += details.delta.dx;
      }
      ..onEnd = (details) {
        // iOS-style swipe back: swiped right from anywhere on screen, with sufficient distance or velocity
        final swipedRight = _dragDistance > 50;
        final fastVelocity = details.velocity.pixelsPerSecond.dx > 300;
        final longDistance = _dragDistance > 100;

        if (swipedRight && (fastVelocity || longDistance)) {
          if (widget.onPop != null) {
            widget.onPop!();
          } else if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      };
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
          () => _recognizer,
          (HorizontalDragGestureRecognizer instance) {},
        ),
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
