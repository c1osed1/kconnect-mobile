import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/features/feed/feed_screen.dart';
import 'package:kconnect_mobile/features/music/music_home.dart';
import 'package:kconnect_mobile/features/menu/menu_screen.dart';
import 'package:kconnect_mobile/features/messages/messages_screen.dart';
import 'package:kconnect_mobile/features/messages/presentation/blocs/messages_bloc.dart';
import 'package:kconnect_mobile/features/messages/presentation/blocs/messages_event.dart';
import 'package:kconnect_mobile/features/messages/presentation/blocs/messages_state.dart';
import 'package:kconnect_mobile/features/profile/my_profile_screen.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/core/utils/theme_extensions.dart';
import 'package:kconnect_mobile/core/widgets/app_header.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_event.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/account_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/account_event.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/account_state.dart';
import 'package:kconnect_mobile/features/auth/presentation/widgets/account_menu.dart';
import 'package:kconnect_mobile/features/feed/presentation/blocs/feed_bloc.dart';
import 'package:kconnect_mobile/features/feed/presentation/blocs/feed_event.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_event.dart';
import 'package:kconnect_mobile/features/profile/presentation/blocs/profile_state.dart';
import 'package:kconnect_mobile/features/music/presentation/blocs/music_bloc.dart';
import 'package:kconnect_mobile/features/music/presentation/blocs/music_event.dart';
import 'package:kconnect_mobile/core/theme/presentation/blocs/theme_bloc.dart';
import 'package:kconnect_mobile/core/theme/presentation/blocs/theme_event.dart';
import 'package:kconnect_mobile/services/storage_service.dart';
import 'package:kconnect_mobile/features/music/widgets/mini_player.dart';
import 'package:kconnect_mobile/features/music/presentation/blocs/playback_bloc.dart';
import 'package:kconnect_mobile/features/music/domain/models/playback_state.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:kconnect_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:kconnect_mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:kconnect_mobile/features/notifications/presentation/widgets/notifications_section.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 2);
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(2);
  final ValueNotifier<bool> isTabAnimating = ValueNotifier(false);
  late AnimationController _tabBarAnimationController;
  late Animation<double> _tabBarOpacityAnimation;
  late Animation<double> _tabBarBottomAnimation;
  late final ValueNotifier<bool> feedScrolledDown = ValueNotifier(false);
  late final ValueNotifier<bool> scrollToTopRequested = ValueNotifier(false);
  late final List<Widget> _pages;
  final ValueNotifier<MusicSection> _musicSectionController = ValueNotifier(MusicSection.home);
  late final ValueNotifier<bool> _notificationsVisible;
  bool _isNotificationsOpen = false;
  final ValueNotifier<int> _unreadMessagesCount = ValueNotifier(0);


  @override
  void initState() {
    super.initState();
    _tabBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tabBarOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _tabBarAnimationController, curve: Curves.easeOutCubic)
    );
    _tabBarBottomAnimation = Tween<double>(begin: 16.0, end: -50.0).animate(
      CurvedAnimation(parent: _tabBarAnimationController, curve: Curves.easeOutCubic)
    );
    _notificationsVisible = ValueNotifier(false);

    _pages = [
      const MyProfileScreen(),
      MusicHome(
        sectionController: _musicSectionController,
      ),
      FeedScreen(
        isTabAnimating: isTabAnimating,
        onScrollChanged: _onFeedScrollChanged,
        scrollToTopRequested: scrollToTopRequested,
      ),
      MessagesScreen(),
      const MenuScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.position.isScrollingNotifier.addListener(() {
        isTabAnimating.value = _pageController.position.isScrollingNotifier.value;
      });
      final authState = BlocProvider.of<AuthBloc>(context).state;
      if (authState is! AuthAuthenticated) {
        BlocProvider.of<AuthBloc>(context).add(RefreshAuthEvent());
      }
      BlocProvider.of<AccountBloc>(context).add(LoadAccountsEvent());
      BlocProvider.of<NotificationsBloc>(context).add(const NotificationsStarted());
      BlocProvider.of<MessagesBloc>(context).add(ConnectWebSocketEvent());
    });
  }

  @override
  void dispose() {
    _tabBarAnimationController.dispose();
    _notificationsVisible.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onPageChanged(int index) {
    _currentIndexNotifier.value = index;
  }

  void _onFeedScrollChanged(bool scrolledDown) {
    feedScrolledDown.value = scrolledDown;
  }

  void _onMusicFavoritesBack() {
    _onTabTapped(1);
    _musicSectionController.value = MusicSection.home;
  }

  void _onMusicPlaylistsBack() {
    _onTabTapped(1);
    _musicSectionController.value = MusicSection.home;
  }

  void _onMusicAllTracksBack() {
    _onTabTapped(1);
    _musicSectionController.value = MusicSection.home;
  }

  void _onMusicSearchBack() {
    _onTabTapped(1);
    _musicSectionController.value = MusicSection.home;
  }



  IconData _getDynamicIcon() {
    switch (_currentIndexNotifier.value) {
      case 0:
        return CupertinoIcons.add;
      case 1:
        return CupertinoIcons.search;
      case 2:
        return feedScrolledDown.value ? CupertinoIcons.up_arrow : CupertinoIcons.add;
      case 3:
        return CupertinoIcons.pencil;
      case 4:
        return CupertinoIcons.person_2;
      default:
        return CupertinoIcons.add;
    }
  }

  void _onDynamicButtonPressed() {
    // TODO: Реализовать действия для каждой вкладки - добавить навигацию к соответствующим экранам
    // Для каждой вкладки реализовать специфическое действие при нажатии на динамическую кнопку
    switch (_currentIndexNotifier.value) {
      case 0:
        // Профиль: редактирование??
        break;
      case 1:
        // Музыка: поиск +
        _onMusicSearchPressed();
        break;
      case 2:
        // Лента: новый пост или прокрутка вверх +-
        if (feedScrolledDown.value) {
          scrollToTopRequested.value = true;
        } else {
          // TODO: Реализовать добавление поста
        }
        break;
      case 3:
        // Сообщения: новый чат - открыть экран выбора пользователя для создания чата
        break;
      case 4:
        // Меню: мульти-аккаунт +
        _showAccountMenu();
        break;
    }
  }

  void _onMusicSearchPressed() {
    _onTabTapped(1);
    _musicSectionController.value = MusicSection.search;
  }

  void _showAccountMenu() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: const AccountMenu(),
      ),
    );
  }

  void _onTabBarToggle(bool hide) {
    if (hide) {
      _tabBarAnimationController.forward();
    } else {
      _tabBarAnimationController.reverse();
    }
  }

  void _toggleNotifications([bool? visible]) {
    final nextValue = visible ?? !_notificationsVisible.value;
    setState(() {
      _notificationsVisible.value = nextValue;
      _isNotificationsOpen = nextValue;
    });
    if (nextValue) {
      context.read<NotificationsBloc>().add(const NotificationsStarted());
    }
  }

  void _onNotificationClose() {
    setState(() {
      _notificationsVisible.value = false;
      _isNotificationsOpen = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<MessagesBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AccountBloc, AccountState>(
            listener: (context, state) {
              // Триггер обновления данных (включая смену аккаунта)
              if (state is AccountLoaded && state.activeAccount != null) {
                context.read<FeedBloc>().add(RefreshFeedEvent());

                context.read<ProfileBloc>().add(RefreshProfileEvent());

                context.read<MusicBloc>().add(MusicMyVibeFetched());
                context.read<MusicBloc>().add(MusicPopularFetched());
                context.read<MusicBloc>().add(MusicChartsFetched());
                context.read<NotificationsBloc>().add(const NotificationsRefreshed());
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) async {
              if (state is ProfileLoaded) {
                final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated &&
            state.profile.username == authState.user.username) {
          final useProfileAccent = await StorageService.getUseProfileAccentColor();
          if (context.mounted) {
            if (useProfileAccent) {
              final profileColor = state.profile.profileColor;
              if (profileColor != null && profileColor.isNotEmpty) {
                context.read<ThemeBloc>().add(UpdateAccentColorStateEvent(profileColor));
              } else {
                context.read<ThemeBloc>().add(UpdateAccentColorStateEvent(null));
              }
            }
          }
        }
              }
            },
          ),
          BlocListener<MessagesBloc, MessagesState>(
            listener: (context, state) {
              debugPrint('MainTabs BlocListener: totalUnreadCount changed to ${state.totalUnreadCount}');
              _unreadMessagesCount.value = state.totalUnreadCount;
            },
          ),
        ],
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (_isNotificationsOpen) {
                _onNotificationClose();
                return;
              }
              if (_currentIndexNotifier.value == 1 && _musicSectionController.value == MusicSection.search) {
                _musicSectionController.value = MusicSection.home;
              } else if (_currentIndexNotifier.value == 1 && _musicSectionController.value != MusicSection.home) {
                _musicSectionController.value = MusicSection.home;
              }
            }
          },
          child: CupertinoPageScaffold(
          backgroundColor: AppColors.bgDark,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ValueListenableBuilder<MusicSection>(
                  valueListenable: _musicSectionController,
                  builder: (context, currentSection, child) => ValueListenableBuilder<int>(
                    valueListenable: _currentIndexNotifier,
                    builder: (context, currentIndex, child) => AppHeader(
                      currentTabIndex: currentIndex,
                      isInMusicFavoritesSection: currentIndex == 1 && currentSection == MusicSection.favorites,
                      onMusicFavoritesBack: (currentIndex == 1 && currentSection == MusicSection.favorites) ? _onMusicFavoritesBack : null,
                      isInMusicPlaylistsSection: currentIndex == 1 && currentSection == MusicSection.playlists,
                      onMusicPlaylistsBack: (currentIndex == 1 && currentSection == MusicSection.playlists) ? _onMusicPlaylistsBack : null,
                      isInMusicAllTracksSection: currentIndex == 1 && currentSection == MusicSection.allTracks,
                      onMusicAllTracksBack: (currentIndex == 1 && currentSection == MusicSection.allTracks) ? _onMusicAllTracksBack : null,
                      isInMusicSearchSection: currentIndex == 1 && currentSection == MusicSection.search,
                      onMusicSearchBack: (currentIndex == 1 && currentSection == MusicSection.search) ? _onMusicSearchBack : null,
                      onNotificationsTap: _toggleNotifications,
                      isNotificationsOpen: _isNotificationsOpen,
                      hideNotificationsBadge: _isNotificationsOpen,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      ValueListenableBuilder<MusicSection>(
                        valueListenable: _musicSectionController,
                        builder: (context, section, child) {
                          return PageView(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            physics: section != MusicSection.home ? const NeverScrollableScrollPhysics() : null,
                            children: _pages,
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _tabBarAnimationController,
                        builder: (context, child) => Positioned(
                          bottom: _tabBarBottomAnimation.value,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: _tabBarOpacityAnimation.value,
                            child: _buildTabBar(),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _tabBarAnimationController,
                        builder: (context, child) => Positioned(
                          bottom: _tabBarBottomAnimation.value,
                          right: 16,
                          child: Opacity(
                            opacity: _tabBarOpacityAnimation.value,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _currentIndexNotifier,
                              builder: (context, currentIndex, child) => ValueListenableBuilder<bool>(
                                valueListenable: feedScrolledDown,
                                builder: (context, scrolledDown, child) => _buildDynamicButton(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      MiniPlayer(onMusicTabTap: () => _onTabTapped(1), onTabBarToggle: _onTabBarToggle),
                      ValueListenableBuilder<bool>(
                        valueListenable: _notificationsVisible,
                        builder: (context, visible, child) => NotificationsSection(
                          isVisible: visible,
                          onClose: _onNotificationClose,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  Widget _buildTabBar() {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65, // 65% ширины
        height: 50, // тонкая сигаретка
        child: LiquidGlassLayer(
          settings: const LiquidGlassSettings(
            thickness: 15,
            glassColor: Color(0x33FFFFFF),
            lightIntensity: 1.5,
            chromaticAberration: 1,
            saturation: 1.1,
            ambientStrength: 1,
            blur: 4,
            refractiveIndex: 1.8,
          ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 25),
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndexNotifier,
            builder: (context, currentIndex, child) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabIcon(0, CupertinoIcons.person),
                BlocBuilder<PlaybackBloc, PlaybackState>(
                  builder: (context, state) => _buildMusicTabIcon(state),
                ),
                _buildTabIcon(2, CupertinoIcons.news),
                _buildTabIcon(3, CupertinoIcons.chat_bubble_2),
                _buildTabIcon(4, CupertinoIcons.square_grid_2x2),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildMusicTabIcon(PlaybackState state) {
    final isSelected = _currentIndexNotifier.value == 1;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _onTabTapped(1),
      child: Icon(
        CupertinoIcons.music_note,
        size: 24,
        color: isSelected ? context.dynamicPrimaryColor : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTabIcon(int index, IconData icon) {
    final isSelected = _currentIndexNotifier.value == index;

    if (index == 3) {
      return ValueListenableBuilder<int>(
        valueListenable: _unreadMessagesCount,
        builder: (context, unreadCount, child) {
          debugPrint('MainTabs: Messages badge - unreadCount: $unreadCount');
          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _onTabTapped(index),
            child: Stack(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? context.dynamicPrimaryColor : AppColors.textSecondary,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.dynamicPrimaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _onTabTapped(index),
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? context.dynamicPrimaryColor : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDynamicButton() {
    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 15,
        glassColor: Color(0x33FFFFFF),
        lightIntensity: 1.5,
        chromaticAberration: 1,
        saturation: 1.1,
        ambientStrength: 1,
        blur: 4,
        refractiveIndex: 1.8,
      ),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 25),
        child: SizedBox(
          width: 50,
          height: 50,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onDynamicButtonPressed,
            child: Icon(
              _getDynamicIcon(),
              size: 24,
              color: AppColors.bgWhite,
            ),
          ),
        ),
      ),
    );
  }
}
