import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/track_row.dart';

class FavoritesPage extends StatelessWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;

  const FavoritesPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = libraryRepo.favorites;

    return AmbientGlow(
      dominantColor: MeloColors.favoriteRed,
      opacity: 0.16,
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
                Row(
                  children: [
                    Container(
                      width: isMobile ? 74 : 90,
                      height: isMobile ? 74 : 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
                        gradient: const LinearGradient(
                          colors: [MeloColors.favoriteRed, MeloColors.tealDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MeloColors.favoriteRed.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.favorite_rounded, color: Colors.white, size: isMobile ? 36 : 44),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorites',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.w800,
                              color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${favorites.length} loved tracks',
                            style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          if (favorites.isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MeloColors.primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => audioEngine.playTrack(favorites.first, newQueue: favorites),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('Play Favorites', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (favorites.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 50, color: MeloColors.darkTextMuted),
                          SizedBox(height: 12),
                          Text('No favorite songs yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Tap the heart icon on any track to add it here', style: TextStyle(color: MeloColors.darkTextMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favorites.length,
                    itemBuilder: (context, i) {
                      final t = favorites[i];
                      return TrackRow(
                        track: t,
                        index: i,
                        isCurrent: audioEngine.currentTrack?.id == t.id,
                        isPlaying: audioEngine.isPlaying,
                        onTap: () => audioEngine.playTrack(t, newQueue: favorites),
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
      ),
    );
  }
}
