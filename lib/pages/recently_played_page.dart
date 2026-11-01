import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/track_row.dart';

class RecentlyPlayedPage extends StatelessWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;

  const RecentlyPlayedPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tracks = libraryRepo.recentlyPlayed;

    return LayoutBuilder(
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
              Text(
                'Recently Played',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tracks.length} tracks listened to recently',
                style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              if (tracks.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text('No listening history yet', style: TextStyle(color: MeloColors.darkTextMuted)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tracks.length,
                  itemBuilder: (context, i) {
                    final t = tracks[i];
                    return TrackRow(
                      track: t,
                      index: i,
                      isCurrent: audioEngine.currentTrack?.id == t.id,
                      isPlaying: audioEngine.isPlaying,
                      onTap: () => audioEngine.playTrack(t, newQueue: tracks),
                      onToggleFavorite: () => libraryRepo.toggleFavorite(t.id),
                      onPlayNext: () => audioEngine.playNext(t),
                      onAddToQueue: () => audioEngine.addToQueue(t),
                    );
                  },
                ),

              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }
}
