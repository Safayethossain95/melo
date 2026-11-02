import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/live_visualizer.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: MeloColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MeloColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  String _formatTrackDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = widget.libraryRepo.playlists;
    final allTracks = widget.libraryRepo.tracks;

    if (_selectedPlaylist != null) {
      return _buildPlaylistDetailView(_selectedPlaylist!, isDark);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return ListenableBuilder(
          listenable: widget.audioEngine,
          builder: (context, _) {
            final currentTrack = widget.audioEngine.currentTrack;
            final isPlaying = widget.audioEngine.isPlaying;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 16.0 : 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
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

                  const SizedBox(height: 20),

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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MeloColors.primaryTeal,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showCreateDialog(context),
                              child: const Text('Create Playlist'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Playlists List like Folders
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: playlists.map((pl) {
                        final tracksInPl = pl.trackIds
                            .map((id) => allTracks.firstWhere((t) => t.id == id, orElse: () => allTracks.first))
                            .where((t) => pl.trackIds.contains(t.id))
                            .toList();

                        return _PlaylistTreeCard(
                          key: ValueKey('playlist_${pl.id}'),
                          playlist: pl,
                          tracks: tracksInPl,
                          isDark: isDark,
                          currentTrack: currentTrack,
                          isPlaying: isPlaying,
                          audioEngine: widget.audioEngine,
                          libraryRepo: widget.libraryRepo,
                          onRename: () => _showRenameDialog(context, pl),
                          onDelete: () {
                            widget.libraryRepo.deletePlaylist(pl.id);
                            setState(() {});
                          },
                          formatDuration: _formatDuration,
                          formatTrackDuration: _formatTrackDuration,
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistDetailView(Playlist pl, bool isDark) {
    final allTracks = widget.libraryRepo.tracks;
    final playlistTracks = pl.trackIds
        .map((id) => allTracks.firstWhere((t) => t.id == id, orElse: () => allTracks.first))
        .where((t) => pl.trackIds.contains(t.id))
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
                    child: Text('Playlist is empty. Add tracks using the "+" button in Now Playing or track rows.', style: TextStyle(color: MeloColors.darkTextMuted)),
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

/// Playlist Card with Expandable Tree Branch List (matching Folders style)
class _PlaylistTreeCard extends StatefulWidget {
  final Playlist playlist;
  final List<Track> tracks;
  final bool isDark;
  final Track? currentTrack;
  final bool isPlaying;
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final String Function(Duration) formatDuration;
  final String Function(Duration) formatTrackDuration;

  const _PlaylistTreeCard({
    super.key,
    required this.playlist,
    required this.tracks,
    required this.isDark,
    required this.currentTrack,
    required this.isPlaying,
    required this.audioEngine,
    required this.libraryRepo,
    required this.onRename,
    required this.onDelete,
    required this.formatDuration,
    required this.formatTrackDuration,
  });

  @override
  State<_PlaylistTreeCard> createState() => _PlaylistTreeCardState();
}

class _PlaylistTreeCardState extends State<_PlaylistTreeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final plColor = Color((widget.playlist.name.hashCode & 0x00FFFFFF) | 0xFF000000);
    final totalDuration = widget.tracks.fold(Duration.zero, (prev, t) => prev + t.duration);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? MeloColors.darkBorder : MeloColors.lightBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('playlist_tree_${widget.playlist.id}'),
          initiallyExpanded: false, // Closed at first, opens with 1 tap like folders
          onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: plColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _isExpanded ? Icons.playlist_play_rounded : Icons.queue_music_rounded,
                color: plColor,
                size: 24,
              ),
            ),
          ),
          title: Text(
            widget.playlist.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: widget.isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            '${widget.tracks.length} tracks • ${widget.formatDuration(totalDuration)}',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tracks.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 28,
                    color: MeloColors.primaryTeal,
                  ),
                  onPressed: () {
                    widget.audioEngine.playTrack(widget.tracks.first, newQueue: widget.tracks);
                  },
                  tooltip: 'Play playlist',
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                ),
                color: widget.isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'rename') {
                    widget.onRename();
                  } else if (val == 'delete') {
                    widget.onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Rename Playlist'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: MeloColors.favoriteRed),
                        SizedBox(width: 10),
                        Text('Delete Playlist', style: TextStyle(color: MeloColors.favoriteRed)),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedRotation(
                turns: _isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                ),
              ),
            ],
          ),
          children: widget.tracks.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                        const SizedBox(width: 8),
                        Text(
                          'No tracks yet. Tap "+" on any song to add it here.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : widget.tracks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final track = entry.value;
                  final isCur = widget.currentTrack?.id == track.id;
                  final isLast = index == widget.tracks.length - 1;

                  return InkWell(
                    onTap: () => widget.audioEngine.playTrack(track, newQueue: widget.tracks),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      color: isCur
                          ? MeloColors.primaryTeal.withValues(alpha: widget.isDark ? 0.16 : 0.10)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          // Tree Branch Connector Line
                          SizedBox(
                            width: 32,
                            height: 38,
                            child: CustomPaint(
                              painter: _TreeBranchPainter(
                                isLast: isLast,
                                color: (widget.isDark ? Colors.white24 : Colors.black26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Mini Icon / Visualizer
                          SizedBox(
                            width: 22,
                            child: isCur && widget.isPlaying
                                ? const LiveVisualizer(isPlaying: true, barCount: 3, height: 14)
                                : Icon(
                                    Icons.music_note_rounded,
                                    size: 16,
                                    color: isCur
                                        ? MeloColors.primaryTeal
                                        : (widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          // Track Title & Artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.title,
                                  style: TextStyle(
                                    fontWeight: isCur ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 13,
                                    color: isCur
                                        ? (widget.isDark ? MeloColors.tealLight : Colors.black)
                                        : (widget.isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  track.artist,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Track Duration
                          Text(
                            widget.formatTrackDuration(track.duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: isCur
                                  ? MeloColors.primaryTeal
                                  : (widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Remove from playlist button
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 17),
                            color: widget.isDark ? Colors.white38 : Colors.black38,
                            tooltip: 'Remove from playlist',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () {
                              widget.libraryRepo.removeTrackFromPlaylist(widget.playlist.id, track.id);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed "${track.title}" from ${widget.playlist.name}'),
                                  backgroundColor: MeloColors.tealDeep,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}

/// Custom painter to draw clean tree branch connector lines
class _TreeBranchPainter extends CustomPainter {
  final bool isLast;
  final Color color;

  _TreeBranchPainter({required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final startX = size.width * 0.4;
    final midY = size.height * 0.5;

    // Vertical line coming from parent or previous sibling
    canvas.drawLine(
      Offset(startX, 0),
      Offset(startX, isLast ? midY : size.height),
      paint,
    );

    // Horizontal elbow branching into the track
    canvas.drawLine(
      Offset(startX, midY),
      Offset(size.width, midY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.color != color;
  }
}
