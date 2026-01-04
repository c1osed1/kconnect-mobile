/// Мини-плеер с анимацией раскрытия и управления воспроизведением
///
/// Плавающий плеер в нижней части экрана с эффектом жидкого стекла.
/// Поддерживает анимацию раскрытия для показа дополнительных контролов.
/// Интегрируется с PlaybackBloc и QueueBloc для управления музыкой.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, Colors;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../presentation/blocs/playback_bloc.dart';
import '../presentation/blocs/queue_bloc.dart';
import '../presentation/blocs/queue_event.dart';
import '../domain/models/playback_state.dart';
import '../domain/models/queue_state.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';
import 'package:kconnect_mobile/core/utils/image_utils.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Виджет мини-плеера с анимацией раскрытия
///
/// Показывает текущий трек, прогресс и элементы управления.
/// Поддерживает плавную анимацию между свернутым и развернутым состояниями.
/// Интегрируется с очередью для автоматического перехода к следующему треку.
class MiniPlayer extends StatefulWidget {
  final VoidCallback? onMusicTabTap;
  final Function(bool hide)? onTabBarToggle;

  const MiniPlayer({super.key, this.onMusicTabTap, this.onTabBarToggle});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _albumArtPositionAnimation;
  late Animation<double> _contentOpacityAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Will be called in build
  }

  void _setupAnimations(double screenWidth) {
    final expandedWidth = screenWidth - 32;
    _positionAnimation = Tween<double>(begin: 16, end: 16).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    _widthAnimation = Tween<double>(begin: 50, end: expandedWidth).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    _heightAnimation = Tween<double>(begin: 50, end: 50).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    _borderRadiusAnimation = Tween<double>(begin: 25, end: 25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    // Album art animates from center (collapsed) to left (expanded)
    _albumArtPositionAnimation = Tween<double>(begin: 3, end: 8).animate( // 3 = slightly left of center in 50px container, 8 = left in expanded
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    // Content opacity animates for smooth reveal
    _contentOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(0.3, 1.0, curve: Curves.easeOut))
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    // Delay tab bar toggle to sync with animation
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.onTabBarToggle?.call(_isExpanded);
    });
  }

  void _handlePlayPause(BuildContext context, PlaybackState state) {
    final bloc = context.read<PlaybackBloc>();
    if (state.isBuffering) {
      // Buffering - do nothing to prevent accidental restart
    } else {
      bloc.add(const PlaybackToggleRequested());
    }
  }

  void _handleNext(BuildContext context) {
    // Trigger queue navigation
    context.read<QueueBloc>().add(const QueueNextRequested());
  }

  void _handlePrevious(BuildContext context) {
    // Trigger queue navigation
    context.read<QueueBloc>().add(const QueuePreviousRequested());
  }

  @override
  Widget build(BuildContext context) {
    _setupAnimations(MediaQuery.of(context).size.width);

    return MultiBlocListener(
      listeners: [
        // Listen to queue changes and auto-play new tracks
        BlocListener<QueueBloc, QueueState>(
          listener: (context, queueState) {
            final currentTrack = queueState.currentTrack;
            final playbackBloc = context.read<PlaybackBloc>();

            // Only auto-play if queue has a track and it's different from currently playing
            if (currentTrack != null) {
              final currentPlaybackState = playbackBloc.state;
              if (currentPlaybackState.currentTrack?.id != currentTrack.id) {
                playbackBloc.add(PlaybackPlayRequested(currentTrack));
              }
            }
          },
        ),
        // Listen to playback state changes for automatic queue progression
        BlocListener<PlaybackBloc, PlaybackState>(
          listener: (context, playbackState) {
            // Check if track completed and trigger next track in queue
            if (playbackState.error == 'COMPLETED' && playbackState.currentTrack != null) {
              context.read<QueueBloc>().add(const QueueNextRequested());
            }
          },
        ),
      ],
      child: BlocBuilder<PlaybackBloc, PlaybackState>(
        builder: (context, state) {
          widget.onTabBarToggle?.call(state.hasTrack && _isExpanded);

          // Main mini player content
        Widget miniPlayerContent = AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Positioned(
            bottom: 16,
            left: _positionAnimation.value,
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
                shape: LiquidRoundedSuperellipse(borderRadius: _borderRadiusAnimation.value),
                child: SizedBox(
                  key: ValueKey('miniPlayer_${state.currentTrack?.id ?? 'idle'}_$_isExpanded'),
                  width: _widthAnimation.value,
                  height: _heightAnimation.value,
                  child: !state.hasTrack
                      ? _buildMusicTabButton(state)
                      : _buildAnimatedView(context, state),
                ),
              ),
            ),
          ),
        );

        // Separate overlay for circular progress with expansion animation
        if (state.hasTrack && (state.isPlaying || state.isBuffering)) {
          final overlay = AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Positioned(
              bottom: 16 - 3 * (1 - _animationController.value), // 3px offset for stroke alignment
              left: 16 - 3 * (1 - _animationController.value),
              child: IgnorePointer( // Allow gestures through to mini player buttons
                child: Opacity(
                  opacity: 1 - _animationController.value,
                  child: Transform.scale(
                    scale: 1 - _animationController.value,
                    child: SizedBox(
                      width: 56, // Same as mini player + stroke
                      height: 56,
                      child: CircularProgressIndicator(
                        value: state.progress.clamp(0.0, 1.0),
                        strokeWidth: 3,
                        backgroundColor: AppColors.bgWhite.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          return Stack(
            children: [
              miniPlayerContent,
              overlay,
            ],
          );
        }

        return miniPlayerContent;
        },
      ),
    );
  }



  Widget _buildMusicTabButton(PlaybackState state) {
    final isPlaying = state.hasTrack && state.isPlaying;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: widget.onMusicTabTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            CupertinoIcons.music_note,
            size: 24,
            color: AppColors.bgWhite,
          ),
          if (isPlaying)
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: state.progress.clamp(0.0, 1.0),
                strokeWidth: 2,
                backgroundColor: AppColors.bgWhite.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedView(BuildContext context, PlaybackState state) {
    final track = state.currentTrack!;
    final hasError = state.hasError;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background tap area - covers entire container except controls
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpand, // Background tap closes the player
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent, // Transparent background
              ),
            ),
          ),

          // Album art that animates from center to left
          Positioned(
            left: _albumArtPositionAnimation.value,
            child: GestureDetector(
              onTap: _toggleExpand, // Album art tap also closes
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: ImageUtils.getCompleteImageUrl(track.coverPath) ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 40,
                    height: 40,
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    child: CupertinoActivityIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 40,
                    height: 40,
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    child: Icon(
                      CupertinoIcons.music_note,
                      color: AppColors.primaryPurple,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Expanded content that fades in
          Opacity(
            opacity: _contentOpacityAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Spacer to account for album art
                  const SizedBox(width: 48), // 40px art + 8px margin
                  // Track info - background tappable
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleExpand, // Track info tap closes player
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2), // Small top padding
                          Text(
                            track.title,
                            style: AppTextStyles.postAuthor.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Error display (if any)
                          if (hasError)
                            Text(
                              'Playback failed: ${state.error}',
                              style: AppTextStyles.bodySecondary.copyWith(
                                fontSize: 8,
                                color: AppColors.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Controls - positioned above background with higher z-index
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous track button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _handlePrevious(context),
                        child: Icon(
                          CupertinoIcons.backward_end,
                          color: AppColors.primaryPurple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (hasError)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => context.read<PlaybackBloc>().add(PlaybackPlayRequested(track)),
                          child: const Icon(
                            CupertinoIcons.refresh,
                            color: AppColors.error,
                            size: 16,
                          ),
                        )
                      else
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _handlePlayPause(context, state),
                          child: _buildPlayAnimatedIcon(state.isPlaying, state.isBuffering),
                        ),
                      const SizedBox(width: 4),
                      // Next track button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _handleNext(context),
                        child: Icon(
                          CupertinoIcons.forward_end,
                          color: AppColors.primaryPurple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _toggleExpand,
                        child: Icon(
                          _isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.arrow_up_to_line,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Progress bar at bottom of container (only when not errored)
          if (!hasError)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final localPosition = box.globalToLocal(details.globalPosition);
                    final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                    final newPosition = Duration(
                      seconds: ((state.duration?.inSeconds ?? 0) * progress).round()
                    );
                    context.read<PlaybackBloc>().add(PlaybackSeekRequested(newPosition));
                  }
                },
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: state.progress.clamp(0.0, 1.0),
                    child: Container(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildPlayAnimatedIcon(bool isPlaying, bool isBuffering) {
    if (isBuffering) {
      return CupertinoActivityIndicator(
        color: AppColors.primaryPurple,
      );
    }
    if (!isPlaying) {
      return Icon(
        CupertinoIcons.play,
        color: AppColors.primaryPurple,
        size: 16,
      );
    }
    return Icon(
      CupertinoIcons.pause,
      color: AppColors.primaryPurple,
      size: 20,
    );
  }
}
