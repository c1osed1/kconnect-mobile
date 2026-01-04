import 'package:equatable/equatable.dart';

/// Модель данных музыкального трека
///
/// Представляет музыкальный трек со всей необходимой информацией
/// для воспроизведения и отображения в интерфейсе.
class Track extends Equatable {
  /// Уникальный идентификатор трека
  final int id;

  /// Название трека
  final String title;

  /// Исполнитель трека
  final String artist;

  /// Путь к обложке альбома (опционально)
  final String? coverPath;

  /// Путь к аудио файлу
  final String filePath;

  /// Длительность трека в миллисекундах
  final int durationMs;

  /// Жанр музыки (опционально)
  final String? genre;

  /// Флаг верификации трека
  final bool verified;

  /// Количество лайков трека
  final int likesCount;

  /// Количество прослушиваний трека
  final int playsCount;

  /// Флаг, поставил ли текущий пользователь лайк
  final bool isLiked;

  /// Контекст трека: 'popular', 'favorites', 'vibe', 'search' и т.д.
  final String? context;

  /// Тренд трека: 'up', 'down' или null
  final String? trend;

  /// Процент изменения (для популярных треков)
  final double? changePercent;

  /// Изменение позиции в чарте
  final int? positionChange;

  /// Текущие прослушивания
  final int? currentPlays;

  /// Предыдущие прослушивания
  final int? previousPlays;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.coverPath,
    required this.filePath,
    required this.durationMs,
    this.genre,
    this.verified = false,
    this.likesCount = 0,
    this.playsCount = 0,
    this.isLiked = false,
    this.context,
    this.trend,
    this.changePercent,
    this.positionChange,
    this.currentPlays,
    this.previousPlays,
  });

  // Create from API JSON response
  factory Track.fromJson(Map<String, dynamic> json) {
    // API returns duration in seconds, convert to milliseconds
    final durationSeconds = json['duration'] as int? ?? 0;
    final durationMs = durationSeconds * 1000;

    // Parse trend data if available
    String? trend;
    double? changePercent;
    int? positionChange;
    int? currentPlays;
    int? previousPlays;

    if (json['trend'] != null) {
      trend = json['trend'] as String?;
    }

    if (json['trend_data'] is Map<String, dynamic>) {
      final trendData = json['trend_data'] as Map<String, dynamic>;
      changePercent = (trendData['change_percent'] as num?)?.toDouble();
      positionChange = trendData['position_change'] as int?;
      currentPlays = trendData['current_plays'] as int?;
      previousPlays = trendData['previous_plays'] as int?;
    }

    return Track(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown Track',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      coverPath: json['cover_path'] as String?,
      filePath: json['file_path'] as String,
      durationMs: durationMs,
      genre: json['genre'] as String?,
      verified: json['verified'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      playsCount: json['plays_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      context: json['context'] as String?,
      trend: trend,
      changePercent: changePercent,
      positionChange: positionChange,
      currentPlays: currentPlays,
      previousPlays: previousPlays,
    );
  }

  // Create from legacy Map<String, dynamic> format
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track.fromJson(map);
  }

  // Convert to JSON for caching/storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'cover_path': coverPath,
      'file_path': filePath,
      'durationMs': durationMs,
      'genre': genre,
      'verified': verified,
      'likes_count': likesCount,
      'plays_count': playsCount,
      'is_liked': isLiked,
      'context': context,
      'trend': trend,
      'change_percent': changePercent,
      'position_change': positionChange,
      'current_plays': currentPlays,
      'previous_plays': previousPlays,
    };
  }

  Track copyWith({
    int? id,
    String? title,
    String? artist,
    String? coverPath,
    String? filePath,
    int? durationMs,
    String? genre,
    bool? verified,
    int? likesCount,
    int? playsCount,
    bool? isLiked,
    String? context,
    String? trend,
    double? changePercent,
    int? positionChange,
    int? currentPlays,
    int? previousPlays,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverPath: coverPath ?? this.coverPath,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      genre: genre ?? this.genre,
      verified: verified ?? this.verified,
      likesCount: likesCount ?? this.likesCount,
      playsCount: playsCount ?? this.playsCount,
      isLiked: isLiked ?? this.isLiked,
      context: context ?? this.context,
      trend: trend ?? this.trend,
      changePercent: changePercent ?? this.changePercent,
      positionChange: positionChange ?? this.positionChange,
      currentPlays: currentPlays ?? this.currentPlays,
      previousPlays: previousPlays ?? this.previousPlays,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    coverPath,
    filePath,
    durationMs,
    genre,
    verified,
    likesCount,
    playsCount,
    isLiked,
    context,
    trend,
    changePercent,
    positionChange,
    currentPlays,
    previousPlays,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
