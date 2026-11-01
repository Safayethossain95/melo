import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import 'glass_container.dart';
import 'wave_progress_bar.dart';

class FloatingPlayerBar extends StatelessWidget {
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;
  final VoidCallback onToggleNowPlaying;

  const FloatingPlayerBar({
    super.key,
    required this.audioEngine,
    required this.libraryRepo,
    required this.onToggleNowPlaying,
  });

  String _formatTime(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: audioEngine,
      builder: (context, _) {
        final currentTrack = audioEngine.currentTrack;
        if (currentTrack == null) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;
            final isVeryNarrow = constraints.maxWidth < 380;

            return Container(
              margin: EdgeInsets.only(
                left: isCompact ? 10 : 16,
                right: isCompact ? 10 : 16,
                bottom: isCompact ? 10 : 16,
              ),
              child: GlassContainer(
                borderRadius: isCompact ? 20.0 : 24.0,
                blur: 24.0,
                backgroundColor: isDark
                    ? MeloColors.darkSurface1.withValues(alpha: 0.90)
                    : MeloColors.lightSurface1.withValues(alpha: 0.94),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12.0 : 16.0,
                  vertical: isCompact ? 8.0 : 10.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Controls Row
                    Row(
                      children: [
                        // Left: Track Thumbnail & Info
                        Expanded(
                          child: GestureDetector(
                            onTap: onToggleNowPlaying,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: isCompact ? 40 : 48,
                                  height: isCompact ? 40 : 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color((currentTrack.id.hashCode & 0x00FFFFFF) | 0xFF000000),
                                        MeloColors.tealDeep,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      size: isCompact ? 20 : 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Title & Artist
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentTrack.title,
                                        style: TextStyle(
                                          fontSize: isCompact ? 13 : 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentTrack.artist,
                                        style: TextStyle(
                                          fontSize: isCompact ? 11 : 12,
                                          color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Favorite Heart
                                IconButton(
                                  icon: Icon(
                                    currentTrack.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 19,
                                    color: currentTrack.isFavorite ? MeloColors.favoriteRed : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                                  ),
                                  onPressed: () => libraryRepo.toggleFavorite(currentTrack.id),
                                  tooltip: 'Favorite',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints.tightFor(width: isVeryNarrow ? 26 : 32, height: 32),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),

                        // Center: Playback Transport Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Shuffle (tablet/desktop)
                            if (!isCompact)
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle_rounded,
                                  size: 19,
                                  color: audioEngine.isShuffle ? MeloColors.primaryTeal : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                                ),
                                onPressed: audioEngine.toggleShuffle,
                                tooltip: 'Shuffle',
                              ),
                            // Previous
                            IconButton(
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                size: isCompact ? 22 : 26,
                                color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                              ),
                              onPressed: () => audioEngine.previous(),
                              tooltip: 'Previous',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(width: isCompact ? 32 : 38, height: isCompact ? 32 : 38),
                            ),
                            const SizedBox(width: 4),
                            // Play/Pause Main Button
                            Material(
                              color: MeloColors.primaryTeal,
                              shape: const CircleBorder(),
                              elevation: 4,
                              shadowColor: MeloColors.primaryTeal.withValues(alpha: 0.5),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: audioEngine.togglePlayPause,
                                child: Padding(
                                  padding: EdgeInsets.all(isCompact ? 8.0 : 10.0),
                                  child: Icon(
                                    audioEngine.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    size: isCompact ? 20 : 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Next
                            IconButton(
                              icon: Icon(
                                Icons.skip_next_rounded,
                                size: isCompact ? 22 : 26,
                                color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                              ),
                              onPressed: () => audioEngine.next(),
                              tooltip: 'Next',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(width: isCompact ? 32 : 38, height: isCompact ? 32 : 38),
                            ),
                            // Repeat Mode (tablet/desktop)
                            if (!isCompact)
                              IconButton(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      audioEngine.repeatMode == MeloRepeatMode.one
                                          ? Icons.repeat_one_rounded
                                          : Icons.repeat_rounded,
                                      size: 19,
                                      color: audioEngine.repeatMode != MeloRepeatMode.off ? MeloColors.primaryTeal : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                                    ),
                                  ],
                                ),
                                onPressed: audioEngine.cycleRepeatMode,
                                tooltip: 'Repeat',
                              ),
                          ],
                        ),

                        // Right: Volume & Queue Button (if wide)
                        if (!isCompact)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              // Queue button
                              IconButton(
                                icon: const Icon(Icons.queue_music_rounded, size: 20),
                                color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                                onPressed: onToggleNowPlaying,
                                tooltip: 'Queue / Now Playing',
                              ),
                              const SizedBox(width: 6),
                              // Mute / Volume icon
                              IconButton(
                                icon: Icon(
                                  audioEngine.isMuted || audioEngine.volume == 0
                                      ? Icons.volume_off_rounded
                                      : (audioEngine.volume < 0.5
                                          ? Icons.volume_down_rounded
                                          : Icons.volume_up_rounded),
                                  size: 20,
                                  color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                                ),
                                onPressed: audioEngine.toggleMute,
                                tooltip: 'Mute',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 6),
                              // Volume Slider
                              SizedBox(
                                width: 80,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                  ),
                                  child: Slider(
                                    value: audioEngine.isMuted ? 0.0 : audioEngine.volume,
                                    onChanged: audioEngine.setVolume,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Wave Seek Bar with Elapsed & Total Time
                    Row(
                      children: [
                        // Elapsed time
                        ValueListenableBuilder<Duration>(
                          valueListenable: audioEngine.positionNotifier,
                          builder: (context, pos, _) {
                            return Text(
                              _formatTime(pos),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Waveform progress
                        Expanded(
                          child: WaveProgressBar(
                            positionNotifier: audioEngine.positionNotifier,
                            durationNotifier: audioEngine.durationNotifier,
                            peaks: currentTrack.waveformPeaks,
                            onSeek: audioEngine.seek,
                            height: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Total / Remaining time
                        ValueListenableBuilder<Duration>(
                          valueListenable: audioEngine.durationNotifier,
                          builder: (context, dur, _) {
                            return Text(
                              _formatTime(dur),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
