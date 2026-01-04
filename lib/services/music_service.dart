/// Сервис для работы с музыкальным API
///
/// Предоставляет методы для загрузки треков, плейлистов, чартов.
/// Поддерживает пагинацию и поиск музыкального контента.
library;

import 'package:dio/dio.dart';
import 'api_client/dio_client.dart';
import '../features/music/domain/models/track.dart';
import '../features/music/domain/models/playlist.dart';
import '../features/music/domain/models/artist.dart';

typedef PaginatedPlaylistsResponse = PaginatedResponse<Playlist>;
typedef PaginatedTracksResponse = PaginatedResponse<Track>;

/// Сервис музыкального API
class MusicService {
  final DioClient _client = DioClient();

  Future<PaginatedTracksResponse> fetchFavorites({int page = 1, int perPage = 20}) async {
    try {
      final res = await _client.get('/api/music/liked/order', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return PaginatedResponse.fromJson(
          data,
          Track.fromJson,
          'tracks',
        );
      } else {
        throw Exception('Failed to fetch favorites: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch favorites: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Track>> fetchAllTracks({int page = 1, int limit = 50}) async {
    try {
      final res = await _client.get('/api/music/tracks', queryParameters: {'page': page, 'limit': limit});
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final tracksData = List<Map<String, dynamic>>.from(data['tracks'] ?? []);
        return tracksData.map((trackJson) => Track.fromJson(trackJson)).toList();
      } else {
        throw Exception('Failed to fetch tracks: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch tracks: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<PaginatedTracksResponse> fetchAllTracksPaginated({int page = 1, int perPage = 50}) async {
    try {
      final res = await _client.get('/api/music', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return PaginatedResponse.fromJson(
          data,
          Track.fromJson,
          'tracks',
        );
      } else {
        throw Exception('Failed to fetch paginated tracks: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch paginated tracks: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<PaginatedPlaylistsResponse> fetchMyPlaylists({int page = 1, int perPage = 20}) async {
    try {
      final res = await _client.get('/api/music/playlists', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return PaginatedResponse.fromJson(
          data,
          Playlist.fromJson,
          'playlists',
        );
      } else {
        throw Exception('Failed to fetch my playlists: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch my playlists: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<PaginatedPlaylistsResponse> fetchPublicPlaylists({int page = 1, int perPage = 20}) async {
    try {
      final res = await _client.get('/api/music/playlists/public', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return PaginatedResponse.fromJson(
          data,
          Playlist.fromJson,
          'playlists',
        );
      } else {
        throw Exception('яйца: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('яйца: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    try {
      final res = await _client.get('/api/music/artists');
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['artists'] ?? []);
      } else {
        throw Exception('Failed to fetch artists: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch artists: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Artist>> fetchRecommendedArtists() async {
    try {
      final res = await _client.get('/api/music/artists/recommended', queryParameters: {'limit': 6});
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final artistsData = List<Map<String, dynamic>>.from(data['artists'] ?? []);
        return artistsData.map((artistJson) => Artist.fromJson(artistJson)).toList();
      } else {
        throw Exception('Failed to fetch recommended artists: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch recommended artists: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Track>> fetchPopularTracks() async {
    try {
      final res = await _client.get('/api/music/popular', queryParameters: {'limit': 10});
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final tracksData = List<Map<String, dynamic>>.from(data['tracks'] ?? []);
        return tracksData.map((trackJson) => Track.fromJson(trackJson)).toList();
      } else {
        throw Exception('Failed to fetch popular tracks: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch popular tracks: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Track>> fetchNewTracks() async {
    try {
      final res = await _client.get('/api/music/tracks/new');
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final tracksData = List<Map<String, dynamic>>.from(data['tracks'] ?? []);
        return tracksData.map((trackJson) => Track.fromJson(trackJson)).toList();
      } else {
        throw Exception('Failed to fetch new tracks: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch new tracks: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<Map<String, List<Track>>> fetchCharts() async {
    try {
      final res = await _client.get('/api/music/charts', queryParameters: {
        'type': 'combined',
        'limit': 50,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final charts = data['charts'] as Map<String, dynamic>;

        return {
          'most_liked': List<Map<String, dynamic>>.from(charts['most_liked'] ?? []).map((trackJson) => Track.fromJson(trackJson)).toList(),
          'most_played': List<Map<String, dynamic>>.from(charts['most_played'] ?? []).map((trackJson) => Track.fromJson(trackJson)).toList(),
          'new_releases': List<Map<String, dynamic>>.from(charts['new_releases'] ?? []).map((trackJson) => Track.fromJson(trackJson)).toList(),
          'popular': List<Map<String, dynamic>>.from(charts['popular'] ?? []).map((trackJson) => Track.fromJson(trackJson)).toList(),
        };
      } else {
        throw Exception('Failed to fetch charts: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch charts: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Track>> fetchMyVibe() async {
    try {
      final res = await _client.get('/api/music/my-vibe');
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final tracksData = List<Map<String, dynamic>>.from(data['tracks'] ?? []);
        return tracksData.map((trackJson) => Track.fromJson(trackJson)).toList();
      } else {
        throw Exception('Failed to fetch my vibe: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch my vibe: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<List<Track>> generateVibe() async {
    try {
      final res = await _client.post('/api/music/vibe', null, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final tracksData = List<Map<String, dynamic>>.from(data['tracks'] ?? []);
        return tracksData.map((trackJson) => Track.fromJson(trackJson)).toList();
      } else {
        throw Exception('Failed to generate vibe: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to generate vibe: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<Map<String, dynamic>> toggleLikeTrack(String trackId) async {
    try {
      final res = await _client.post('/api/music/$trackId/like', {}, headers: {
        'Origin': 'https://k-connect.ru',
        'Referer': 'https://k-connect.ru/',
      });
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to toggle like: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to toggle like: ${e.response?.statusCode ?? 'Network error'}');
    }
  }

  Future<void> playTrack(int trackId) async {
    try {
      await _client.post('/api/music/$trackId/play', {});
    } catch (e) {
      // Ошбика
    }
  }

  Future<Map<String, dynamic>?> nextTrack(int currentId, String context) async {
    try {
      final res = await _client.get('/api/music/next', queryParameters: {
        'current_id': currentId,
        'context': context,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data['track'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // Ошибка
    }
    return null;
  }

  Future<Map<String, dynamic>?> previousTrack(int currentId, String context) async {
    try {
      final res = await _client.get('/api/music/previous', queryParameters: {
        'current_id': currentId,
        'context': context,
      });
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        return data['track'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // Ошибка
    }
    return null;
  }

  Future<List<Track>> searchTracks(String query, {CancelToken? cancelToken}) async {
    try {
      final res = await _client.get('/api/music/search', queryParameters: {'query': query}, cancelToken: cancelToken);
      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.map((trackJson) => Track.fromJson(trackJson as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to search tracks: ${res.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('Search cancelled');
      }
      throw Exception('Failed to search tracks: ${e.response?.statusCode ?? 'Network error'}');
    }
  }
}
