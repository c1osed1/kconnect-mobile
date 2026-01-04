/// Интерцептор для автоматического добавления аутентификационных заголовков
///
/// Автоматически добавляет Bearer токен и cookie к каждому HTTP запросу.
/// Обеспечивает безопасность передачи сессионных данных.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../dio_client.dart';

class AuthInterceptor extends Interceptor {
  final DioClient _client;

  AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final sessionKey = await _client.getSession();
    debugPrint('AuthInterceptor: Session key from storage: ${sessionKey != null ? "${sessionKey.substring(0, 10)}..." : "null"}');

    if (sessionKey != null) {
      options.headers['Authorization'] = 'Bearer $sessionKey';
      options.headers['Cookie'] = 'session_key=$sessionKey';

      debugPrint('AuthInterceptor: Added headers - Authorization: Bearer ${sessionKey.substring(0, 10)}..., Cookie: session_key=${sessionKey.substring(0, 10)}...');
    } else {
      debugPrint('AuthInterceptor: No session key found, sending request without auth headers');
    }

    debugPrint('AuthInterceptor: Final request headers: ${options.headers}');
    debugPrint('AuthInterceptor: Request URL: ${options.uri}');

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Если нужно, можно тут обработать 401 и редирект на логин
    super.onError(err, handler);
  }
}
