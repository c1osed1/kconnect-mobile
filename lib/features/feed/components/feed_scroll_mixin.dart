/// Mixin для управления скроллом в экране ленты
///
/// Предоставляет функциональность для обработки скролла, показа кнопки "наверх"
/// и автоматической подгрузки контента при достижении нижнего края экрана.
library;

import 'package:flutter/material.dart';
import '../feed_screen.dart';
import '../presentation/blocs/feed_event.dart';
import '../presentation/blocs/feed_bloc.dart';
import '../presentation/blocs/feed_state.dart';
import 'post_constants.dart';

/// Mixin для управления скроллом в FeedScreen
mixin FeedScrollMixin<T extends StatefulWidget> on State<T> {
  FeedBloc get feedBloc;
  ScrollController get scrollController;
  ValueNotifier<bool> get showScrollToTop;

  void initScrollListeners() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

    final pixels = scrollController.position.pixels;
    final maxScrollExtent = scrollController.position.maxScrollExtent;

    // Управление видимостью кнопки "наверх"
    final shouldShowFloating = pixels > PostConstants.scrollToTopThreshold;
    if (showScrollToTop.value != shouldShowFloating) {
      showScrollToTop.value = shouldShowFloating;
    }

    // Логика смены иконки в MainTabs: стрелка вверх после 100px скролла, add при возврате наверх
    final scrolledDown = pixels > 400;
    if (widget is FeedScreen) {
      (widget as FeedScreen).onScrollChanged(scrolledDown);
    }

    if (_isNearBottom(pixels, maxScrollExtent) && _canLoadMore) {
      feedBloc.add(FetchPostsEvent());
    }
  }

  bool _isNearBottom(double pixels, double maxScrollExtent) {
    return pixels >= maxScrollExtent - PostConstants.loadMoreThreshold;
  }

  bool get _canLoadMore => feedBloc.state.hasNext && feedBloc.state.paginationStatus != PaginationStatus.loading && feedBloc.state.paginationStatus != PaginationStatus.failed;

  void scrollToTop({Duration duration = const Duration(milliseconds: 300)}) {
    scrollController.animateTo(
      0,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  void scrollToPosition(double position, {Duration duration = const Duration(milliseconds: 300)}) {
    scrollController.animateTo(
      position,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    super.dispose();
  }
}
