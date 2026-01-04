/// Компонент фонового изображения профиля
///
/// Отображает баннер профиля пользователя с авторизацией.
/// Использует DioClient для получения заголовков аутентификации.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_client/dio_client.dart';

/// Виджет фонового изображения профиля
///
/// Показывает баннер профиля с поддержкой аутентифицированной загрузки.
/// Используется в заголовке профиля для отображения фонового изображения.
class ProfileBackground extends StatelessWidget {
  final String? backgroundUrl;

  const ProfileBackground({
    super.key,
    required this.backgroundUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundUrl == null) {
      return const SizedBox();
    }

    return FutureBuilder<Map<String, String>>(
      future: DioClient().getImageAuthHeaders(),
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                backgroundUrl!,
                headers: snapshot.data,
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
