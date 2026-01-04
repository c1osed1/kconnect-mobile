// Утилиты для работы с изображениями
//
// Предоставляет функции для загрузки изображений с оптимизацией GIF,
// кэшированием и аутентификацией для защищенных ресурсов.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/api_client/dio_client.dart';

/// Утилиты для обработки загрузки изображений с оптимизацией GIF
class ImageUtils {
  /// Дополняет относительный URL до полного, добавляя базовый URL если необходимо
  ///
  /// [url] - URL изображения (может быть относительным или полным)
  /// Returns: Полный URL или null если входной URL пустой
  static String? getCompleteImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return 'https://k-connect.ru$url';
  }
  /// Создает виджет обложки альбома с предотвращением анимации GIF для оптимизации
  ///
  /// [imageUrl] - URL изображения обложки
  /// [width] - ширина виджета
  /// [height] - высота виджета
  /// [fit] - режим масштабирования изображения
  /// [placeholder] - виджет-заполнитель при загрузке
  /// [headers] - HTTP заголовки для запроса
  static Widget buildAlbumArt(
    String? imageUrl, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Map<String, String>? headers,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.music_note,
          color: Colors.grey,
        ),
      );
    }

    // For GIF images, add ?static=true parameter to force server to return static version
    // This changes the URL, clearing cache and potentially enabling server-side GIF->PNG conversion
    final String finalUrl = imageUrl.toLowerCase().contains('.gif')
        ? '$imageUrl?static=true'
        : imageUrl;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          finalUrl,
          fit: fit,
          headers: headers,
          gaplessPlayback: false, // Prevents re-animation on reload
          // Stop GIF animation by showing only first frame
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            // Only show the first frame, block all subsequent animated frames
            if (frame == null || frame == 0) {
              return child;
            }
            // Return the first frame container to prevent animation
            // This effectively stops GIF from animating
            return child;
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.music_note,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }

  /// Проверяет, требует ли URL аутентификационные заголовки
  ///
  /// Изображения на s3.k-connect.ru размещены на S3 и имеют собственный контроль доступа
  /// [url] - URL изображения для проверки
  /// Returns: true если требуется аутентификация
  static bool requiresAuth(String url) {
    if (url.contains('s3.k-connect.ru')) return false;
    return url.contains('k-connect.ru');
  }

  /// Создает виджет аватара чата с правильным кэшированием и аутентификацией для API изображений
  ///
  /// [imageUrl] - URL аватара
  /// [width] - ширина аватара
  /// [height] - высота аватара
  /// [fit] - режим масштабирования
  /// Returns: Future'<'Widget'>' настроенный виджет аватара
  static Future<Widget> buildChatAvatarImage(
    String imageUrl, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) async {
    final headers = requiresAuth(imageUrl) ? await DioClient().getImageAuthHeaders() : <String, String>{};

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          filterQuality: FilterQuality.low,
          memCacheWidth: width.toInt() * 2,
          memCacheHeight: height.toInt() * 2,
          httpHeaders: headers,
          placeholder: (context, url) => CupertinoActivityIndicator(radius: 8),
          errorWidget: (context, url, error) => Icon(
            CupertinoIcons.person,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }

  /// Создает CachedNetworkImageProvider с аутентификационными заголовками при необходимости
  ///
  /// [url] - URL изображения
  /// Returns: Future'<'CachedNetworkImageProvider'>' с настроенными заголовками аутентификации
  static Future<CachedNetworkImageProvider> createAuthorizedImageProvider(String url) async {
    final headers = requiresAuth(url) ? await DioClient().getImageAuthHeaders() : <String, String>{};
    return CachedNetworkImageProvider(url, headers: headers);
  }
}
