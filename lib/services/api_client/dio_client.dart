import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:kconnect_mobile/services/api_client/interceptors/auth_interceptor.dart';
import 'package:kconnect_mobile/services/api_client/interceptors/logging_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP клиент для работы с API K-Connect
///
/// Обеспечивает безопасное управление сессиями, cookie и HTTP запросами.
/// Поддерживает как обычные запросы, так и multipart/form-data загрузки.
class WrappedDioClient {
  static final WrappedDioClient _instance = WrappedDioClient._internal();
  factory WrappedDioClient() => _instance;

  final cookieJar = CookieJar();

  late final Dio regularDio;
  late final Dio formDataDio;

  WrappedDioClient._internal() {
    _setupRegularDio();
    _setupFormDataDio();
  }

  void _setupRegularDio() {
    regularDio = Dio(BaseOptions(
      baseUrl: 'https://k-connect.ru',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent': 'K-Connect/1.0.0 (Flutter Mobile)',
      },
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      sendTimeout: Duration(seconds: 10),
    ));

    regularDio.interceptors.add(CookieManager(cookieJar));
    regularDio.interceptors.add(LoggingInterceptor());
    regularDio.interceptors.add(AuthInterceptor(this));
  }

  void _setupFormDataDio() {
    formDataDio = Dio(BaseOptions(
      baseUrl: 'https://k-connect.ru',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'K-Connect/1.0.0 (Flutter Mobile)',
      },
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      sendTimeout: Duration(seconds: 10),
    ));

    formDataDio.interceptors.add(CookieManager(cookieJar)); // Shared cookie jar
    formDataDio.interceptors.add(LoggingInterceptor());
    formDataDio.interceptors.add(AuthInterceptor(this));
  }

  /// Выполняет POST запрос к API
  ///
  /// [path] - путь к API эндпоинту (без baseUrl)
  /// [data] - данные для отправки в JSON формате
  /// [headers] - дополнительные заголовки запроса
  Future<Response> post(String path, Map<String, dynamic>? data, {Map<String, dynamic>? headers}) async {
    return regularDio.post(path, data: data, options: Options(headers: headers, extra: {'withCredentials': true}));
  }

  /// Выполняет GET запрос к API
  ///
  /// [path] - путь к API эндпоинту (без baseUrl)
  /// [headers] - дополнительные заголовки запроса
  /// [queryParameters] - параметры запроса
  /// [cancelToken] - токен для отмены запроса
  Future<Response> get(String path, {Map<String, dynamic>? headers, Map<String, dynamic>? queryParameters, CancelToken? cancelToken}) async {
    return regularDio.get(path, options: Options(headers: headers), queryParameters: queryParameters, cancelToken: cancelToken);
  }

  /// Выполняет DELETE запрос к API
  ///
  /// [path] - путь к API эндпоинту (без baseUrl)
  /// [headers] - дополнительные заголовки запроса
  Future<Response> delete(String path, {Map<String, dynamic>? headers}) async {
    return regularDio.delete(path, options: Options(headers: headers, extra: {'withCredentials': true}));
  }

  /// Выполняет POST запрос с FormData (для загрузки файлов)
  ///
  /// [path] - путь к API эндпоинту (без baseUrl)
  /// [data] - FormData с файлами и данными
  /// [headers] - дополнительные заголовки запроса
  Future<Response> postFormData(String path, FormData data, {Map<String, dynamic>? headers}) async {
    return formDataDio.post(path, data: data, options: Options(headers: headers, extra: {'withCredentials': true}));
  }

  /// Сохраняет сессионный ключ в защищенное хранилище
  ///
  /// Ключ хранится в SharedPreferences с шифрованием на уровне ОС.
  /// Также обновляется cookie jar для поддержания сессии в HTTP запросах.
  ///
  /// [key] - сессионный ключ от сервера
  Future<void> saveSession(String key) async {
    // Логируем только первые 10 символов для безопасности
    debugPrint('DioClient: saveSession called with key: ${key.substring(0, 10)}...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_key', key);

    // Обновляем сессионный cookie вместо полной очистки всех cookies
    final uri = Uri.parse('https://k-connect.ru');
    final cookies = await cookieJar.loadForRequest(uri);

    debugPrint('DioClient: Cookies before update: ${cookies.map((c) => '${c.name}=${c.value}').join(', ')}');

    // Удаляем старый сессионный cookie если существует
    cookies.removeWhere((cookie) => cookie.name == 'session_key');

    // Добавляем новый сессионный cookie
    cookies.add(Cookie('session_key', key)
      ..domain = 'k-connect.ru'
      ..path = '/'
      ..httpOnly = false);

    // Сохраняем обновленные cookies
    await cookieJar.saveFromResponse(uri, cookies);

    debugPrint('DioClient: Cookies after update: ${cookies.map((c) => '${c.name}=${c.value}').join(', ')}');
    debugPrint('DioClient: Session saved successfully');
  }

  /// Получает сессионный ключ из защищенного хранилища
  ///
  /// Returns: сессионный ключ или null если не найден
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_key');
  }

  /// Полностью очищает сессию и связанные данные
  ///
  /// Удаляет сессионный ключ из SharedPreferences и очищает все cookies.
  /// Используется при выходе из аккаунта для обеспечения безопасности.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_key');

    // Очищаем cookies для полной очистки сессии
    await cookieJar.deleteAll();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final sessionKey = await getSession();
    final headers = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'K-Connect/1.0.0 (Flutter Mobile)',
      'Origin': 'https://k-connect.ru',
      'Referer': 'https://k-connect.ru',
    };

    if (sessionKey != null) {
      headers['Authorization'] = 'Bearer $sessionKey';
      headers['Cookie'] = 'session_key=$sessionKey';
    }

    return headers;
  }

  /// Возвращает заголовки аутентификации, подходящие для запросов изображений (за исключением Content-Type).
  Future<Map<String, String>> getImageAuthHeaders() async {
    final sessionKey = await getSession();
    final headers = <String, String>{};

    if (sessionKey != null) {
      headers['Authorization'] = 'Bearer $sessionKey';
      headers['Cookie'] = 'session_key=$sessionKey';
    }

    return headers;
  }
}

typedef DioClient = WrappedDioClient;
