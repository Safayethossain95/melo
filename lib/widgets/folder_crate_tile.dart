import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/folder_crate.dart';
import 'glass_container.dart';

class FolderCrateTile extends StatefulWidget {
  final FolderCrate crate;
  final VoidCallback onTap;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  const FolderCrateTile({
    super.key,
    required this.crate,
    required this.onTap,
    required this.onPlayAll,
    required this.onShuffle,
  });

  @override
  State<FolderCrateTile> createState() => _FolderCrateTileState();
}

class _FolderCrateTileState extends State<FolderCrateTile> {
  bool _isHovered = false;

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sleeveColors = widget.crate.sleeveColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final cardPadding = isCompact ? 10.0 : 16.0;
        final sleeveHeight = isCompact ? 86.0 : 124.0;
        final sleeve1Size = isCompact ? 76.0 : 112.0;
        final sleeve2Size = isCompact ? 70.0 : 106.0;
        final sleeve3Size = isCompact ? 64.0 : 100.0;
        final folderIconSize = isCompact ? 28.0 : 40.0;
        final grooveCircleSize = isCompact ? 46.0 : 70.0;
        final titleFontSize = isCompact ? 13.0 : 16.0;
        final metaFontSize = isCompact ? 11.0 : 12.0;
        final vSpacing = isCompact ? 8.0 : 14.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
              child: GlassContainer(
                borderRadius: isCompact ? 16.0 : 22.0,
                padding: EdgeInsets.all(cardPadding),
                backgroundColor: _isHovered
                    ? (isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stacked Sleeves "Crate" Visual
                    SizedBox(
                      height: sleeveHeight,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Sleeve 3 (Deepest back, tilted left)
                          Positioned(
                            top: isCompact ? 2 : 4,
                            child: Transform.rotate(
                              angle: -0.12,
                              child: Container(
                                width: sleeve3Size,
                                height: sleeve3Size,
                                decoration: BoxDecoration(
                                  color: sleeveColors.length > 2
                                      ? sleeveColors[2].withValues(alpha: 0.6)
                                      : MeloColors.tealDeep,
                                  borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Sleeve 2 (Middle, tilted right)
                          Positioned(
                            top: isCompact ? 5 : 8,
                            child: Transform.rotate(
                              angle: 0.10,
                              child: Container(
                                width: sleeve2Size,
                                height: sleeve2Size,
                                decoration: BoxDecoration(
                                  color: sleeveColors.length > 1
                                      ? sleeveColors[1].withValues(alpha: 0.75)
                                      : MeloColors.primaryTeal,
                                  borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Sleeve 1 (Front sleeve, centered & prominent)
                          Positioned(
                            top: isCompact ? 9 : 14,
                            child: Container(
                              width: sleeve1Size,
                              height: sleeve1Size,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    sleeveColors[0],
                                    Color.lerp(sleeveColors[0], Colors.black, 0.4)!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                                boxShadow: [
                                  BoxShadow(
                                    color: MeloColors.primaryTeal.withValues(alpha: _isHovered ? 0.35 : 0.15),
                                    blurRadius: _isHovered ? 16 : 8,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Subtle vinyl groove circle watermark
                                  Center(
                                    child: Container(
                                      width: grooveCircleSize,
                                      height: grooveCircleSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.folder_rounded,
                                      size: folderIconSize,
                                      color: Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),
                                  // Floating Play button on hover
                                  if (_isHovered)
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Material(
                                        color: MeloColors.primaryTeal,
                                        shape: const CircleBorder(),
                                        elevation: 6,
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: widget.onPlayAll,
                                          child: Padding(
                                            padding: EdgeInsets.all(isCompact ? 6.0 : 8.0),
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: isCompact ? 16 : 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: vSpacing),
                    // Folder Title
                    Text(
                      widget.crate.folderName,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Metadata: Track Count & Duration
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${widget.crate.trackCount} ${widget.crate.trackCount == 1 ? "track" : "tracks"}',
                            style: TextStyle(
                              fontSize: metaFontSize,
                              fontWeight: FontWeight.w500,
                              color: MeloColors.primaryTeal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: metaFontSize,
                            color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _formatDuration(widget.crate.totalDuration),
                            style: TextStyle(
                              fontSize: metaFontSize,
                              color: isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
