/// Интерцептор для логирования HTTP запросов и ответов
///
/// Перехватывает все запросы и ответы Dio, логируя их для отладки.
/// Помогает отслеживать сетевые операции и выявлять проблемы.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Интерцептор логирования для Dio клиента
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('DIO REQUEST: ${options.method} ${options.uri}');
    debugPrint('HEADERS: ${options.headers}');
    if (options.data != null) {
      debugPrint('DATA: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('QUERY: ${options.queryParameters}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('DIO RESPONSE ${response.statusCode}: ${response.realUri}');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('DATA: ${response.data}');
    if (response.data is String) {
      debugPrint('RESPONSE BODY LENGTH: ${response.data.length}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('DIO ERROR: ${err.type} for ${err.requestOptions.uri}');
    debugPrint('STATUS CODE: ${err.response?.statusCode}');
    if (err.response?.data != null) {
      debugPrint('ERROR DATA: ${err.response?.data}');
    }
    debugPrint('ERROR MESSAGE: ${err.message}');
    super.onError(err, handler);
  }
}
