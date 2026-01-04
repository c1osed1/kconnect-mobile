/// Состояние ленты новостей
///
/// Определяет структуру состояния FeedBloc, включая посты, комментарии,
/// онлайн-пользователей, статусы загрузки и состояния обработки лайков.
library;

import 'package:equatable/equatable.dart';
import '../../domain/models/post.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/online_user.dart';

/// Статусы загрузки ленты новостей
enum FeedStatus {
  initial,
  loading,
  success,
  failure
}

/// Статусы загрузки комментариев
enum CommentsStatus {
  initial,
  loading,
  success,
  failure
}

/// Статусы пагинации
enum PaginationStatus {
  idle,
  loading,
  failed
}

/// Состояние FeedBloc
///
/// Содержит все данные и статусы для управления UI ленты новостей,
/// включая посты, комментарии, онлайн-пользователей и состояния загрузки.
class FeedState extends Equatable {

  final FeedStatus status;
  final List<Post> posts;
  final List<OnlineUser> onlineUsers;
  final String? error;
  /// Текущая страница пагинации
  final int page;
  /// Флаг наличия следующей страницы
  final bool hasNext;
  /// Флаг загрузки дополнительных постов
  final bool isLoadingMore;
  final PaginationStatus paginationStatus;
  final bool isRefreshing;

  // Состояние комментариев
  final int? commentsPostId;
  final List<Comment> comments;
  final CommentsStatus commentsStatus;
  /// Флаг наличия следующей страницы комментариев
  final bool commentsHasNext;
  /// Текущая страница комментариев
  final int commentsPage;
  final bool commentsIsLoadingMore;
  final String? commentsError;

  // Состояния обработки лайков
  final Set<int> processingPostLikes;
  final Set<int> processingCommentLikes;

  /// Конструктор состояния ленты новостей
  const FeedState({
    this.status = FeedStatus.initial,
    this.posts = const [],
    this.onlineUsers = const [],
    this.error,
    this.page = 1,
    this.hasNext = true,
    this.isLoadingMore = false,
    this.paginationStatus = PaginationStatus.idle,
    this.isRefreshing = false,
    this.commentsPostId,
    this.comments = const [],
    this.commentsStatus = CommentsStatus.initial,
    this.commentsHasNext = true,
    this.commentsPage = 1,
    this.commentsIsLoadingMore = false,
    this.commentsError,
    this.processingPostLikes = const {},
    this.processingCommentLikes = const {},
  });

  /// Создает копию состояния с измененными полями
  ///
  /// Используется для иммутабельных обновлений состояния в BLoC паттерне.
  /// Null значения означают, что поле не нужно изменять.
  FeedState copyWith({
    FeedStatus? status,
    List<Post>? posts,
    List<OnlineUser>? onlineUsers,
    String? error,
    int? page,
    bool? hasNext,
    bool? isLoadingMore,
    PaginationStatus? paginationStatus,
    bool? isRefreshing,
    int? commentsPostId,
    List<Comment>? comments,
    CommentsStatus? commentsStatus,
    bool? commentsHasNext,
    int? commentsPage,
    bool? commentsIsLoadingMore,
    String? commentsError,
    Set<int>? processingPostLikes,
    Set<int>? processingCommentLikes,
  }) {
    return FeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      error: error,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      commentsPostId: commentsPostId ?? this.commentsPostId,
      comments: comments ?? this.comments,
      commentsStatus: commentsStatus ?? this.commentsStatus,
      commentsHasNext: commentsHasNext ?? this.commentsHasNext,
      commentsPage: commentsPage ?? this.commentsPage,
      commentsIsLoadingMore: commentsIsLoadingMore ?? this.commentsIsLoadingMore,
      commentsError: commentsError ?? this.commentsError,
      processingPostLikes: processingPostLikes ?? this.processingPostLikes,
      processingCommentLikes: processingCommentLikes ?? this.processingCommentLikes,
    );
  }

  /// Список свойств для сравнения состояний в Equatable
  ///
  /// Определяет, какие поля участвуют в сравнении состояний.
  /// При изменении любого из этих полей состояние считается измененным.
  @override
  List<Object?> get props => [
        status,
        posts,
        onlineUsers,
        error,
        page,
        hasNext,
        isLoadingMore,
        paginationStatus,
        isRefreshing,
        commentsPostId,
        comments,
        commentsStatus,
        commentsHasNext,
        commentsPage,
        commentsIsLoadingMore,
        commentsError,
        processingPostLikes,
        processingCommentLikes,
      ];
}
