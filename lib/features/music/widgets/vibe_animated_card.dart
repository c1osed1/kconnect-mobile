/// Анимированная карточка Vibe с эффектом плавающих частиц
///
/// Отображает информацию о Vibe плейлисте с анимацией.
/// Показывает синусоидальную волну при воспроизведении.
/// Поддерживает различные состояния воспроизведения.
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/theme_extensions.dart';
import '../../../theme/app_colors.dart';
import '../presentation/blocs/music_bloc.dart';
import '../presentation/blocs/music_state.dart';
import '../presentation/blocs/playback_bloc.dart';
import '../domain/models/playback_state.dart';
import '../domain/models/track.dart';

/// Анимированная карточка Vibe с плавающими частицами
///
/// Создает интерактивную карточку для Vibe плейлиста с эффектами анимации.
/// При воспроизведении отображает синусоидальную волну и плавающие частицы.
class VibeAnimatedCard extends StatefulWidget {
  final VoidCallback? onPressed;
  final Duration animationDuration;

  const VibeAnimatedCard({
    super.key,
    this.onPressed,
    this.animationDuration = const Duration(seconds: 4),
  });

  @override
  State<VibeAnimatedCard> createState() => _VibeAnimatedCardState();
}

class _VibeAnimatedCardState extends State<VibeAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> _getArtistsInfo(List<Track> tracks) {
    if (tracks.isEmpty) return ['Загрузка...', ''];

    final uniqueArtists = tracks
        .map((t) => t.artist)
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueArtists.isEmpty) return ['Нет данных', ''];

    // Показываем максимум 2 артиста в первой строке
    final displayArtists = uniqueArtists.take(2).toList();
    final firstLine = displayArtists.join(', ');

    // Вторая строка - "и не только" если есть больше артистов
    final secondLine = uniqueArtists.length > 2 ? 'и не только' : '';

    return [firstLine, secondLine];
  }

  List<Widget> _buildArtistsText(List<Track> tracks) {
    final artistsInfo = _getArtistsInfo(tracks);

    return [
      // Первая строка - артисты
      Text(
        artistsInfo[0],
        style: TextStyle(
          color: AppColors.bgWhite.withValues(alpha: 0.9),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      // Вторая строка - "и не только" (если есть)
      if (artistsInfo[1].isNotEmpty)
        Text(
          artistsInfo[1],
          style: TextStyle(
            color: AppColors.bgWhite.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlaybackBloc, PlaybackState, ({Track? currentTrack, bool isPlaying})>(
      selector: (state) => (currentTrack: state.currentTrack, isPlaying: state.isPlaying),
      builder: (context, playbackData) {
        return BlocBuilder<MusicBloc, MusicState>(
          builder: (context, musicState) {
            final currentTrack = playbackData.currentTrack;
            final isPlaying = playbackData.isPlaying;

            // Проверяем, играет ли трек из вайба
            final isPlayingFromVibe = currentTrack != null &&
                musicState.vibeTracks.isNotEmpty &&
                musicState.vibeTracks.any((track) => track.id == currentTrack.id);

            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        // Яркий градиент когда не играет из вайба, обычный когда играет
                        isPlayingFromVibe
                            ? context.dynamicGradientStart.withValues(alpha: 0.3 + 0.2 * _animationController.value)
                            : context.dynamicGradientStart.withValues(alpha: 0.8 + 0.2 * _animationController.value),
                        isPlayingFromVibe
                            ? context.dynamicGradientEnd.withValues(alpha: 0.2 + 0.3 * _animationController.value)
                            : context.dynamicGradientEnd.withValues(alpha: 0.6 + 0.4 * _animationController.value),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.dynamicPrimaryColor.withValues(alpha: 0.1),
                        blurRadius: 1,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: widget.onPressed,
                    child: Stack(
                      children: [
                        // Синусоидальная волна при воспроизведении
                        if (isPlayingFromVibe)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SineWavePainter(
                                color: context.dynamicPrimaryColor,
                                amplitude: 8,
                                frequency: 0.02,
                                // Непрерывная синусоида при воспроизведении, фиксированная на паузе
                                phase: isPlaying
                                    ? (DateTime.now().millisecondsSinceEpoch * 0.002) % (10 * math.pi) // Замедленная непрерывная анимация с ограничением фазы
                                    : math.pi / 4, // Фиксированная фаза на паузе
                                opacity: 0.4,
                                // Добавляем небольшую рандомность
                                randomSeed: DateTime.now().millisecondsSinceEpoch ~/ 400, // Меняем seed каждую секунду для плавности
                              ),
                            ),
                          ),
                        // Floating particles effect (базовая анимация)
                        Positioned(
                          top: 20 + 10 * _animationController.value,
                          left: 80,
                          child: Icon(
                            CupertinoIcons.star_fill,
                            size: 8,
                            color: AppColors.bgWhite.withValues(alpha: 0.5),
                          ),
                        ),
                        Positioned(
                          top: 40 + 15 * (1 - _animationController.value),
                          right: 60,
                          child: Icon(
                            CupertinoIcons.wand_stars,
                            size: 6,
                            color: AppColors.bgWhite.withValues(alpha: 0.7),
                          ),
                        ),
                        Positioned(
                          bottom: 40 + 8 * _animationController.value,
                          right: 60,
                          child: Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 10,
                            color: AppColors.bgWhite.withValues(alpha: 0.6),
                          ),
                        ),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.wand_stars_inverse,
                                    size: 32,
                                    color: AppColors.bgWhite,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Мой вайб',
                                    style: TextStyle(
                                      color: AppColors.bgWhite,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ..._buildArtistsText(musicState.vibeTracks),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Custom painter for sine wave animation
class SineWavePainter extends CustomPainter {
  final Color color;
  final double amplitude;
  final double frequency;
  final double phase;
  final double opacity;
  final int? randomSeed;

  SineWavePainter({
    required this.color,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.opacity,
    this.randomSeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;

    // Инициализируем генератор случайных чисел для вариаций
    final random = randomSeed != null ? math.Random(randomSeed) : null;

    // Draw sine wave across the width with amplitude variation
    // Start directly from the first sine wave point to avoid straight line at the beginning
    bool isFirstPoint = true;
    for (double x = 0; x <= size.width; x += 1) {
      // Базовая синусоида
      double y = centerY + amplitude * math.sin(frequency * x + phase);

      // Добавляем вариацию амплитуды для органичности
      if (random != null) {
        // Создаем вариацию пиков волны с большим разбросом
        final timeVariation = math.sin(phase * 0.5) * 0.3; // ±30% вариация амплитуды
        final ampMultiplier = 1.0 + timeVariation;

        y = centerY + (amplitude * ampMultiplier) * math.sin(frequency * x + phase);
      }

      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SineWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
           oldDelegate.color != color ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.frequency != frequency ||
           oldDelegate.opacity != opacity ||
           oldDelegate.randomSeed != randomSeed;
  }
}
