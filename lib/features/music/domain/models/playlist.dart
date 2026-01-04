import 'package:equatable/equatable.dart';

/// Модель плейлиста музыкальных треков
///
/// Представляет плейлист с информацией о владельце, треках и метаданных.
/// Поддерживает как пользовательские плейлисты, так и системные коллекции.
/// Используется для отображения и управления музыкальными коллекциями.
class Playlist extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String coverImage;
  final String coverUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlaylistOwner owner;
  final List<PlaylistTrackPreview> previewTracks;
  final int tracksCount;
  final bool isOwner;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.coverImage,
    required this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    required this.previewTracks,
    required this.tracksCount,
    required this.isOwner,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String,
      coverUrl: json['cover_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      owner: PlaylistOwner.fromJson(json['owner'] as Map<String, dynamic>),
      previewTracks: (json['preview_tracks'] as List<dynamic>?)
          ?.map((track) => PlaylistTrackPreview.fromJson(track as Map<String, dynamic>))
          .toList() ?? [],
      tracksCount: json['tracks_count'] as int,
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, coverImage, tracksCount, isOwner];
}

class PlaylistOwner extends Equatable {
  final int id;
  final String name;
  final String username;
  final String avatarUrl;

  const PlaylistOwner({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
  });

  factory PlaylistOwner.fromJson(Map<String, dynamic> json) {
    return PlaylistOwner(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String,
    );
  }

  @override
  List<Object?> get props => [id, username];
}

class PlaylistTrackPreview extends Equatable {
  final String artist;
  final String title;

  const PlaylistTrackPreview({
    required this.artist,
    required this.title,
  });

  factory PlaylistTrackPreview.fromJson(Map<String, dynamic> json) {
    return PlaylistTrackPreview(
      artist: json['artist'] as String,
      title: json['title'] as String,
    );
  }

  @override
  List<Object?> get props => [artist, title];
}

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFactory,
    String itemsKey,
  ) {
    final items = (json[itemsKey] as List<dynamic>?)
        ?.map((item) => itemFactory(item as Map<String, dynamic>))
        .toList() ?? [];

    final currentPage = json['current_page'] as int? ?? 1;
    final totalPages = json['pages'] as int? ?? 1;
    final totalItems = json['total'] as int? ?? items.length;

    return PaginatedResponse(
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNextPage: currentPage < totalPages,
    );
  }
}
