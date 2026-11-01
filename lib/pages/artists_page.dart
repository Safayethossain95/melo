import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/glass_container.dart';
import '../widgets/track_row.dart';

class ArtistsPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;

  const ArtistsPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
  });

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  String? _selectedArtist;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artists = widget.libraryRepo.artists;

    if (_selectedArtist != null) {
      final artistTracks = artists[_selectedArtist!] ?? [];
      return _buildArtistDetailView(_selectedArtist!, artistTracks, isDark);
    }

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
                'Artists',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${artists.length} artists in your local collection',
                style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final crossAxisCount = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 700 ? 4 : 2);
                  final childAspectRatio = constraints.maxWidth < 500 ? 0.84 : 0.88;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: artists.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isMobile ? 12 : 18,
                      mainAxisSpacing: isMobile ? 12 : 18,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, i) {
                      final artistName = artists.keys.elementAt(i);
                      final tracks = artists[artistName]!;
                      final color = Color((artistName.hashCode & 0x00FFFFFF) | 0xFF000000);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedArtist = artistName),
                        child: GlassContainer(
                          borderRadius: isMobile ? 16 : 20,
                          padding: EdgeInsets.all(isMobile ? 10 : 14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isMobile ? 62 : 80,
                                height: isMobile ? 62 : 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [color, MeloColors.tealDeep],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: MeloColors.primaryTeal.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(Icons.person_rounded, size: isMobile ? 32 : 40, color: Colors.white),
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Text(
                                artistName,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tracks.length} tracks',
                                style: TextStyle(fontSize: isMobile ? 11 : 12, color: MeloColors.darkTextMuted),
                              ),
                            ],
                          ),
                        ),
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
    );
  }

  Widget _buildArtistDetailView(String artistName, List<Track> tracks, bool isDark) {
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
              TextButton.icon(
                onPressed: () => setState(() => _selectedArtist = null),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: MeloColors.primaryTeal),
                label: const Text('Back to Artists', style: TextStyle(color: MeloColors.primaryTeal)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: isMobile ? 74 : 100,
                    height: isMobile ? 74 : 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [MeloColors.primaryTeal, MeloColors.tealDeep]),
                    ),
                    child: Center(child: Icon(Icons.person_rounded, size: isMobile ? 38 : 50, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(artistName, style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${tracks.length} tracks cataloged', style: const TextStyle(fontSize: 12, color: MeloColors.primaryTeal), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MeloColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () => widget.audioEngine.playTrack(tracks.first, newQueue: tracks),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Play Artist', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: widget.audioEngine,
                builder: (context, _) {
                  final curTrackId = widget.audioEngine.currentTrack?.id;
                  final isPlaying = widget.audioEngine.isPlaying;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tracks.length,
                    itemBuilder: (context, i) {
                      final t = tracks[i];
                      return TrackRow(
                        key: ValueKey(t.id),
                        track: t,
                        index: i,
                        isCurrent: curTrackId == t.id,
                        isPlaying: isPlaying,
                        onTap: () => widget.audioEngine.playTrack(t, newQueue: tracks),
                        onToggleFavorite: () => widget.libraryRepo.toggleFavorite(t.id),
                        onPlayNext: () => widget.audioEngine.playNext(t),
                        onAddToQueue: () => widget.audioEngine.addToQueue(t),
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
    );
  }
}
