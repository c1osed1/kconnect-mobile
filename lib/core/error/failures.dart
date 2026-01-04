import 'package:equatable/equatable.dart';

/// Базовый класс для всех типов ошибок в приложении
///
/// Все ошибки наследуются от этого класса для обеспечения консистентности
/// обработки ошибок во всем приложении.
abstract class Failure extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Ошибка сервера при выполнении API запросов
///
/// Возникает при получении ошибок от бэкенда (4xx, 5xx статусы).
class ServerFailure extends Failure {
  final String? message;

  ServerFailure({this.message});

  @override
  List<Object?> get props => [message];
}

/// Ошибка кэширования данных
///
/// Возникает при проблемах с сохранением или чтением кэшированных данных.
class CacheFailure extends Failure {}

/// Ошибка сетевого подключения
///
/// Возникает при отсутствии интернет-соединения или проблемах с сетью.
class NetworkFailure extends Failure {}

/// Ошибка валидации данных
///
/// Содержит информацию о поле и сообщении об ошибке валидации.
class ValidationFailure extends Failure {
  final String field;
  final String message;

  ValidationFailure({required this.field, required this.message});

  @override
  List<Object?> get props => [field, message];
}

/// Ошибка авторизации
///
/// Возникает при попытке доступа к защищенным ресурсам без авторизации.
class UnauthorizedFailure extends Failure {}

/// Ошибка "Не найдено"
///
/// Возникает при запросе несуществующего ресурса.
class NotFoundFailure extends Failure {
  final String? message;

  NotFoundFailure({this.message});

  @override
  List<Object?> get props => [message];
}

/// Ошибка аудио функционала
///
/// Возникает при проблемах с воспроизведением музыки или аудио контента.
class AudioFailure extends Failure {
  final String? message;

  AudioFailure({this.message});

  @override
  List<Object?> get props => [message];
}
