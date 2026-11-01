import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import 'live_visualizer.dart';

class TrackRow extends StatefulWidget {
  final Track track;
  final int index;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onPlayNext;
  final VoidCallback onAddToQueue;
  final Function(String playlistId)? onAddToPlaylist;

  const TrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onPlayNext,
    required this.onAddToQueue,
    this.onAddToPlaylist,
  });

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  bool _isHovered = false;

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseRowColor = widget.isCurrent
        ? MeloColors.primaryTeal.withValues(alpha: isDark ? 0.16 : 0.12)
        : (_isHovered
            ? (isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2)
            : Colors.transparent);

    final titleColor = widget.isCurrent
        ? MeloColors.tealLight
        : (isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          return GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14, vertical: 8),
              decoration: BoxDecoration(
                color: baseRowColor,
                borderRadius: BorderRadius.circular(12),
                border: widget.isCurrent
                    ? Border.all(
                        color: MeloColors.primaryTeal.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Index / Equalizer / Hover Play
                  SizedBox(
                    width: isCompact ? 22 : 34,
                    child: Center(
                      child: widget.isCurrent && widget.isPlaying
                          ? const LiveVisualizer(
                              isPlaying: true,
                              barCount: 4,
                              height: 14,
                            )
                          : (_isHovered
                              ? Icon(
                                  widget.isCurrent && widget.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 18,
                                  color: MeloColors.primaryTeal,
                                )
                              : Text(
                                  '${widget.index + 1}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isCurrent
                                        ? MeloColors.primaryTeal
                                        : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                                  ),
                                )),
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  // Track Artwork Thumbnail
                  Container(
                    width: isCompact ? 36 : 40,
                    height: isCompact ? 36 : 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Color((widget.track.id.hashCode & 0x00FFFFFF) | 0xFF000000),
                          MeloColors.tealDeep,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        size: isCompact ? 18 : 20,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 14),
                  // Title & Artist
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.title,
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.track.artist,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Album column (hidden on mobile viewports)
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Text(
                        widget.track.album,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Like Button
                  IconButton(
                    icon: Icon(
                      widget.track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: widget.track.isFavorite ? MeloColors.favoriteRed : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                    ),
                    onPressed: widget.onToggleFavorite,
                    tooltip: widget.track.isFavorite ? 'Remove favorite' : 'Add favorite',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  ),
                  SizedBox(width: isCompact ? 6 : 14),
                  // Duration
                  Text(
                    _formatDuration(widget.track.duration),
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Context Menu ("⋯")
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                    ),
                    color: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
                    elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder,
                  ),
                ),
                onSelected: (val) {
                  if (val == 'play_next') widget.onPlayNext();
                  if (val == 'queue') widget.onAddToQueue();
                  if (val == 'favorite') widget.onToggleFavorite();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play_next',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_play_rounded, size: 18, color: MeloColors.primaryTeal),
                        SizedBox(width: 10),
                        Text('Play Next'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'queue',
                    child: Row(
                      children: [
                        Icon(Icons.queue_music_rounded, size: 18, color: MeloColors.primaryTeal),
                        SizedBox(width: 10),
                        Text('Add to Queue'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(
                          widget.track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: MeloColors.favoriteRed,
                        ),
                        const SizedBox(width: 10),
                        Text(widget.track.isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ),
);
  }
}
