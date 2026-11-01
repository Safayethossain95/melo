import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/folder_crate.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/track_row.dart';

class FolderDetailPage extends StatelessWidget {
  final FolderCrate crate;
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;
  final VoidCallback onBack;

  const FolderDetailPage({
    super.key,
    required this.crate,
    required this.audioEngine,
    required this.libraryRepo,
    required this.onBack,
  });

  String _formatTotalDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins min $secs sec';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = crate.sleeveColors.first;

    return AmbientGlow(
      dominantColor: primaryColor,
      opacity: 0.25,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16.0 : 24.0,
              vertical: isMobile ? 16.0 : 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs Header
                Row(
                  children: [
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 16, color: MeloColors.primaryTeal),
                            const SizedBox(width: 6),
                            Text(
                              'Folders',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      ' / ',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        crate.folderName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MeloColors.tealLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Hero Folder Header
                if (isMobile) ...[
                  Row(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [primaryColor, MeloColors.tealDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.folder_special_rounded, size: 44, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crate.folderName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${crate.trackCount} tracks • ${_formatTotalDuration(crate.totalDuration)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: MeloColors.primaryTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeloColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (crate.tracks.isNotEmpty) {
                            audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          side: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (crate.tracks.isNotEmpty) {
                            audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                            if (!audioEngine.isShuffle) audioEngine.toggleShuffle();
                          }
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 16),
                        label: const Text('Shuffle', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Big Crate Artwork
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [primaryColor, MeloColors.tealDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.folder_special_rounded, size: 64, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Info & Action Buttons
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: MeloColors.primaryTeal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'FOLDER CRATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: MeloColors.tealLight,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              crate.folderName,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${crate.trackCount} tracks • ${_formatTotalDuration(crate.totalDuration)} • Local Folder',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Play All & Shuffle Buttons
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MeloColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    if (crate.tracks.isNotEmpty) {
                                      audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                  label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                    side: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    if (crate.tracks.isNotEmpty) {
                                      audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                                      if (!audioEngine.isShuffle) audioEngine.toggleShuffle();
                                    }
                                  },
                                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                                  label: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Track List Header (Desktop only)
                if (!isMobile) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(width: 34, child: Center(child: Text('#', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)))),
                        SizedBox(width: 62),
                        Expanded(flex: 5, child: Text('TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MeloColors.darkTextMuted, letterSpacing: 0.8))),
                        SizedBox(width: 8),
                        Expanded(flex: 4, child: Text('ALBUM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MeloColors.darkTextMuted, letterSpacing: 0.8))),
                        SizedBox(width: 14),
                        Text('DURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MeloColors.darkTextMuted, letterSpacing: 0.8)),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const Divider(color: MeloColors.darkBorder, height: 1),
                  const SizedBox(height: 8),
                ],

                // Track Rows (Reactive to Audio Engine)
                ListenableBuilder(
                  listenable: audioEngine,
                  builder: (context, _) {
                    final curTrackId = audioEngine.currentTrack?.id;
                    final isPlaying = audioEngine.isPlaying;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: crate.tracks.length,
                      itemBuilder: (context, i) {
                        final t = crate.tracks[i];
                        final isCur = curTrackId == t.id;

                        return TrackRow(
                          key: ValueKey(t.id),
                          track: t,
                          index: i,
                          isCurrent: isCur,
                          isPlaying: isPlaying,
                          onTap: () => audioEngine.playTrack(t, newQueue: crate.tracks),
                          onToggleFavorite: () => libraryRepo.toggleFavorite(t.id),
                          onPlayNext: () => audioEngine.playNext(t),
                          onAddToQueue: () => audioEngine.addToQueue(t),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }
}
