import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_state.dart';
import '../../domain/usecases/fetch_posts_usecase.dart';
import '../../domain/models/online_user.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// BLoC для управления состоянием ленты новостей
///
/// Отвечает за загрузку постов, комментариев, обработку лайков,
/// пагинацию и взаимодействие с системой аутентификации.
/// Управляет состоянием UI ленты новостей в реальном времени.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FetchPostsUseCase _fetchPostsUseCase;
  final LikePostUseCase _likePostUseCase;

  final FetchOnlineUsersUseCase _fetchOnlineUsersUseCase;

  final FetchCommentsUseCase _fetchCommentsUseCase;
  final AddCommentUseCase _addCommentUseCase;
  final DeleteCommentUseCase _deleteCommentUseCase;
  final LikeCommentUseCase _likeCommentUseCase;

  /// BLoC аутентификации для отслеживания изменений пользователя
  final AuthBloc _authBloc;

  /// Конструктор FeedBloc
  FeedBloc(
    this._fetchPostsUseCase,
    this._likePostUseCase,
    this._fetchOnlineUsersUseCase,
    this._fetchCommentsUseCase,
    this._addCommentUseCase,
    this._deleteCommentUseCase,
    this._likeCommentUseCase,
    this._authBloc,
  ) : super(const FeedState()) {
    // Подписка на изменения состояния аутентификации для перезагрузки ленты
    _authBloc.stream.listen(_onAuthStateChanged);

    // Регистрация обработчиков событий
    on<InitFeedEvent>(_onInitFeed);
    on<FetchPostsEvent>(_onFetchPosts);
    on<LikePostEvent>(_onLikePost);
    on<FetchOnlineUsersEvent>(_onFetchOnlineUsers);
    on<RefreshFeedEvent>(_onRefreshFeed);
    on<LoadCommentsEvent>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<LikeCommentEvent>(_onLikeComment);
  }

  /// Обработчик изменений состояния аутентификации
  ///
  /// Следит за изменениями пользователя и перезагружает ленту при необходимости.
  /// При смене пользователя перезагружает ленту для отображения актуального контента.
  void _onAuthStateChanged(AuthState authState) {
    debugPrint('FeedBloc: Auth state changed: $authState');

    if (authState is AuthAuthenticated) {
      if (state.posts.isNotEmpty) {
        debugPrint('FeedBloc: Reloading feed for new user');
        add(const InitFeedEvent());
      }
    } else if (authState is AuthUnauthenticated || authState is AuthInitial) {
      debugPrint('FeedBloc: User logged out, clearing feed');
    }
  }

  /// Обработчик инициализации ленты новостей
  ///
  /// Загружает первую страницу постов и список онлайн-пользователей.
  /// При наличии существующих постов показывает индикатор обновления,
  /// иначе полностью сбрасывает состояние.
  Future<void> _onInitFeed(
    InitFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    final hasExistingPosts = state.posts.isNotEmpty;
    if (hasExistingPosts) {
      emit(state.copyWith(
        isRefreshing: true,
        status: FeedStatus.loading,
        error: null,
      ));
    } else {
      emit(const FeedState());
    }

    try {
      final posts = await _fetchPostsUseCase(page: 1);
      emit(state.copyWith(
        posts: posts,
        status: FeedStatus.success,
        page: 1,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      if (hasExistingPosts) {
        emit(state.copyWith(
          status: FeedStatus.success,
          isRefreshing: false,
          error: e.toString(),
        ));
      } else {
        emit(state.copyWith(
          status: FeedStatus.failure,
          isRefreshing: false,
          error: e.toString(),
        ));
      }
    }
    add(FetchOnlineUsersEvent());
  }

  Future<void> _onFetchPosts(
    FetchPostsEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      if (!state.hasNext) return;

      emit(state.copyWith(
        isLoadingMore: state.posts.isNotEmpty,
        status: state.posts.isEmpty ? FeedStatus.loading : state.status,
        paginationStatus: PaginationStatus.loading,
      ));

      final newPosts = await _fetchPostsUseCase(page: state.page + 1);

      if (newPosts.isEmpty) {
        emit(state.copyWith(
          hasNext: false,
          isLoadingMore: false,
          paginationStatus: PaginationStatus.idle,
        ));
        return;
      }

      final allPosts = [...state.posts, ...newPosts];
      final nextPage = state.page + 1;

      emit(state.copyWith(
        posts: allPosts,
        page: nextPage,
        status: FeedStatus.success,
        isLoadingMore: false,
        paginationStatus: PaginationStatus.idle,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: state.posts.isEmpty ? FeedStatus.failure : state.status,
        error: e.toString(),
        isLoadingMore: false,
        paginationStatus: PaginationStatus.failed,
      ));
    }
  }

  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<FeedState> emit,
  ) async {
    if (state.processingPostLikes.contains(event.postId)) {
      return;
    }

    final postIndex = state.posts.indexWhere((post) => post.id == event.postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];

    final processingLikes = {...state.processingPostLikes, event.postId};
    emit(state.copyWith(processingPostLikes: processingLikes));

    try {
      final optimisticPost = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
      final optimisticPosts = state.posts.map((p) => p.id == event.postId ? optimisticPost : p).toList();
      emit(state.copyWith(posts: optimisticPosts));

      final serverPost = await _likePostUseCase(event.postId);

      final serverUpdatedPost = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: serverPost.likesCount,
        dislikesCount: serverPost.dislikesCount,
      );

      final finalPosts = state.posts.map((p) => p.id == event.postId ? serverUpdatedPost : p).toList();

      emit(state.copyWith(
        posts: finalPosts,
        processingPostLikes: state.processingPostLikes.where((id) => id != event.postId).toSet(),
      ));
    } catch (e) {
      final revertedPost = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
      final revertedPosts = state.posts.map((p) => p.id == event.postId ? revertedPost : p).toList();

      emit(state.copyWith(
        posts: revertedPosts,
        processingPostLikes: state.processingPostLikes.where((id) => id != event.postId).toSet(),
      ));
    }
  }

  Future<void> _onFetchOnlineUsers(
    FetchOnlineUsersEvent event,
    Emitter<FeedState> emit,
  ) async {
    if (state.onlineUsers.isNotEmpty) return;

    try {
      final onlineUsersData = await _fetchOnlineUsersUseCase();
      final onlineUsers = onlineUsersData.map((userJson) => OnlineUser.fromJson(userJson)).toList();
      emit(state.copyWith(onlineUsers: onlineUsers));
    } catch (e) {
      //Ошибка
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    final hasExistingPosts = state.posts.isNotEmpty;
    
    if (hasExistingPosts) {
      emit(state.copyWith(
        isRefreshing: true,
        status: FeedStatus.loading,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        status: FeedStatus.loading,
        isRefreshing: false,
        error: null,
      ));
    }

    try {
      final posts = await _fetchPostsUseCase(page: 1);
      final onlineUsersData = await _fetchOnlineUsersUseCase();
      final onlineUsers = onlineUsersData.map((userJson) => OnlineUser.fromJson(userJson)).toList();

      emit(state.copyWith(
        posts: posts,
        onlineUsers: onlineUsers,
        status: FeedStatus.success,
        page: 1,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      if (hasExistingPosts) {
        emit(state.copyWith(
          status: FeedStatus.success,
          isRefreshing: false,
          error: e.toString(),
        ));
      } else {
        emit(state.copyWith(
          status: FeedStatus.failure,
          isRefreshing: false,
          error: e.toString(),
        ));
      }
    }
  }

  Future<void> _onLoadComments(
    LoadCommentsEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      emit(state.copyWith(
        commentsPostId: event.postId,
        comments: [],
        commentsStatus: CommentsStatus.loading,
        commentsPage: 1,
        commentsHasNext: false,
        commentsIsLoadingMore: false,
        commentsError: null,
      ));

      final comments = await _fetchCommentsUseCase(event.postId, page: 1);

      emit(state.copyWith(
        comments: comments,
        commentsPage: 1,
        commentsHasNext: false,
        commentsStatus: CommentsStatus.success,
        commentsIsLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        commentsStatus: CommentsStatus.failure,
        commentsError: e.toString(),
        commentsIsLoadingMore: false,
      ));
    }
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final newComment = await _addCommentUseCase(event.postId, event.content);
      final updatedComments = [newComment, ...state.comments];
      emit(state.copyWith(comments: updatedComments));

      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(commentsCount: post.commentsCount + 1);
        }
        return post;
      }).toList();
      emit(state.copyWith(posts: updatedPosts));
    } catch (e) {
      emit(state.copyWith(
        commentsError: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteComment(
    DeleteCommentEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _deleteCommentUseCase(event.commentId);
      final updatedComments = state.comments.where((c) => c.id != event.commentId).toList();
      emit(state.copyWith(comments: updatedComments));

      // Update post's comments count
      if (state.commentsPostId != null) {
        final updatedPosts = state.posts.map((post) {
          if (post.id == state.commentsPostId) {
            return post.copyWith(commentsCount: post.commentsCount - 1);
          }
          return post;
        }).toList();
        emit(state.copyWith(posts: updatedPosts));
      }
    } catch (e) {
      emit(state.copyWith(
        commentsError: e.toString(),
      ));
    }
  }

  Future<void> _onLikeComment(
    LikeCommentEvent event,
    Emitter<FeedState> emit,
  ) async {
    if (state.processingCommentLikes.contains(event.commentId)) {
      return;
    }

    final processingLikes = {...state.processingCommentLikes, event.commentId};
    emit(state.copyWith(processingCommentLikes: processingLikes));

    try {
      await _likeCommentUseCase(event.commentId);

      final updatedComments = state.comments.map((c) {
        if (c.id == event.commentId) {
          return c.copyWith(
            userLiked: !c.userLiked,
            likesCount: c.userLiked ? c.likesCount - 1 : c.likesCount + 1,
          );
        }
        return c;
      }).toList();

      emit(state.copyWith(
        comments: updatedComments,
        processingCommentLikes: state.processingCommentLikes.where((id) => id != event.commentId).toSet(),
      ));
    } catch (e) {
      emit(state.copyWith(
        processingCommentLikes: state.processingCommentLikes.where((id) => id != event.commentId).toSet(),
      ));
    }
  }
}
