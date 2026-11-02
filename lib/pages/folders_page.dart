import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/folder_crate.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/live_visualizer.dart';

enum FolderSortBy { name, trackCount, duration }

class FoldersPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;
  final Function(FolderCrate) onOpenFolder;

  const FoldersPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
    required this.onOpenFolder,
  });

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  FolderSortBy _sortBy = FolderSortBy.name;
  bool _ascending = true;

  List<FolderCrate> get _sortedCrates {
    final list = List<FolderCrate>.from(widget.libraryRepo.crates);
    switch (_sortBy) {
      case FolderSortBy.name:
        list.sort((a, b) => _ascending
            ? a.folderName.compareTo(b.folderName)
            : b.folderName.compareTo(a.folderName));
        break;
      case FolderSortBy.trackCount:
        list.sort((a, b) => _ascending
            ? a.trackCount.compareTo(b.trackCount)
            : b.trackCount.compareTo(a.trackCount));
        break;
      case FolderSortBy.duration:
        list.sort((a, b) => _ascending
            ? a.totalDuration.compareTo(b.totalDuration)
            : b.totalDuration.compareTo(a.totalDuration));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final crates = _sortedCrates;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 24.0,
            vertical: isMobile ? 16.0 : 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Controls
              if (isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folders & Crates',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${crates.length} music directories cataloged',
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
                    // Import folder button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MeloColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => widget.libraryRepo.importFolder(),
                      icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                      label: const Text('Add Folder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const Spacer(),
                    // Sort menu
                    _buildSortButton(isDark),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Folders & Crates',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${crates.length} music directories cataloged',
                          style: const TextStyle(
                            fontSize: 13,
                            color: MeloColors.primaryTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Controls: Add Folder and Sort
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MeloColors.primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => widget.libraryRepo.importFolder(),
                          icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                          label: const Text('Add Folder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        _buildSortButton(isDark),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Content: Folders Branch Tree Open Style
              if (crates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_rounded,
                          size: 64,
                          color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No music folders indexed yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Add Folder" to index your audio collection',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildTreeView(crates, isDark),

              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortButton(bool isDark) {
    return PopupMenuButton<FolderSortBy>(
      icon: Icon(
        Icons.sort_rounded,
        color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
      ),
      tooltip: 'Sort by',
      color: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (_sortBy == val) {
          setState(() => _ascending = !_ascending);
        } else {
          setState(() {
            _sortBy = val;
            _ascending = true;
          });
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: FolderSortBy.name,
          child: Row(
            children: [
              const Text('Sort by Name'),
              if (_sortBy == FolderSortBy.name) ...[
                const Spacer(),
                Icon(_ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16, color: MeloColors.primaryTeal),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: FolderSortBy.trackCount,
          child: Row(
            children: [
              const Text('Sort by Track Count'),
              if (_sortBy == FolderSortBy.trackCount) ...[
                const Spacer(),
                Icon(_ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16, color: MeloColors.primaryTeal),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: FolderSortBy.duration,
          child: Row(
            children: [
              const Text('Sort by Duration'),
              if (_sortBy == FolderSortBy.duration) ...[
                const Spacer(),
                Icon(_ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16, color: MeloColors.primaryTeal),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Folders Branch Tree View (Closed at first, openable with one tap)
  Widget _buildTreeView(List<FolderCrate> crates, bool isDark) {
    return ListenableBuilder(
      listenable: widget.audioEngine,
      builder: (context, _) {
        final currentTrack = widget.audioEngine.currentTrack;
        final isPlaying = widget.audioEngine.isPlaying;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: crates.map((crate) {
            return _FolderTreeCard(
              key: ValueKey('crate_${crate.folderPath}'),
              crate: crate,
              isDark: isDark,
              currentTrack: currentTrack,
              isPlaying: isPlaying,
              audioEngine: widget.audioEngine,
              onOpenFolder: widget.onOpenFolder,
              formatDuration: _formatDuration,
              formatTrackDuration: _formatTrackDuration,
            );
          }).toList(),
        );
      },
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
}

class _FolderTreeCard extends StatefulWidget {
  final FolderCrate crate;
  final bool isDark;
  final Track? currentTrack;
  final bool isPlaying;
  final MeloAudioEngine audioEngine;
  final Function(FolderCrate) onOpenFolder;
  final String Function(Duration) formatDuration;
  final String Function(Duration) formatTrackDuration;

  const _FolderTreeCard({
    super.key,
    required this.crate,
    required this.isDark,
    required this.currentTrack,
    required this.isPlaying,
    required this.audioEngine,
    required this.onOpenFolder,
    required this.formatDuration,
    required this.formatTrackDuration,
  });

  @override
  State<_FolderTreeCard> createState() => _FolderTreeCardState();
}

class _FolderTreeCardState extends State<_FolderTreeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final folderColor = widget.crate.sleeveColors.first;

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
          key: PageStorageKey<String>('folder_tree_${widget.crate.folderPath}'),
          initiallyExpanded: false, // Closed at first, opens with one tap
          onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: folderColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                color: folderColor,
                size: 24,
              ),
            ),
          ),
          title: Text(
            widget.crate.folderName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: widget.isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            '${widget.crate.trackCount} tracks • ${widget.formatDuration(widget.crate.totalDuration)}',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 28,
                  color: MeloColors.primaryTeal,
                ),
                onPressed: () {
                  if (widget.crate.tracks.isNotEmpty) {
                    widget.audioEngine.playTrack(widget.crate.tracks.first, newQueue: widget.crate.tracks);
                  }
                },
                tooltip: 'Play all in folder',
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
          children: widget.crate.tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            final isCur = widget.currentTrack?.id == track.id;
            final isLast = index == widget.crate.tracks.length - 1;

            return InkWell(
              onTap: () => widget.audioEngine.playTrack(track, newQueue: widget.crate.tracks),
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
                              color: isCur ? MeloColors.primaryTeal : (widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
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
                              fontSize: 13,
                              fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                              color: isCur
                                  ? MeloColors.primaryTeal
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
                    // Duration
                    Text(
                      widget.formatTrackDuration(track.duration),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: widget.isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                      ),
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
