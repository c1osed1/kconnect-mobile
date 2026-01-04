// Карточка исполнителя для отображения в горизонтальных списках
//
// Отображает аватар исполнителя, имя, и статус верификации.
// Поддерживает различные действия: навигация к профилю исполнителя.
// Используется в секциях музыки для показа рекомендованных исполнителей.
// Карточка артиста квадратная с закругленными углами
library;

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/theme_extensions.dart';
import '../domain/models/artist.dart';

/// Виджет карточки исполнителя с аватаром и информацией
///
/// Показывает исполнителя в компактном формате с аватаром,
/// именем и дополнительными элементами (верификация).
class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: artist.avatarUrl.isNotEmpty
                        ? ImageUtils.getCompleteImageUrl(artist.avatarUrl) ?? ''
                        : '',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 140,
                      height: 140,
                      color: AppColors.bgCard,
                      child: const CupertinoActivityIndicator(radius: 15),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 140,
                      height: 140,
                      color: AppColors.bgCard,
                      child: const Icon(
                        CupertinoIcons.person,
                        size: 70,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.9),
                        const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.5),
                        const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.2, 0.4],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          artist.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      if (artist.verified)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.dynamicPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 8,
                            color: AppColors.bgWhite,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
