/// Панель онлайн-пользователей
///
/// Отображает список пользователей, находящихся в сети.
/// Показывает аватары пользователей с возможностью навигации к профилю.
/// Ограничивает количество отображаемых пользователей и показывает счетчик.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/authorized_cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../features/profile/utils/profile_navigation_utils.dart';
import '../presentation/blocs/feed_bloc.dart' as bloc;
import '../presentation/blocs/feed_state.dart' as state;

/// Виджет для отображения панели онлайн-пользователей
///
/// Получает список онлайн-пользователей из FeedBloc и отображает их аватары.
/// Поддерживает навигацию к профилю пользователя при нажатии на аватар.
class OnlineUsersBar extends StatelessWidget {
  const OnlineUsersBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<bloc.FeedBloc, state.FeedState>(
      builder: (context, feedState) {
        if (feedState.onlineUsers.isEmpty) return const SizedBox(height: 60);

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Аватарки слева
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: feedState.onlineUsers.length > 20 ? 21 : feedState.onlineUsers.length,
                  itemBuilder: (context, index) {
                    if (index == 20 && feedState.onlineUsers.length > 20) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '+${feedState.onlineUsers.length - 20}',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final user = feedState.onlineUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (user.username.isNotEmpty) {
                            ProfileNavigationUtils.navigateToProfile(context, user.username);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: AuthorizedCachedNetworkImage(
                              imageUrl: user.avatar.isNotEmpty ? user.avatar : AppConstants.userAvatarPlaceholder,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
                              errorWidget: (context, url, error) => const Icon(
                                CupertinoIcons.person,
                                size: 16,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Каунтер справа
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: context.dynamicPrimaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${feedState.onlineUsers.length}',
                    style: const TextStyle(
                      color: AppColors.bgWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
