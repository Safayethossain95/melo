import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import 'ambient_glow.dart';
import 'glass_container.dart';
import 'live_visualizer.dart';
import 'track_row.dart';

class NowPlayingPanel extends StatefulWidget {
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;
  final VoidCallback? onClose;

  const NowPlayingPanel({
    super.key,
    required this.audioEngine,
    required this.libraryRepo,
    this.onClose,
  });

  @override
  State<NowPlayingPanel> createState() => _NowPlayingPanelState();
}

class _NowPlayingPanelState extends State<NowPlayingPanel> {
  int _selectedTab = 0; // 0 = Queue, 1 = Lyrics

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.audioEngine,
      builder: (context, _) {
        final track = widget.audioEngine.currentTrack;

        if (track == null) {
          return GlassContainer(
            borderRadius: 0,
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Text(
                'No track playing',
                style: TextStyle(color: MeloColors.darkTextMuted),
              ),
            ),
          );
        }

        final dominant = Color((track.id.hashCode & 0x00FFFFFF) | 0xFF000000);

        return AmbientGlow(
          dominantColor: dominant,
          opacity: 0.22,
          child: Container(
            color: isDark ? MeloColors.darkSurface1.withValues(alpha: 0.9) : MeloColors.lightSurface1.withValues(alpha: 0.95),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: widget.onClose,
                          tooltip: 'Close',
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Large Artwork
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [dominant, MeloColors.tealDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MeloColors.primaryTeal.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.album_rounded,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Title & Artist
                        Text(
                          track.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MeloColors.primaryTeal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.album,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 16),

                        // Live Reactive Visualizer
                        LiveVisualizer(
                          isPlaying: widget.audioEngine.isPlaying,
                          barCount: 20,
                          height: 28,
                        ),

                        const SizedBox(height: 20),

                        // Segmented Tab Selector (Queue / Lyrics)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(0, 'Up Next', Icons.queue_music_rounded),
                              _buildTabItem(1, 'Lyrics', Icons.lyrics_rounded),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tab Content: Queue or Lyrics
                        if (_selectedTab == 0) ...[
                          _buildQueueView(isDark),
                        ] else ...[
                          _buildLyricsView(track, isDark),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? MeloColors.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : MeloColors.darkTextMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : MeloColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueView(bool isDark) {
    final queue = widget.audioEngine.queue;
    final currentIndex = widget.audioEngine.currentIndex;

    if (queue.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Queue is empty',
          style: TextStyle(color: MeloColors.darkTextMuted, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${queue.length} Tracks in queue',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
              ),
            ),
            TextButton(
              onPressed: widget.audioEngine.clearQueue,
              child: const Text('Clear', style: TextStyle(color: MeloColors.primaryTeal, fontSize: 12)),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: queue.length,
          itemBuilder: (context, i) {
            final t = queue[i];
            final isCur = i == currentIndex;

            return TrackRow(
              key: ValueKey(t.id),
              track: t,
              index: i,
              isCurrent: isCur,
              isPlaying: widget.audioEngine.isPlaying,
              onTap: () => widget.audioEngine.playTrack(t),
              onToggleFavorite: () => widget.libraryRepo.toggleFavorite(t.id),
              onPlayNext: () => widget.audioEngine.playNext(t),
              onAddToQueue: () => widget.audioEngine.addToQueue(t),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLyricsView(Track track, bool isDark) {
    final lyrics = track.lyrics ??
        '♪ Instrumental track ♪\n\n[00:04.00] Immersive frequencies floating in space\n[00:08.50] Deep teal horizons, no internet required\n[00:12.00] Instant playback pulsing in your headphones\n[00:16.00] Pure offline sound, crystal clear clarity\n[00:20.00] Melo beats continue...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        lyrics,
        style: TextStyle(
          fontSize: 13,
          height: 1.8,
          color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
