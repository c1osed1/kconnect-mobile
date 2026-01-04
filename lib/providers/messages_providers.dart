/// Провайдеры BLoC для системы сообщений
///
/// Создает и настраивает все зависимости для работы с сообщениями,
/// включая репозитории, use cases и WebSocket соединение.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/blocs/auth_bloc.dart';
import '../features/messages/data/services/messages_service.dart';
import '../features/messages/data/repositories/messages_repository_impl.dart';
import '../features/messages/domain/usecases/fetch_chats_usecase.dart';
import '../features/messages/presentation/blocs/messages_bloc.dart';
import '../services/messenger_websocket_service.dart';
import '../services/api_client/dio_client.dart';

/// Провайдеры для BLoC системы сообщений
class MessagesBlocProviders {
  static MessagesService createMessagesService() {
    return MessagesService();
  }

  static MessagesRepositoryImpl createMessagesRepository() {
    return MessagesRepositoryImpl(createMessagesService());
  }

  static FetchChatsUseCase createFetchChatsUseCase() {
    return FetchChatsUseCase(createMessagesRepository());
  }

  static MessengerWebSocketService createWebSocketService(DioClient dioClient) {
    return MessengerWebSocketService(dioClient);
  }

  static MessagesBloc createMessagesBloc(AuthBloc authBloc, DioClient dioClient) {
    return MessagesBloc(
      createFetchChatsUseCase(),
      authBloc,
      createMessagesRepository(),
      createWebSocketService(dioClient),
    );
  }

  static List<BlocProvider> get providers => [
    BlocProvider<MessagesBloc>(
      create: (context) {
        final authBloc = BlocProvider.of<AuthBloc>(context);
        final dioClient = DioClient();
        return createMessagesBloc(authBloc, dioClient);
      },
    ),
  ];
}
