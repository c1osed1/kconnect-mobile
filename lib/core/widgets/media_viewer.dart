/// Просмотрщик медиа-контента
///
/// Виджет для просмотра галереи изображений и видео.
/// Поддерживает зум, панорамирование, полноэкранный режим.
/// Включает элементы управления видео и навигацию между элементами.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_text_styles.dart';
import '../media_item.dart';

/// Виджет для просмотра медиа-галереи
///
/// Позволяет просматривать изображения и видео в полноэкранном режиме
/// с поддержкой зума, панорамирования и навигации между элементами.
class MediaViewer extends StatefulWidget {
  /// Список медиа-элементов для просмотра
  final List<MediaItem> items;

  /// Индекс начального элемента для отображения
  final int initialIndex;

  /// Конструктор просмотрщика медиа
  const MediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

/// Состояние виджета MediaViewer
class _MediaViewerState extends State<MediaViewer> {
  /// Текущий индекс отображаемого элемента
  late int _currentIndex;

  /// Контроллеры Chewie для видео-плееров
  final Map<int, ChewieController?> _chewieControllers = {};

  /// Контроллеры VideoPlayer для видео
  final Map<int, VideoPlayerController?> _videoControllers = {};

  /// Набор индексов видео, которые не удалось загрузить
  final Set<int> _failedVideoIndices = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    if (widget.items.isNotEmpty && widget.items[_currentIndex].isVideo) {
      _initializeVideo(_currentIndex);
    }
  }

  @override
  void dispose() {
    _chewieControllers.values.where((c) => c != null).forEach((c) => c!.dispose());
    _videoControllers.values.where((c) => c != null).forEach((c) => c!.dispose());

    super.dispose();
  }

  /// Инициализация видео-контроллера для указанного индекса
  ///
  /// Создает VideoPlayerController и ChewieController для видео.
  /// Обрабатывает ошибки загрузки и помечает неудачные загрузки.
  void _initializeVideo(int index) async {
    if (!_videoControllers.containsKey(index) && widget.items[index].isVideo) {
      final item = widget.items[index];

      try {
        final uri = Uri.parse(item.url);
        final videoController = VideoPlayerController.networkUrl(uri);
        _videoControllers[index] = videoController;

        await videoController.initialize();

        if (mounted) {
          final chewieController = ChewieController(
            videoPlayerController: videoController,
            autoPlay: false,
            looping: false,
            showControls: true,
            aspectRatio: videoController.value.aspectRatio,
            placeholder: const SizedBox.shrink(),
            errorBuilder: (_, _) => const Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemGrey,
                size: 48,
              ),
            ),
          );
          _chewieControllers[index] = chewieController;
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          _failedVideoIndices.add(index);
          setState(() {});
        }
      }
    }
  }

  /// Обработчик изменения страницы в галерее
  ///
  /// Обновляет текущий индекс, останавливает предыдущие видео
  /// и инициализирует видео для текущей страницы.
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pauseAllVideos();
    if (widget.items[index].isVideo) {
      if (_chewieControllers[index] == null) {
        _initializeVideo(index);
      } else {
        _videoControllers[index]?.play();
      }
    }
    final nextIndex = index + 1;
    if (nextIndex < widget.items.length && widget.items[nextIndex].isVideo && !_videoControllers.containsKey(nextIndex)) {
      _initializeVideo(nextIndex);
    }
  }

  /// Останавливает все активные видео
  void _pauseAllVideos() {
    for (final controller in _videoControllers.values) {
      controller?.pause();
    }
  }

  /// Создает виджет для отображения видео-элемента
  ///
  /// Возвращает Chewie плеер для загруженного видео или
  /// заполнители для состояний загрузки/ошибки.
  Widget _buildVideoItem(MediaItem item, int index) {
    if (_failedVideoIndices.contains(index)) {
      // Не удалось загрузить видео
      return const Center(
        child: Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.systemGrey,
          size: 48,
        ),
      );
    }

    final chewieController = _chewieControllers[index];
    if (chewieController != null) {
      return Chewie(controller: chewieController);
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (item.posterUrl != null)
            CachedNetworkImage(
              imageUrl: item.posterUrl!,
              fit: BoxFit.contain,
              placeholder: (_, _) => const Center(
                child: CupertinoActivityIndicator(),
              ),
              errorWidget: (_, _, _) => Container(
                color: CupertinoColors.black,
              ),
            ),
          if (item.posterUrl == null)
            const Center(
              child: CupertinoActivityIndicator(),
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = widget.items[_currentIndex];

    return Container(
      color: CupertinoColors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PhotoViewGallery
            PhotoViewGallery.builder(
              itemCount: widget.items.length,
              pageController: PageController(initialPage: widget.initialIndex),
              builder: (context, index) {
                final mediaItem = widget.items[index];

                if (mediaItem.isImage) {
                  // Пользовательская обработка изображений с резервом при ошибке
                  return PhotoViewGalleryPageOptions.customChild(
                    child: CachedNetworkImage(
                      imageUrl: mediaItem.url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      errorWidget: (context, url, error) {
                        // Проверяем, является ли это ошибкой 403 или другой, показываем плейсхолдер аватара
                        if (mediaItem.url.contains('/avatar/')) {
                          return CachedNetworkImage(
                            imageUrl: 'https://k-connect.ru/static/uploads/system/album_placeholder.jpg',
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CupertinoActivityIndicator(),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: CupertinoColors.black,
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.photo,
                                  color: CupertinoColors.systemGrey,
                                  size: 48,
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Для других ошибок изображений показываем общую ошибку
                          return Container(
                            color: CupertinoColors.black,
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: CupertinoColors.systemGrey,
                                size: 48,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4.0,
                    initialScale: PhotoViewComputedScale.contained,
                  );
                } else {
                  // Пользовательский дочерний элемент для видео
                  return PhotoViewGalleryPageOptions.customChild(
                    child: _buildVideoItem(mediaItem, index),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained,
                    initialScale: PhotoViewComputedScale.contained,
                  );
                }
              },
              onPageChanged: _onPageChanged,
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: CupertinoColors.black,
              ),
              loadingBuilder: (context, event) => const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),

            // Оверлей: Кнопка назад и счетчик
            Positioned(
              top: 20,
              left: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),

            // Счетчик
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.items.length}',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (item.isVideo && _videoControllers[_currentIndex]?.value.isInitialized == false)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    'Нажмите для воспроизведения',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
