/// Реализация репозитория музыки с кэшированием и локальным хранением
///
/// Управляет загрузкой музыкального контента, кэшированием и историей прослушиваний.
/// Предоставляет унифицированный интерфейс для работы с музыкальными данными.
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../services/music_service.dart';
import '../../../../services/storage_service.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/models/track.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/artist.dart';

/// Реализация музыкального репозитория
class MusicRepositoryImpl implements MusicRepository {
  final MusicService _musicService;

  MusicRepositoryImpl(this._musicService);

  @override
  Future<PaginatedResponse<Track>> fetchFavorites({int page = 1, int perPage = 20}) async {
    return await _musicService.fetchFavorites(page: page, perPage: perPage);
  }

  @override
  Future<List<Track>> fetchPopularTracks() async {
    return await _musicService.fetchPopularTracks();
  }

  @override
  Future<List<Track>> fetchNewTracks() async {
    return await _musicService.fetchNewTracks();
  }

  @override
  Future<List<Artist>> fetchRecommendedArtists() async {
    return await _musicService.fetchRecommendedArtists();
  }

  @override
  Future<PaginatedResponse<Playlist>> fetchMyPlaylists({int page = 1, int perPage = 20}) async {
    return await _musicService.fetchMyPlaylists(page: page, perPage: perPage);
  }

  @override
  Future<PaginatedResponse<Playlist>> fetchPublicPlaylists({int page = 1, int perPage = 20}) async {
    return await _musicService.fetchPublicPlaylists(page: page, perPage: perPage);
  }

  @override
  Future<Map<String, List<Track>>> fetchCharts() async {
    return await _musicService.fetchCharts();
  }

  @override
  Future<List<Track>> fetchMyVibe() async {
    return await _musicService.fetchMyVibe();
  }

  @override
  Future<List<Track>> generateVibe() async {
    return await _musicService.generateVibe();
  }

  @override
  Future<List<Track>> fetchTracksPage(String context, int page, {int perPage = 20}) async {
    switch (context) {
      case 'favorites':
        final response = await fetchFavorites(page: page, perPage: perPage);
        return response.items;
      case 'allTracks':
        final response = await fetchAllTracksPaginated(page: page, perPage: perPage);
        return response.items;
      case 'vibe':
        // For vibe, generate new batch
        return await generateVibe();
      default:
        throw UnsupportedError('Unknown context: $context');
    }
  }

  @override
  Future<List<Track>> fetchAllTracks({int page = 1, int limit = 50}) async {
    return await _musicService.fetchAllTracks(page: page, limit: limit);
  }

  @override
  Future<PaginatedResponse<Track>> fetchAllTracksPaginated({int page = 1, int perPage = 50}) async {
    return await _musicService.fetchAllTracksPaginated(page: page, perPage: perPage);
  }

  @override
  Future<void> toggleLikeTrack(int trackId) async {
    await _musicService.toggleLikeTrack(trackId.toString());
  }

  @override
  Future<void> incrementPlayCount(int trackId) async {
    await _musicService.playTrack(trackId);
  }

  @override
  Future<Track?> getNextTrack(int currentTrackId, String context) async {
    final jsonTrack = await _musicService.nextTrack(currentTrackId, context);
    return jsonTrack != null ? Track.fromJson(jsonTrack) : null;
  }

  @override
  Future<Track?> getPreviousTrack(int currentTrackId, String context) async {
    final jsonTrack = await _musicService.previousTrack(currentTrackId, context);
    return jsonTrack != null ? Track.fromJson(jsonTrack) : null;
  }

  @override
  Future<List<Track>> searchTracks(String query, {CancelToken? cancelToken}) async {
    return await _musicService.searchTracks(query, cancelToken: cancelToken);
  }

  @override
  Future<void> savePlayedTrackToHistory(String userId, Track track) async {
    final trackJson = jsonEncode(track.toJson());
    await StorageService.addToMusicPlayedTracksHistory(userId, trackJson);
  }

  @override
  Future<List<Track>> getPlayedTracksHistory(String userId) async {
    final historyJson = await StorageService.getMusicPlayedTracksHistory(userId);
    return historyJson.map((jsonStr) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return Track.fromJson(jsonMap);
      } catch (e) {
        // Skip invalid tracks
        return null;
      }
    }).where((track) => track != null).cast<Track>().toList();
  }

  @override
  Future<void> clearPlayedTracksHistory(String userId) async {
    await StorageService.clearMusicPlayedTracksHistory(userId);
  }
}
