import 'package:kconnect_mobile/features/messages/domain/models/chat.dart';
import 'package:kconnect_mobile/features/messages/domain/repositories/messages_repository.dart';

/// Use case для получения списка чатов пользователя
///
/// Загружает все чаты пользователя с информацией о последних сообщениях,
/// участниках и количестве непрочитанных сообщений.
class FetchChatsUseCase {
  final MessagesRepository _repository;

  FetchChatsUseCase(this._repository);

  /// Выполняет загрузку чатов пользователя
  ///
  /// Returns: список чатов с полной информацией для отображения в интерфейсе
  Future<List<Chat>> call() {
    return _repository.fetchChats();
  }
}
