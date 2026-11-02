import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import 'bouncing_tap.dart';
import 'live_visualizer.dart';
import 'song_artwork.dart';

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
        ? (isDark ? MeloColors.tealLight : Colors.black)
        : (isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: BouncingTap(
        onTap: widget.onTap,
        scaleDown: 0.965,
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
                width: isCompact ? 24 : 34,
                child: Center(
                  child: widget.isCurrent && widget.isPlaying
                      ? const LiveVisualizer(
                          isPlaying: true,
                          barCount: 3,
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
              SongArtwork(
                track: widget.track,
                width: isCompact ? 36 : 40,
                height: isCompact ? 36 : 40,
                borderRadius: BorderRadius.circular(8),
                fallbackPlaceholder: Container(
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
              const SizedBox(width: 8),
              // Functional Favorite Heart on the right edge
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                splashRadius: 18,
                icon: Icon(
                  widget.track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: widget.track.isFavorite
                      ? MeloColors.favoriteRed
                      : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                ),
                onPressed: () {
                  widget.onToggleFavorite();
                  setState(() {});
                },
                tooltip: widget.track.isFavorite ? 'Remove favorite' : 'Add favorite',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
