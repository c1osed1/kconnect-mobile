/// Виджет для отображения изображений с авторизацией
///
/// Обертка вокруг CachedNetworkImage, которая автоматически добавляет
/// заголовки аутентификации для URL-адресов K-Connect.
/// Поддерживает кэширование изображений с проверкой необходимости авторизации.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/api_client/dio_client.dart';
import '../utils/image_utils.dart';

/// Виджет для отображения изображений с автоматической авторизацией
///
/// Обертка вокруг CachedNetworkImage, которая автоматически добавляет
/// заголовки аутентификации для URL-адресов K-Connect.
/// Проверяет необходимость авторизации на основе URL изображения.
class AuthorizedCachedNetworkImage extends StatelessWidget {
  /// URL изображения для загрузки
  final String imageUrl;

  /// Ширина изображения
  final double? width;

  /// Высота изображения
  final double? height;

  /// Режим подгонки изображения (fit)
  final BoxFit? fit;

  /// Качество фильтрации изображения
  final FilterQuality filterQuality;

  /// Ширина изображения в памяти для кэширования
  final int? memCacheWidth;

  /// Высота изображения в памяти для кэширования
  final int? memCacheHeight;

  /// Виджет-заполнитель во время загрузки
  final Widget Function(BuildContext, String)? placeholder;

  /// Виджет при ошибке загрузки
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  /// Флаг использования старого изображения при изменении URL
  final bool useOldImageOnUrlChange;

  /// Выравнивание изображения
  final Alignment alignment;

  /// Конструктор виджета авторизованного изображения
  const AuthorizedCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.filterQuality = FilterQuality.medium,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.useOldImageOnUrlChange = false,
    this.alignment = Alignment.center,
  });

  /// Построение виджета авторизованного изображения
  ///
  /// Проверяет необходимость авторизации и либо использует CachedNetworkImage
  /// с заголовками аутентификации, либо обычный CachedNetworkImage.
  @override
  Widget build(BuildContext context) {
    final requiresAuth = ImageUtils.requiresAuth(imageUrl);

    if (requiresAuth) {
      return FutureBuilder<Map<String, String>>(
        future: DioClient().getImageAuthHeaders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            final placeholderWidget = placeholder != null
                ? placeholder!(context, imageUrl)
                : const CupertinoActivityIndicator(radius: 10);
            return Container(
              width: width,
              height: height,
              color: CupertinoColors.systemGrey6,
              child: placeholderWidget,
            );
          }

          final headers = snapshot.hasData ? snapshot.data! : <String, String>{};

          return CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            httpHeaders: headers,
            placeholder: placeholder,
            errorWidget: errorWidget ??
                (context, url, error) => Container(
                  width: width,
                  height: height,
                  color: CupertinoColors.systemGrey6,
                  child: const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
            useOldImageOnUrlChange: useOldImageOnUrlChange,
            alignment: alignment,
          );
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        filterQuality: filterQuality,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: placeholder,
        errorWidget: errorWidget ??
            (context, url, error) => Container(
              width: width,
              height: height,
              color: CupertinoColors.systemGrey6,
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemGrey,
              ),
            ),
        useOldImageOnUrlChange: useOldImageOnUrlChange,
        alignment: alignment,
      );
    }
  }
}
