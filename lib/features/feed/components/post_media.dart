/// Компонент для отображения медиа-контента постов
///
/// Поддерживает отображение изображений и видео в различных сетках:
/// одиночное изображение, сетка 2x2, 3xN для большего количества.
/// Автоматически рассчитывает размеры и пропорции.
library;

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import 'post_constants.dart';

/// Компонент медиа поста (изображения и видео)
class PostMedia extends StatelessWidget {
  final List<String>? images;
  final String? singleImage;
  final String? videoUrl;
  final String? videoPoster;
  final bool isFullWidth;
  final ValueChanged<int>? onMediaTap;

  const PostMedia({
    super.key,
    this.images,
    this.singleImage,
    this.videoUrl,
    this.videoPoster,
    this.isFullWidth = true,
    this.onMediaTap,
  });


  List<String> get _allMediaUrls {
    final List<String> urls = [];

    if (images != null && images!.isNotEmpty) {
      urls.addAll(images!);
    } else if (singleImage != null && singleImage!.isNotEmpty) {
      urls.add(singleImage!);
    }

    if (videoUrl != null && videoUrl!.isNotEmpty) {
      if (videoPoster != null && videoPoster!.isNotEmpty) {
        urls.add(videoPoster!);
      } else {
        urls.add('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4gIDxyZWN0IHdpZHRoPSI0MDAiIGhlaWdodD0iMzAwIiBmaWxsPSIjMDAwMDAwIi8+ICA8Y2lyY2xlIGN4PSIyMDAiIGN5PSIxNTAiIHI9IjUwIiBmaWxsPSIjZmZmZmZmIi8+ICA8dGV4dCB4PSIyMDAiIHk9IjI2MCIgZmlsbD0iI2ZmZmZmZiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1zaXplPSIxOCI+VmlkZW88L3RleHQ+IDwvc3ZnPg==');
      }
    }

    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _allMediaUrls;

    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = PostConstants.cardHorizontalPadding * 2;
    final availableWidth = screenWidth - cardPadding;
    final containerWidth = isFullWidth ? availableWidth : availableWidth - PostConstants.cardHorizontalPadding * 2;

    return _buildImagesGrid(context, urls, containerWidth, 4.0);
  }



  Widget _buildImagesGrid(BuildContext context, List<String> imageUrls, double containerWidth, double spacing) {
    final int imageCount = imageUrls.length;

    if (imageCount == 1) {
      // 1 изображение/видео
      return GestureDetector(
        onTap: onMediaTap != null ? () => onMediaTap!(0) : null,
        child: Container(
          height: containerWidth,
          width: containerWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PostConstants.borderRadius),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(PostConstants.borderRadius),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[0],
                  width: containerWidth,
                  height: containerWidth,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  placeholder: (context, url) => const CupertinoActivityIndicator(radius: 10),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.bgCard,
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ),
              ),
              // Кнопка play
              if (videoUrl != null && videoUrl!.isNotEmpty && videoPoster != null && imageUrls[0] == videoPoster)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        color: AppColors.bgWhite,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Расчет размеров для сетки
    int maxPerRow = imageCount <= 4 ? 2 : 3;
    double imageSize = (containerWidth - (maxPerRow - 1) * spacing) / maxPerRow;

    List<List<String>> rows = [];
    for (int i = 0; i < imageCount; i += maxPerRow) {
      int end = (i + maxPerRow > imageCount) ? imageCount : i + maxPerRow;
      rows.add(imageUrls.sublist(i, end));
    }

    return Column(
      children: rows.asMap().entries.map((rowEntry) {
        final rowIndex = rowEntry.key;
        final rowImages = rowEntry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows.length - 1 ? spacing : 0),
          child: Row(
            children: rowImages.asMap().entries.map((imageEntry) {
              final imageIndex = imageEntry.key;
              final imageUrl = imageEntry.value;
              final globalIndex = rows.take(rowIndex).fold(0, (sum, row) => sum + row.length) + imageIndex;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: imageIndex < rowImages.length - 1 ? spacing : 0),
                  child: GestureDetector(
                    onTap: onMediaTap != null ? () {
                      onMediaTap!(globalIndex);
                    } : null,
                    child: Container(
                      height: imageSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(PostConstants.borderRadius),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(PostConstants.borderRadius),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          placeholder: (context, url) => const CupertinoActivityIndicator(radius: 10),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.bgCard,
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
