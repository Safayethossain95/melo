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

    return ListenableBuilder(
      listenable: libraryRepo,
      builder: (context, _) {
        final tracks = libraryRepo.recentlyPlayed;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final horizPadding = isMobile ? 16.0 : 24.0;
            final vertPadding = isMobile ? 16.0 : 20.0;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: horizPadding,
                    right: horizPadding,
                    top: vertPadding,
                  ),
                  sliver: SliverToBoxAdapter(
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
                      ],
                    ),
                  ),
                ),

                if (tracks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Text('No listening history yet', style: TextStyle(color: MeloColors.darkTextMuted)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizPadding),
                    sliver: ListenableBuilder(
                      listenable: audioEngine,
                      builder: (context, _) {
                        final curTrackId = audioEngine.currentTrack?.id;
                        final isPlaying = audioEngine.isPlaying;

                        return SliverList.builder(
                          itemCount: tracks.length,
                          itemBuilder: (context, i) {
                            final t = tracks[i];
                            return TrackRow(
                              key: ValueKey(t.id),
                              track: t,
                              index: i,
                              isCurrent: curTrackId == t.id,
                              isPlaying: isPlaying,
                              onTap: () => audioEngine.playTrack(t, newQueue: tracks),
                              onToggleFavorite: () => libraryRepo.toggleFavorite(t.id),
                              onPlayNext: () => audioEngine.playNext(t),
                              onAddToQueue: () => audioEngine.addToQueue(t),
                            );
                          },
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
