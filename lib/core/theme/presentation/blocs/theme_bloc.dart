import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/storage_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/route_names.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// BLoC для управления темой приложения
///
/// Отвечает за все операции управления темой: загрузка, обновление акцентного цвета,
/// сброс к настройкам по умолчанию. Обеспечивает синхронизацию с хранилищем и UI.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeInitial()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<UpdateAccentColorEvent>(_onUpdateAccentColor);
    on<UpdateAccentColorStateEvent>(_onUpdateAccentColorState);
    on<ResetThemeEvent>(_onResetTheme);
  }

  static final MaterialColor _defaultAccentColor = const MaterialColor(
    0xFFD0BCFF,
    <int, Color>{
      50: Color(0xFFF3F0FF),
      100: Color(0xFFE0DCF9),
      200: Color(0xFFC9C0F0),
      300: Color(0xFFB2A4E7),
      400: Color(0xFF9B88DE),
      500: Color(0xFFD0BCFF),  // основной цвет
      600: Color(0xFF8F70E3),
      700: Color(0xFF7F5BD9),
      800: Color(0xFF6F46CF),
      900: Color(0xFF5F31C5),
    },
  );

  /// Создает MaterialColor из hex строки цвета
  MaterialColor _createMaterialColor(String hexColor) {

    final hexColorSanitized = hexColor.replaceFirst('#', '');

    final colorInt = int.parse(hexColorSanitized, radix: 16);

    final color = Color(colorInt | 0xFF000000);

    final Map<int, Color> swatch = {};
    final hslColor = HSLColor.fromColor(color);

    final shadeKeys = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];

    for (int i = 0; i < shadeKeys.length; i++) {
      final shadeKey = shadeKeys[i];
      final lightness = 1.0 - (i * 0.1);
      final shade = hslColor.withLightness(lightness.clamp(0.0, 1.0)).toColor();
      swatch[shadeKey] = shade;
    }

    swatch[500] = color;

    final materialColor = MaterialColor(color.toARGB32(), swatch);

    return materialColor;
  }

  void _onLoadTheme(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    try {
      debugPrint('ThemeBloc: LoadThemeEvent started');

      final useProfileAccent = await StorageService.getUseProfileAccentColor();
      debugPrint('ThemeBloc: Personalization enabled: $useProfileAccent');

      String? accentColorHex;

      if (useProfileAccent) {
        accentColorHex = await StorageService.getSavedAccentColor();
        debugPrint('ThemeBloc: Saved accent color: $accentColorHex');
      } else {
        debugPrint('ThemeBloc: Personalization disabled, using default color');
      }

      MaterialColor accentColor = _defaultAccentColor;
      if (accentColorHex != null && accentColorHex.isNotEmpty) {
        try {
          accentColor = _createMaterialColor(accentColorHex);
          debugPrint('ThemeBloc: Successfully created MaterialColor from $accentColorHex');
        } catch (e) {
          debugPrint('ThemeBloc: Failed to parse color $accentColorHex, using default');
          accentColor = _defaultAccentColor;
        }
      } else {
        debugPrint('hemeBloc: No accent color hex, using default color');
      }

      AppColors.updateFromMaterialColor(accentColor);
      debugPrint('ThemeBloc: Updated AppColors, emitting ThemeLoaded');

      emit(ThemeLoaded(accentColor));
    } catch (e) {
      debugPrint('ThemeBloc: Error in LoadThemeEvent: $e');
      AppColors.updateFromMaterialColor(_defaultAccentColor);
      emit(ThemeLoaded(_defaultAccentColor));
    }
  }

  void _onUpdateAccentColor(UpdateAccentColorEvent event, Emitter<ThemeState> emit) async {
    if (state is! ThemeLoaded) {
      return;
    }

    MaterialColor accentColor = _defaultAccentColor;
    if (event.accentColor != null && event.accentColor!.isNotEmpty) {
      try {
        accentColor = _createMaterialColor(event.accentColor!);
        await StorageService.setSavedAccentColor(event.accentColor);
      } catch (e) {
        accentColor = _defaultAccentColor;
        await StorageService.setSavedAccentColor(null);
      }
    } else {
      await StorageService.setSavedAccentColor(null);
    }

    AppColors.updateFromMaterialColor(accentColor);

    emit(ThemeLoaded(accentColor));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.splash, (route) => false);
    });
  }

  void _onUpdateAccentColorState(UpdateAccentColorStateEvent event, Emitter<ThemeState> emit) async {
    MaterialColor accentColor = _defaultAccentColor;
    if (event.accentColor != null && event.accentColor!.isNotEmpty) {
      try {
        accentColor = _createMaterialColor(event.accentColor!);
        await StorageService.setSavedAccentColor(event.accentColor);
      } catch (e) {
        accentColor = _defaultAccentColor;
        await StorageService.setSavedAccentColor(null);
      }
    } else {
      await StorageService.setSavedAccentColor(null);
    }

    AppColors.updateFromMaterialColor(accentColor);

    emit(ThemeLoaded(accentColor));
  }

  void _onResetTheme(ResetThemeEvent event, Emitter<ThemeState> emit) {
    StorageService.setUseProfileAccentColor(false);
    StorageService.setSavedAccentColor(null);

    AppColors.resetToDefault();

    emit(ThemeLoaded(_defaultAccentColor));
  }
}
