import 'package:dio/dio.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/artist.dart';

/// Интерфейс репозитория для музыкального контента
///
/// Определяет контракт для работы с музыкальными треками, плейлистами,
/// поиском и управлением очередью воспроизведения.
abstract class MusicRepository {
  // Fetch collections
  Future<PaginatedResponse<Track>> fetchFavorites({int page = 1, int perPage = 20});
  Future<List<Track>> fetchPopularTracks();
  Future<List<Track>> fetchNewTracks();
  Future<List<Artist>> fetchRecommendedArtists();
  Future<PaginatedResponse<Playlist>> fetchMyPlaylists({int page = 1, int perPage = 20});
  Future<PaginatedResponse<Playlist>> fetchPublicPlaylists({int page = 1, int perPage = 20});

  // Charts and collections
  Future<Map<String, List<Track>>> fetchCharts();
  Future<List<Track>> fetchMyVibe();
  Future<List<Track>> generateVibe();

  // Unified page fetching for queues
  Future<List<Track>> fetchTracksPage(String context, int page, {int perPage = 20});

  // Paginated fetching
  Future<List<Track>> fetchAllTracks({int page = 1, int limit = 50});
  Future<PaginatedResponse<Track>> fetchAllTracksPaginated({int page = 1, int perPage = 20});

  // Track actions
  Future<void> toggleLikeTrack(int trackId);
  Future<void> incrementPlayCount(int trackId);

  // Search functionality
  Future<List<Track>> searchTracks(String query, {CancelToken? cancelToken});

  // Played tracks history management
  Future<void> savePlayedTrackToHistory(String userId, Track track);
  Future<List<Track>> getPlayedTracksHistory(String userId);
  Future<void> clearPlayedTracksHistory(String userId);

  // Queue navigation
  Future<Track?> getNextTrack(int currentTrackId, String context);
  Future<Track?> getPreviousTrack(int currentTrackId, String context);
}
