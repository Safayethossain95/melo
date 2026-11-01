import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/folder_crate.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/folder_crate_tile.dart';
import '../widgets/glass_container.dart';

enum FolderViewMode { grid, list, tree }
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
  FolderViewMode _viewMode = FolderViewMode.grid;
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
              // Header & View Toggles
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => widget.libraryRepo.importFolder(),
                      icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                      label: const Text('Add Folder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const Spacer(),
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewIconButton(FolderViewMode.grid, Icons.grid_view_rounded, 'Grid view'),
                          _buildViewIconButton(FolderViewMode.list, Icons.view_list_rounded, 'List view'),
                          _buildViewIconButton(FolderViewMode.tree, Icons.account_tree_rounded, 'Tree view'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort menu
                    PopupMenuButton<FolderSortBy>(
                      icon: Icon(
                        Icons.sort_rounded,
                        color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                      ),
                      tooltip: 'Sort by',
                      color: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
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
                        const PopupMenuItem(value: FolderSortBy.name, child: Text('Sort by Name')),
                        const PopupMenuItem(value: FolderSortBy.trackCount, child: Text('Sort by Track Count')),
                        const PopupMenuItem(value: FolderSortBy.duration, child: Text('Sort by Duration')),
                      ],
                    ),
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

                    // Controls: Add Folder, View Mode Toggle, Sort
                    Row(
                      children: [
                        // Import folder button
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
                        // View mode toggle
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildViewIconButton(FolderViewMode.grid, Icons.grid_view_rounded, 'Grid view'),
                              _buildViewIconButton(FolderViewMode.list, Icons.view_list_rounded, 'List view'),
                              _buildViewIconButton(FolderViewMode.tree, Icons.account_tree_rounded, 'Tree view'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sort menu
                        PopupMenuButton<FolderSortBy>(
                          icon: Icon(
                            Icons.sort_rounded,
                            color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                          ),
                          tooltip: 'Sort by',
                          color: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
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
                            const PopupMenuItem(value: FolderSortBy.name, child: Text('Sort by Name')),
                            const PopupMenuItem(value: FolderSortBy.trackCount, child: Text('Sort by Track Count')),
                            const PopupMenuItem(value: FolderSortBy.duration, child: Text('Sort by Duration')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Content by View Mode
              if (crates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.folder_off_rounded, size: 56, color: MeloColors.darkTextMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No folders cataloged yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => widget.libraryRepo.importFiles(),
                          child: const Text('Pick Audio Files'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_viewMode == FolderViewMode.grid) ...[
                Builder(
                  builder: (context) {
                    final crossAxisCount = constraints.maxWidth > 1100
                        ? 4
                        : (constraints.maxWidth > 750 ? 3 : 2);
                    final childAspectRatio = constraints.maxWidth < 500
                        ? 0.78
                        : (constraints.maxWidth < 800 ? 0.82 : 0.88);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: crates.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: isMobile ? 12 : 18,
                        mainAxisSpacing: isMobile ? 12 : 18,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, i) {
                        final crate = crates[i];
                        return FolderCrateTile(
                          crate: crate,
                          onTap: () => widget.onOpenFolder(crate),
                          onPlayAll: () {
                            if (crate.tracks.isNotEmpty) {
                              widget.audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                            }
                          },
                          onShuffle: () {
                            if (crate.tracks.isNotEmpty) {
                              widget.audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                              if (!widget.audioEngine.isShuffle) widget.audioEngine.toggleShuffle();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ] else if (_viewMode == FolderViewMode.list) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: crates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final crate = crates[i];
                return GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  onTap: () => widget.onOpenFolder(crate),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: crate.sleeveColors.first,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.folder_rounded, color: Colors.white, size: 26)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crate.folderName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${crate.trackCount} tracks • ${_formatDuration(crate.totalDuration)} • ${crate.folderPath}',
                              style: const TextStyle(fontSize: 12, color: MeloColors.darkTextMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 32, color: MeloColors.primaryTeal),
                        onPressed: () {
                          if (crate.tracks.isNotEmpty) {
                            widget.audioEngine.playTrack(crate.tracks.first, newQueue: crate.tracks);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            // Tree View
            _buildTreeView(crates, isDark),
          ],

          const SizedBox(height: 120),
        ],
      ),
    );
  },
);
  }

  Widget _buildViewIconButton(FolderViewMode mode, IconData icon, String tooltip) {
    final isSelected = _viewMode == mode;
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: isSelected ? MeloColors.primaryTeal : MeloColors.darkTextMuted,
      ),
      onPressed: () => setState(() => _viewMode = mode),
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildTreeView(List<FolderCrate> crates, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: crates.map((crate) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
          ),
          child: ExpansionTile(
            leading: Icon(Icons.folder_rounded, color: crate.sleeveColors.first),
            title: Text(
              crate.folderName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              '${crate.trackCount} tracks • ${_formatDuration(crate.totalDuration)}',
              style: const TextStyle(fontSize: 12, color: MeloColors.darkTextMuted),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: MeloColors.primaryTeal),
              onPressed: () => widget.onOpenFolder(crate),
            ),
            children: crate.tracks.map((t) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.music_note_rounded, size: 16, color: MeloColors.primaryTeal),
                title: Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(t.artist, style: const TextStyle(fontSize: 11, color: MeloColors.darkTextMuted)),
                trailing: Text(_formatDuration(t.duration), style: const TextStyle(fontSize: 12)),
                onTap: () => widget.audioEngine.playTrack(t, newQueue: crate.tracks),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }
}
