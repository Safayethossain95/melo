import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/glass_container.dart';
import '../widgets/track_row.dart';

class AlbumsPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;

  const AlbumsPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
  });

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  String? _selectedAlbum;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final albums = widget.libraryRepo.albums;

    if (_selectedAlbum != null) {
      final albumTracks = albums[_selectedAlbum!] ?? [];
      return _buildAlbumDetailView(_selectedAlbum!, albumTracks, isDark);
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
                'Albums',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${albums.length} releases in your local library',
                style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 700 ? 3 : 2);
                  final childAspectRatio = constraints.maxWidth < 500
                      ? 0.78
                      : (constraints.maxWidth < 800 ? 0.82 : 0.85);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: albums.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isMobile ? 12 : 18,
                      mainAxisSpacing: isMobile ? 12 : 18,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, i) {
                      final albumName = albums.keys.elementAt(i);
                      final tracks = albums[albumName]!;
                      final artist = tracks.first.artist;
                      final color = Color((albumName.hashCode & 0x00FFFFFF) | 0xFF000000);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedAlbum = albumName),
                        child: GlassContainer(
                          borderRadius: isMobile ? 16 : 20,
                          padding: EdgeInsets.all(isMobile ? 10 : 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                    gradient: LinearGradient(
                                      colors: [color, MeloColors.tealDeep],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.album_rounded, size: isMobile ? 38 : 54, color: Colors.white70),
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Text(
                                albumName,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$artist • ${tracks.length} tracks',
                                style: TextStyle(fontSize: isMobile ? 11 : 12, color: MeloColors.darkTextMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

  Widget _buildAlbumDetailView(String albumName, List<Track> tracks, bool isDark) {
    final color = Color((albumName.hashCode & 0x00FFFFFF) | 0xFF000000);
    final artist = tracks.isNotEmpty ? tracks.first.artist : 'Unknown Artist';

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
                onPressed: () => setState(() => _selectedAlbum = null),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: MeloColors.primaryTeal),
                label: const Text('Back to Albums', style: TextStyle(color: MeloColors.primaryTeal)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: isMobile ? 90 : 120,
                    height: isMobile ? 90 : 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
                      gradient: LinearGradient(colors: [color, MeloColors.tealDeep]),
                    ),
                    child: Center(child: Icon(Icons.album_rounded, size: isMobile ? 42 : 54, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(albumName, style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('$artist • ${tracks.length} tracks', style: const TextStyle(fontSize: 12, color: MeloColors.primaryTeal), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MeloColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () => widget.audioEngine.playTrack(tracks.first, newQueue: tracks),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Play Album', style: TextStyle(fontSize: 13)),
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
