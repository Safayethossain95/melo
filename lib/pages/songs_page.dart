import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/track_row.dart';

enum SongSortColumn { title, artist, album, duration, dateAdded }

class SongsPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;

  const SongsPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
  });

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final TextEditingController _filterController = TextEditingController();
  SongSortColumn _sortColumn = SongSortColumn.title;
  bool _ascending = true;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<Track> get _filteredAndSortedTracks {
    final query = _filterController.text.trim().toLowerCase();
    var list = widget.libraryRepo.tracks;

    if (query.isNotEmpty) {
      list = list.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.artist.toLowerCase().contains(query) ||
            t.album.toLowerCase().contains(query);
      }).toList();
    } else {
      list = List.from(list);
    }

    switch (_sortColumn) {
      case SongSortColumn.title:
        list.sort((a, b) => _ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title));
        break;
      case SongSortColumn.artist:
        list.sort((a, b) => _ascending ? a.artist.compareTo(b.artist) : b.artist.compareTo(a.artist));
        break;
      case SongSortColumn.album:
        list.sort((a, b) => _ascending ? a.album.compareTo(b.album) : b.album.compareTo(a.album));
        break;
      case SongSortColumn.duration:
        list.sort((a, b) => _ascending ? a.duration.compareTo(b.duration) : b.duration.compareTo(a.duration));
        break;
      case SongSortColumn.dateAdded:
        list.sort((a, b) => _ascending ? a.addedDate.compareTo(b.addedDate) : b.addedDate.compareTo(a.addedDate));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.libraryRepo,
      builder: (context, _) {
        final tracks = _filteredAndSortedTracks;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
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
                        // Header Row
                        if (isMobile) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Songs',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${tracks.length} tracks • Offline library',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MeloColors.primaryTeal,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                                  onPressed: () {
                                    if (tracks.isNotEmpty) {
                                      widget.audioEngine.playTrack(tracks.first, newQueue: tracks);
                                    }
                                  },
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
                                    if (tracks.isNotEmpty) {
                                      widget.audioEngine.playTrack(tracks.first, newQueue: tracks);
                                      if (!widget.audioEngine.isShuffle) widget.audioEngine.toggleShuffle();
                                    }
                                  },
                                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                                  label: const Text('Shuffle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'All Songs',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tracks.length} tracks • Instant offline playback',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: MeloColors.primaryTeal,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MeloColors.primaryTeal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      if (tracks.isNotEmpty) {
                                        widget.audioEngine.playTrack(tracks.first, newQueue: tracks);
                                      }
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                    label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                      side: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      if (tracks.isNotEmpty) {
                                        widget.audioEngine.playTrack(tracks.first, newQueue: tracks);
                                        if (!widget.audioEngine.isShuffle) widget.audioEngine.toggleShuffle();
                                      }
                                    },
                                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                                    label: const Text('Shuffle'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Instant Filter Search Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list_rounded, size: 18, color: MeloColors.primaryTeal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _filterController,
                                  onChanged: (_) => setState(() {}),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Filter by song title, artist, or album...',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              if (_filterController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _filterController.clear();
                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Table Column Headers: Hidden on Mobile, Sortable on Desktop
                        if (isMobile) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${tracks.length} tracks',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: MeloColors.darkTextMuted,
                                  ),
                                ),
                                PopupMenuButton<SongSortColumn>(
                                  tooltip: 'Sort tracks',
                                  color: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                                  ),
                                  onSelected: (col) {
                                    if (_sortColumn == col) {
                                      setState(() => _ascending = !_ascending);
                                    } else {
                                      setState(() {
                                        _sortColumn = col;
                                        _ascending = true;
                                      });
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: SongSortColumn.title,
                                      child: Text('Title ${_sortColumn == SongSortColumn.title ? (_ascending ? '↑' : '↓') : ''}'),
                                    ),
                                    PopupMenuItem(
                                      value: SongSortColumn.artist,
                                      child: Text('Artist ${_sortColumn == SongSortColumn.artist ? (_ascending ? '↑' : '↓') : ''}'),
                                    ),
                                    PopupMenuItem(
                                      value: SongSortColumn.album,
                                      child: Text('Album ${_sortColumn == SongSortColumn.album ? (_ascending ? '↑' : '↓') : ''}'),
                                    ),
                                    PopupMenuItem(
                                      value: SongSortColumn.duration,
                                      child: Text('Duration ${_sortColumn == SongSortColumn.duration ? (_ascending ? '↑' : '↓') : ''}'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.sort_rounded, size: 14, color: MeloColors.primaryTeal),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sort: ${_sortColumn.name[0].toUpperCase()}${_sortColumn.name.substring(1)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                          size: 12,
                                          color: MeloColors.primaryTeal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 34, child: Center(child: Text('#', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)))),
                                const SizedBox(width: 62),
                                Expanded(
                                  flex: 5,
                                  child: _buildColumnHeader('TITLE', SongSortColumn.title),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 4,
                                  child: _buildColumnHeader('ALBUM', SongSortColumn.album),
                                ),
                                const SizedBox(width: 8),
                                const SizedBox(width: 44),
                              ],
                            ),
                          ),
                          const Divider(color: MeloColors.darkBorder, height: 1),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),

                // Virtualized Track List or Empty State
                if (tracks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No tracks match your filter', style: TextStyle(color: MeloColors.darkTextMuted)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizPadding),
                    sliver: ListenableBuilder(
                      listenable: widget.audioEngine,
                      builder: (context, _) {
                        final curTrackId = widget.audioEngine.currentTrack?.id;
                        final isPlaying = widget.audioEngine.isPlaying;

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
                              onTap: () => widget.audioEngine.playTrack(t, newQueue: tracks),
                              onToggleFavorite: () => widget.libraryRepo.toggleFavorite(t.id),
                              onPlayNext: () => widget.audioEngine.playNext(t),
                              onAddToQueue: () => widget.audioEngine.addToQueue(t),
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

  Widget _buildColumnHeader(String label, SongSortColumn col) {
    final isSelected = _sortColumn == col;
    return InkWell(
      onTap: () {
        if (_sortColumn == col) {
          setState(() => _ascending = !_ascending);
        } else {
          setState(() {
            _sortColumn = col;
            _ascending = true;
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? MeloColors.tealLight : MeloColors.darkTextMuted,
              letterSpacing: 0.8,
            ),
          ),
          if (isSelected)
            Icon(
              _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13,
              color: MeloColors.primaryTeal,
            ),
        ],
      ),
    );
  }
}
