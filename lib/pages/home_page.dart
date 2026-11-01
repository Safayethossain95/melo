import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/folder_crate.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/track_row.dart';

class HomePage extends StatelessWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;
  final Function(FolderCrate)? onOpenFolder;
  final VoidCallback? onNavigateFolders;
  final VoidCallback? onNavigateSongs;

  const HomePage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
    this.onOpenFolder,
    this.onNavigateFolders,
    this.onNavigateSongs,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 650;

    return ListenableBuilder(
      listenable: libraryRepo,
      builder: (context, _) {
        final mostPlayed = libraryRepo.mostPlayed;
        final totalTrackCount = libraryRepo.tracks.length;

        return AmbientGlow(
          opacity: 0.18,
          child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 24.0,
          vertical: isMobile ? 16.0 : 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Greeting Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTimeGreeting(),
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'All music stored locally • Zero telemetry',
                        style: TextStyle(
                          fontSize: isMobile ? 11.5 : 13,
                          color: MeloColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Quick Import Files Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                    foregroundColor: MeloColors.primaryTeal,
                    elevation: 0,
                    side: BorderSide(
                      color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 9 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => libraryRepo.importFiles(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    isMobile ? 'Add' : 'Add Music',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // "Most Played Songs" Section Header
            _buildSectionHeader(
              context,
              title: 'Most played songs',
              subtitle: 'Your heaviest rotation',
              actionLabel: onNavigateSongs != null ? 'All songs ($totalTrackCount)' : null,
              onAction: onNavigateSongs,
            ),

            if (mostPlayed.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (isMobile)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeloColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => audioEngine.playTrack(mostPlayed.first, newQueue: mostPlayed),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          side: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          audioEngine.playTrack(mostPlayed.first, newQueue: mostPlayed);
                          if (!audioEngine.isShuffle) audioEngine.toggleShuffle();
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 18),
                        label: const Text('Shuffle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MeloColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => audioEngine.playTrack(mostPlayed.first, newQueue: mostPlayed),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Play Top Tracks', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                        side: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        audioEngine.playTrack(mostPlayed.first, newQueue: mostPlayed);
                        if (!audioEngine.isShuffle) audioEngine.toggleShuffle();
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 16),

            if (mostPlayed.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note_rounded, size: 48, color: MeloColors.darkTextMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No tracks in your library yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Import local audio files to get started',
                        style: TextStyle(fontSize: 13, color: MeloColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Reactive high-performance track list listening to audio engine
              ListenableBuilder(
                listenable: audioEngine,
                builder: (context, _) {
                  final curTrackId = audioEngine.currentTrack?.id;
                  final isPlaying = audioEngine.isPlaying;
                  final topTracks = mostPlayed.take(25).toList();

                  return Column(
                    children: [
                      for (int i = 0; i < topTracks.length; i++)
                        TrackRow(
                          key: ValueKey(topTracks[i].id),
                          track: topTracks[i],
                          index: i,
                          isCurrent: curTrackId == topTracks[i].id,
                          isPlaying: isPlaying,
                          onTap: () => audioEngine.playTrack(topTracks[i], newQueue: mostPlayed),
                          onToggleFavorite: () => libraryRepo.toggleFavorite(topTracks[i].id),
                          onPlayNext: () => audioEngine.playNext(topTracks[i]),
                          onAddToQueue: () => audioEngine.addToQueue(topTracks[i]),
                        ),
                      if (mostPlayed.length > 25 && onNavigateSongs != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: onNavigateSongs,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              label: Text('View all $totalTrackCount songs'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MeloColors.primaryTeal,
                                side: const BorderSide(color: MeloColors.primaryTeal),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 120), // Clearance for floating player bar
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MeloColors.primaryTeal,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
