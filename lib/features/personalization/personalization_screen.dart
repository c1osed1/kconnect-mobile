/// Экран персонализации с настройками акцентного цвета
///
/// Позволяет пользователю настроить персонализацию интерфейса.
/// Поддерживает использование акцентного цвета из профиля пользователя.
/// Интегрируется с ThemeBloc и ProfileBloc для управления темами.
/// Экран персонализации с настройками акцентного цвета
///
/// Позволяет пользователю настроить персонализацию интерфейса.
/// Поддерживает использование акцентного цвета из профиля пользователя.
/// Интегрируется с ThemeBloc и ProfileBloc для управления темами.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';
import 'package:kconnect_mobile/core/utils/theme_extensions.dart';
import '../../core/theme/presentation/blocs/theme_bloc.dart';
import '../../core/theme/presentation/blocs/theme_event.dart';
import '../../core/theme/presentation/blocs/theme_state.dart';
import '../../features/profile/presentation/blocs/profile_bloc.dart';
import '../../features/profile/presentation/blocs/profile_event.dart';
import '../../features/profile/presentation/blocs/profile_state.dart';
import '../../services/storage_service.dart';

/// Экран настроек персонализации
///
/// Предоставляет интерфейс для настройки персональных предпочтений:
/// акцентный цвет из профиля, темы и другие визуальные настройки.
class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  bool _useProfileAccentColor = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
  }

  Future<void> _loadCurrentSetting() async {
    _useProfileAccentColor = await StorageService.getUseProfileAccentColor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded && _useProfileAccentColor) {
              final profileColor = state.profile.profileColor;
              debugPrint('🎨 Personalization: Profile loaded, profileColor: $profileColor');
              if (profileColor != null && profileColor.isNotEmpty) {
                debugPrint('🎨 Personalization: Applying profile color: $profileColor');
                context.read<ThemeBloc>().add(UpdateAccentColorEvent(profileColor));
              } else {
                debugPrint('🎨 Personalization: Profile has no color, using default');
                context.read<ThemeBloc>().add(UpdateAccentColorEvent(null));
              }
            } else if (state is ProfileLoaded) {
              debugPrint('🎨 Personalization: Profile loaded but personalization disabled');
            }
          },
        ),
        BlocListener<ThemeBloc, ThemeState>(
          listener: (context, state) {
          },
        ),
      ],
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.bgDark,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.bgDark,
          border: null,
          middle: Text(
            'Персонализация',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(
              CupertinoIcons.back,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Акцентный цвет',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.dynamicPrimaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Использовать акцентный цвет профиля',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Заменяет акцентный цвет приложения на цвет из вашего профиля',
                              style: AppTextStyles.bodySecondary.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoSwitch(
                        value: _useProfileAccentColor,
                        activeTrackColor: context.dynamicPrimaryColor,
                        onChanged: (value) async {
                          setState(() {
                            _useProfileAccentColor = value;
                          });

                          final profileBloc = context.read<ProfileBloc>();
                          final themeBloc = context.read<ThemeBloc>();

                          await StorageService.setUseProfileAccentColor(value);

                          if (!mounted) return;

                          if (value) {
                            // Load profile and apply color
                            profileBloc.add(LoadCurrentProfileEvent());
                          } else {
                            // Reset to default
                            themeBloc.add(UpdateAccentColorEvent(null));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
