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
    final isCompact = MediaQuery.sizeOf(context).width < 650;

    final baseRowColor = widget.isCurrent
        ? MeloColors.primaryTeal.withValues(alpha: isDark ? 0.20 : 0.14)
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
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14, vertical: 8),
          decoration: BoxDecoration(
            color: baseRowColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.isCurrent
                ? Border.all(
                    color: MeloColors.primaryTeal.withValues(alpha: 0.45),
                    width: 1.5,
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
                                fontWeight: FontWeight.w600,
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
                    widget.isCurrent && widget.isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                    size: isCompact ? 18 : 20,
                    color: Colors.white.withValues(alpha: 0.9),
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
                        fontWeight: widget.isCurrent ? FontWeight.w700 : FontWeight.w600,
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
              // Album (Desktop only)
              if (!isCompact)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.track.album,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              // Format Pill (.flac / .wav / .mp3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (widget.track.extension == 'FLAC' || widget.track.extension == 'WAV')
                      ? MeloColors.primaryTeal.withValues(alpha: 0.15)
                      : (isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.track.extension,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: (widget.track.extension == 'FLAC' || widget.track.extension == 'WAV')
                        ? MeloColors.tealLight
                        : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              // Favorite button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                icon: Icon(
                  widget.track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: widget.track.isFavorite
                      ? MeloColors.favoriteRed
                      : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                ),
                onPressed: widget.onToggleFavorite,
                tooltip: widget.track.isFavorite ? 'Remove favorite' : 'Add favorite',
              ),
              // Duration
              SizedBox(
                width: isCompact ? 36 : 46,
                child: Text(
                  _formatDuration(widget.track.duration),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                  ),
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
                        SizedBox(width: 10),
                        Text(widget.track.isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
