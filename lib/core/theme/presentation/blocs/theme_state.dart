import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Состояния BLoC для темы
///
/// Определяет все возможные состояния процесса управления темой,
/// включая состояния загрузки, успеха и ошибок.

/// Базовый класс для всех состояний темы
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final MaterialColor accentColor;

  const ThemeLoaded(this.accentColor);

  Color get primaryColor => accentColor;

  @override
  List<Object> get props => [accentColor];
}
