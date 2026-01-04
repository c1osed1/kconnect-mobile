import 'api_client/dio_client.dart';

/// Сервис для работы с пользователями через API
///
/// Предоставляет методы для получения информации о пользователях,
/// включая список онлайн-пользователей.
class UsersService {
  final DioClient _client = DioClient();

  Future<List<dynamic>> fetchOnlineUsers({int limit = 100}) async {
    final res = await _client.get('/api/users/online', queryParameters: {'limit': limit});
    if (res.statusCode == 200) {
      return res.data as List<dynamic>;
    } else {
      throw Exception('Не удалось загрузить онлайн-пользователей');
    }
  }
}
