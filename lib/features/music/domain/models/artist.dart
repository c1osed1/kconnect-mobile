/// Модель исполнителя для музыкального контента
///
/// Представляет исполнителя с основной информацией для отображения
/// в списках и карточках музыкальных секций.
library;

import 'package:equatable/equatable.dart';

/// Модель исполнителя
class Artist extends Equatable {
  final int id;
  final String name;
  final String avatarUrl;
  final String bio;
  final List<String> genres;
  final int tracksCount;
  final bool verified;

  const Artist({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.genres,
    required this.tracksCount,
    required this.verified,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String,
      bio: json['bio'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>?)
          ?.map((genre) => genre as String)
          .toList() ?? [],
      tracksCount: json['tracks_count'] as int,
      verified: json['verified'] as bool,
    );
  }

  @override
  List<Object?> get props => [id, name, avatarUrl, verified];
}
