/// События для управления темой в BLoC
///
/// Определяет все возможные события, которые могут происходить
/// в процессе управления темой приложения (загрузка, обновление, сброс).

/// Базовый класс для всех событий темы
library;

import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class LoadThemeEvent extends ThemeEvent {}

class UpdateAccentColorEvent extends ThemeEvent {
  final String? accentColor;

  const UpdateAccentColorEvent(this.accentColor);

  @override
  List<Object> get props => [accentColor ?? ''];
}

class UpdateAccentColorStateEvent extends ThemeEvent {
  final String? accentColor;

  const UpdateAccentColorStateEvent(this.accentColor);

  @override
  List<Object> get props => [accentColor ?? ''];
}

class ResetThemeEvent extends ThemeEvent {}
