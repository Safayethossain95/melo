import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/playlist.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/glass_container.dart';
import '../widgets/track_row.dart';

class PlaylistsPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;

  const PlaylistsPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  Playlist? _selectedPlaylist;

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MeloColors.darkSurface1,
        title: const Text('Create New Playlist', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MeloColors.darkTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MeloColors.primaryTeal, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                widget.libraryRepo.createPlaylist(nameCtrl.text.trim(), description: descCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Playlist pl) {
    final nameCtrl = TextEditingController(text: pl.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MeloColors.darkSurface1,
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                widget.libraryRepo.renamePlaylist(pl.id, nameCtrl.text.trim());
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = widget.libraryRepo.playlists;

    if (_selectedPlaylist != null) {
      return _buildPlaylistDetailView(_selectedPlaylist!, isDark);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Playlists',
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlists.length} custom playlists',
                          style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MeloColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 8 : 10,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showCreateDialog(context),
                    icon: Icon(Icons.add_rounded, size: isMobile ? 16 : 18),
                    label: Text(
                      isMobile ? 'New' : 'New Playlist',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (playlists.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.playlist_add_rounded, size: 54, color: MeloColors.darkTextMuted),
                        const SizedBox(height: 12),
                        const Text('No playlists created yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showCreateDialog(context),
                          child: const Text('Create Playlist'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playlists.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 700 ? 3 : 2),
                    crossAxisSpacing: isMobile ? 12 : 18,
                    mainAxisSpacing: isMobile ? 12 : 18,
                    childAspectRatio: constraints.maxWidth < 500 ? 0.78 : 0.88,
                  ),
                  itemBuilder: (context, i) {
                    final pl = playlists[i];
                    final color = Color((pl.name.hashCode & 0x00FFFFFF) | 0xFF000000);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlaylist = pl),
                      child: GlassContainer(
                        borderRadius: 20,
                        padding: EdgeInsets.all(isMobile ? 10 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [color, MeloColors.tealDeep],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(Icons.queue_music_rounded, size: isMobile ? 38 : 50, color: Colors.white70),
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            Text(
                              pl.name,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pl.trackIds.length} tracks',
                              style: TextStyle(fontSize: isMobile ? 11 : 12, color: MeloColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildPlaylistDetailView(Playlist pl, bool isDark) {
    final allTracks = widget.libraryRepo.tracks;
    final playlistTracks = pl.trackIds
        .map((id) => allTracks.firstWhere((t) => t.id == id, orElse: () => allTracks.first))
        .toList();

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedPlaylist = null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16, color: MeloColors.primaryTeal),
                    label: const Text('Back to Playlists', style: TextStyle(color: MeloColors.primaryTeal)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: () => _showRenameDialog(context, pl),
                        tooltip: 'Rename',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: MeloColors.favoriteRed),
                        onPressed: () {
                          widget.libraryRepo.deletePlaylist(pl.id);
                          setState(() => _selectedPlaylist = null);
                        },
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(pl.name, style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w800)),
              if (pl.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(pl.description, style: const TextStyle(fontSize: 13, color: MeloColors.darkTextSecondary)),
              ],
              const SizedBox(height: 6),
              Text('${playlistTracks.length} tracks', style: const TextStyle(fontSize: 12, color: MeloColors.primaryTeal)),
              const SizedBox(height: 16),
              if (playlistTracks.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: MeloColors.primaryTeal, foregroundColor: Colors.white),
                  onPressed: () => widget.audioEngine.playTrack(playlistTracks.first, newQueue: playlistTracks),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play Playlist'),
                ),
              const SizedBox(height: 24),
              if (playlistTracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Playlist is empty. Add tracks from "⋯" menu in Songs or Folders.', style: TextStyle(color: MeloColors.darkTextMuted)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playlistTracks.length,
                  itemBuilder: (context, i) {
                    final t = playlistTracks[i];
                    return TrackRow(
                      track: t,
                      index: i,
                      isCurrent: widget.audioEngine.currentTrack?.id == t.id,
                      isPlaying: widget.audioEngine.isPlaying,
                      onTap: () => widget.audioEngine.playTrack(t, newQueue: playlistTracks),
                      onToggleFavorite: () => widget.libraryRepo.toggleFavorite(t.id),
                      onPlayNext: () => widget.audioEngine.playNext(t),
                      onAddToQueue: () => widget.audioEngine.addToQueue(t),
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
