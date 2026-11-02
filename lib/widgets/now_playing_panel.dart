import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/audio_output_service.dart';
import '../services/artwork_service.dart';
import '../services/library_repository.dart';
import 'bouncing_tap.dart';
import 'song_artwork.dart';
import 'track_row.dart';

class NowPlayingPanel extends StatefulWidget {
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;
  final VoidCallback? onClose;

  const NowPlayingPanel({
    super.key,
    required this.audioEngine,
    required this.libraryRepo,
    this.onClose,
  });

  @override
  State<NowPlayingPanel> createState() => _NowPlayingPanelState();
}

class _NowPlayingPanelState extends State<NowPlayingPanel> {
  bool _isDraggingSlider = false;
  double _dragSliderValue = 0.0;
  late PageController _artPageController;
  int _lastSyncedIndex = 0;
  bool _isUserDraggingPage = false;

  @override
  void initState() {
    super.initState();

    final queue = widget.audioEngine.queue;
    final curIdx = widget.audioEngine.currentIndex;
    _lastSyncedIndex = (curIdx >= 0 && curIdx < queue.length) ? curIdx : 0;
    _artPageController = PageController(
      initialPage: _lastSyncedIndex,
      viewportFraction: 0.76,
    );
    widget.audioEngine.addListener(_onAudioEngineChanged);
  }

  @override
  void dispose() {
    widget.audioEngine.removeListener(_onAudioEngineChanged);
    _artPageController.dispose();
    super.dispose();
  }

  void _onAudioEngineChanged() {
    if (!mounted) return;
    final queue = widget.audioEngine.queue;
    final curIdx = widget.audioEngine.currentIndex;
    if (queue.isEmpty) return;

    if (curIdx >= 0 && curIdx < queue.length && curIdx != _lastSyncedIndex) {
      _lastSyncedIndex = curIdx;
      if (_artPageController.hasClients && !_isUserDraggingPage) {
        final currentPage = _artPageController.page?.round();
        if (currentPage != curIdx) {
          _artPageController.animateToPage(
            curIdx,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }



  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Compute the immersive teal ambient top gradient tint for dark mode
  Color _getAmbientColor(Track track) {
    // Generate a deep, curated teal organic dominant color
    final hash = track.id.hashCode;
    final r = 12 + ((hash >> 16) & 0x1F); // 12..43
    final g = 65 + ((hash >> 8) & 0x2F);  // 65..112
    final b = 70 + (hash & 0x2F);         // 70..117
    return Color.fromARGB(255, r, g, b);
  }

  /// Compute the fresh luminous ambient top gradient tint for light mode
  Color _getLightAmbientColor(Track track) {
    final hash = track.id.hashCode;
    final r = 202 + ((hash >> 16) & 0x1F); // 202..233
    final g = 240 + ((hash >> 8) & 0x0D);  // 240..253
    final b = 236 + (hash & 0x0F);         // 236..251
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.audioEngine,
      builder: (context, _) {
        final track = widget.audioEngine.currentTrack;

        if (track == null) {
          return Container(
            color: isDark ? MeloColors.darkBgBase : MeloColors.lightBgBase,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No track playing',
                style: TextStyle(
                  color: isDark ? Colors.white70 : MeloColors.lightTextSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        final dominant = _getAmbientColor(track);
        final lightDominant = _getLightAmbientColor(track);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        dominant,
                        Color.lerp(dominant, MeloColors.darkBgBase, 0.5)!,
                        MeloColors.darkBgBase,
                        const Color(0xFF040809),
                      ]
                    : [
                        lightDominant,
                        Color.lerp(lightDominant, MeloColors.lightBgBase, 0.45)!,
                        MeloColors.lightBgBase,
                        const Color(0xFFEDF2F7),
                      ],
                stops: isDark
                    ? const [0.0, 0.42, 0.78, 1.0]
                    : const [0.0, 0.38, 0.72, 1.0],
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactHeight = constraints.maxHeight < 680;
                  final horizontalPadding = constraints.maxWidth > 500 ? 32.0 : 24.0;
                  final maxArtHeight = constraints.maxHeight * (isCompactHeight ? 0.38 : 0.44);
                  final artSize = min(constraints.maxWidth * 0.70, maxArtHeight).clamp(180.0, 340.0);

                  return Column(
                    children: [
                      // 1. Top Bar: Down Chevron, Title, 3 Dots
                      _buildTopBar(track, isDark),

                      // 2. Main Content
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 2a. Swipable Album Artwork Carousel (Edge-to-edge, gap, stacking animation)
                            _buildSwipableArtwork(track, artSize, widget.audioEngine.queue),

                            // Padded Controls Section
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 2b. Track Title, Artist & Quick Add/Favorite
                                  _buildTrackInfoRow(track, isDark),
                                  const SizedBox(height: 12),

                                  // 2c. Scrubber / Slider with Timestamps
                                  _buildScrubberSection(isDark),
                                  const SizedBox(height: 8),

                                  // 2d. Player Controls (Shuffle, Prev, Play/Pause, Next, Repeat)
                                  _buildPlayerControls(isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Bottom Output Device Bar & Queue Actions
                      _buildBottomBar(track, isDark),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Swipable Album Artwork Carousel (Swipe left/right with gap & stacking animation)
  Widget _buildSwipableArtwork(Track track, double artSize, List<Track> queue) {
    final effectiveQueue = queue.isNotEmpty ? queue : [track];
    final curIdx = widget.audioEngine.currentIndex;
    final safeCurIdx = (curIdx >= 0 && curIdx < effectiveQueue.length)
        ? curIdx
        : effectiveQueue.indexWhere((t) => t.id == track.id);
    final targetIndex = safeCurIdx >= 0 ? safeCurIdx : 0;

    // Check if PageController is mounted and needs synchronization
    if (_artPageController.hasClients && !_isUserDraggingPage) {
      final currentPage = _artPageController.page?.round();
      if (currentPage != null && currentPage != targetIndex && _lastSyncedIndex != targetIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _artPageController.hasClients && !_isUserDraggingPage) {
            _lastSyncedIndex = targetIndex;
            _artPageController.jumpToPage(targetIndex);
          }
        });
      }
    }

    return SizedBox(
      height: artSize + 28,
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              if (notification.dragDetails != null) {
                _isUserDraggingPage = true;
              }
            } else if (notification is ScrollEndNotification) {
              _isUserDraggingPage = false;
            }
            return false;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: PageView.builder(
              controller: _artPageController,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: effectiveQueue.length,
              onPageChanged: (index) {
                _lastSyncedIndex = index;
                if (index >= 0 && index < effectiveQueue.length) {
                  final targetTrack = effectiveQueue[index];
                  if (targetTrack.id != widget.audioEngine.currentTrack?.id) {
                    widget.audioEngine.playTrack(targetTrack);
                    HapticFeedback.lightImpact();
                  }
                }
              },
              itemBuilder: (context, index) {
                final t = effectiveQueue[index];
                return AnimatedBuilder(
                  animation: _artPageController,
                  builder: (context, child) {
                    double page = _lastSyncedIndex.toDouble();
                    if (_artPageController.hasClients &&
                        _artPageController.position.haveDimensions) {
                      page = _artPageController.page ?? _lastSyncedIndex.toDouble();
                    }
                    final diff = page - index;
                    final absDiff = diff.abs().clamp(0.0, 1.0);

                    // Stacking Card Deck Scale: Front card is 1.0, stacked adjacent card is ~0.86
                    final scale = (1.0 - (absDiff * 0.14)).clamp(0.70, 1.0);

                    // Stacking Opacity: Front card is 1.0, stacked cards are 0.60
                    final opacity = (1.0 - (absDiff * 0.40)).clamp(0.40, 1.0);

                    // Stacking Vertical Shift (Depth): Stacked cards sit slightly lower
                    final translateY = absDiff * 12.0;

                    // Stacking Fan Angle (Tilt like CardSwiper):
                    final tiltAngle = diff * -0.05;

                    // 3D Perspective rotation:
                    final rotateY = diff * 0.14;

                    return Transform.translate(
                      offset: Offset(0.0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // 3D depth perspective
                            ..rotateZ(tiltAngle.clamp(-0.08, 0.08))
                            ..rotateY(rotateY.clamp(-0.22, 0.22)),
                          child: Opacity(
                            opacity: opacity,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: SongArtwork(
                        track: t,
                        width: artSize,
                        height: artSize,
                        borderRadius: BorderRadius.circular(18),
                        showShadow: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Top Bar
  Widget _buildTopBar(Track track, bool isDark) {
    final mediaQuery = MediaQuery.of(context);
    // viewPadding.top preserves the immutable status bar height (cutout/notification icons)
    final statusBarHeight = mediaQuery.viewPadding.top > 0
        ? mediaQuery.viewPadding.top
        : mediaQuery.padding.top;
    final topMargin = max(statusBarHeight, 26.0) + 8.0;

    return Padding(
      padding: EdgeInsets.only(left: 8, right: 8, top: topMargin, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncingTap(
            scaleDown: 0.82,
            onTap: widget.onClose ?? () => Navigator.maybePop(context),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 34,
                color: isDark ? Colors.white : MeloColors.lightTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PLAYING FROM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: isDark ? Colors.white.withValues(alpha: 0.65) : MeloColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.folderName.isNotEmpty && track.folderName != 'Internal Storage'
                      ? track.folderName
                      : 'Now Playing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          BouncingTap(
            scaleDown: 0.82,
            onTap: () => _showOptionsMenu(track),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.more_vert_rounded,
                size: 24,
                color: isDark ? Colors.white : MeloColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Track Info Row
  Widget _buildTrackInfoRow(Track track, bool isDark) {
    return ListenableBuilder(
      listenable: widget.libraryRepo,
      builder: (context, _) {
        final isFav = track.isFavorite;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withValues(alpha: 0.70) : MeloColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BouncingTap(
              scaleDown: 0.82,
              onTap: () => _showAddToCollectionModal(track),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  isFav ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  size: 30,
                  color: isFav
                      ? MeloColors.primaryTeal
                      : (isDark ? Colors.white : MeloColors.lightTextPrimary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Modal: Add to Favorites & Add to Playlist with Create Playlist option
  void _showAddToCollectionModal(Track track) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isFav = widget.libraryRepo.favorites.any((t) => t.id == track.id);
          final playlists = widget.libraryRepo.playlists;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom.clamp(0.0, 1000.0) + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Track Info Header
                  Row(
                    children: [
                      SongArtwork(
                        track: track,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : MeloColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: isDark ? Colors.white12 : MeloColors.lightBorder,
                    height: 24,
                  ),

                  // Option 1: Add to Favorites
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      widget.libraryRepo.toggleFavorite(track.id);
                      HapticFeedback.lightImpact();
                      setModalState(() {});
                      setState(() {});
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav ? 'Removed from Favorites' : 'Saved to Favorites',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: MeloColors.tealDeep,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFav
                              ? MeloColors.primaryTeal.withValues(alpha: 0.3)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isFav
                                  ? MeloColors.favoriteRed.withValues(alpha: 0.18)
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav
                                  ? MeloColors.favoriteRed
                                  : (isDark ? Colors.white70 : MeloColors.lightTextSecondary),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFav ? 'Added to Favorites' : 'Add to Favorites',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isFav
                                      ? 'Saved in your Loved Tracks'
                                      : 'Tap to save track to your Loved Tracks',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : MeloColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isFav ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            color: isFav
                                ? MeloColors.primaryTeal
                                : (isDark ? Colors.white38 : MeloColors.lightTextMuted),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Option 2: Add to Playlist header & Create Playlist button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add to Playlist',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeloColors.primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showCreatePlaylistForTrackDialog(track, setModalState),
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text(
                          'Create Playlist',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Playlists List
                  if (playlists.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      margin: const EdgeInsets.only(top: 2, bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white10 : MeloColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.playlist_add_rounded, color: MeloColors.primaryTeal, size: 36),
                          const SizedBox(height: 6),
                          Text(
                            'No playlists created yet',
                            style: TextStyle(
                              color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap "Create Playlist" above to make your first playlist',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : MeloColors.lightTextMuted,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        separatorBuilder: (context, index) => Divider(
                          color: isDark ? Colors.white10 : MeloColors.lightBorder,
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          final pl = playlists[i];
                          final isInPl = pl.trackIds.contains(track.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? MeloColors.tealDeep.withValues(alpha: 0.35)
                                    : MeloColors.primaryTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.queue_music_rounded,
                                color: isDark ? MeloColors.tealLight : MeloColors.tealDeep,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              pl.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${pl.trackIds.length} tracks',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : MeloColors.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              isInPl ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              color: isInPl
                                  ? MeloColors.primaryTeal
                                  : (isDark ? Colors.white38 : MeloColors.lightTextMuted),
                              size: 24,
                            ),
                            onTap: () {
                              if (isInPl) {
                                widget.libraryRepo.removeTrackFromPlaylist(pl.id, track.id);
                              } else {
                                widget.libraryRepo.addTrackToPlaylist(pl.id, track.id);
                              }
                              HapticFeedback.lightImpact();
                              setModalState(() {});
                              setState(() {});
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isInPl ? 'Removed from "${pl.name}"' : 'Added to "${pl.name}"',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: MeloColors.tealDeep,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Create Playlist dialog invoked directly from collection modal
  void _showCreatePlaylistForTrackDialog(
    Track track,
    void Function(void Function()) setModalState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Create New Playlist',
          style: TextStyle(
            color: isDark ? Colors.white : MeloColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : MeloColors.lightTextPrimary),
          decoration: InputDecoration(
            hintText: 'Playlist name (e.g., Chill Vibes)',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : MeloColors.lightTextMuted),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : MeloColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MeloColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                widget.libraryRepo.createPlaylist(name);
                // Also add track to this newly created playlist
                final created = widget.libraryRepo.playlists.lastWhere((p) => p.name == name);
                widget.libraryRepo.addTrackToPlaylist(created.id, track.id);
                Navigator.pop(dialogCtx);
                setModalState(() {});
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created "$name" and added "${track.title}"'),
                    backgroundColor: MeloColors.tealDeep,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  // Scrubber Section
  Widget _buildScrubberSection(bool isDark) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.audioEngine.durationNotifier,
      builder: (context, duration, _) {
        final maxSeconds = duration.inMilliseconds.toDouble();

        return ValueListenableBuilder<Duration>(
          valueListenable: widget.audioEngine.positionNotifier,
          builder: (context, position, _) {
            final posMs = position.inMilliseconds.toDouble();
            final currentSliderValue = _isDraggingSlider
                ? _dragSliderValue
                : (maxSeconds > 0 ? posMs.clamp(0.0, maxSeconds) : 0.0);

            final activeTrackColor = isDark ? Colors.white : MeloColors.tealDeep;
            final inactiveTrackColor = isDark
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.12);
            final thumbColor = isDark ? Colors.white : MeloColors.tealDeep;
            final timestampColor = isDark
                ? Colors.white.withValues(alpha: 0.65)
                : MeloColors.lightTextMuted;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.5,
                    activeTrackColor: activeTrackColor,
                    inactiveTrackColor: inactiveTrackColor,
                    thumbColor: thumbColor,
                    overlayColor: activeTrackColor.withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: maxSeconds > 0 ? currentSliderValue.clamp(0.0, maxSeconds) : 0.0,
                    min: 0.0,
                    max: maxSeconds > 0 ? maxSeconds : 1.0,
                    onChangeStart: (val) {
                      setState(() {
                        _isDraggingSlider = true;
                        _dragSliderValue = val;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        _dragSliderValue = val;
                      });
                    },
                    onChangeEnd: (val) {
                      _isDraggingSlider = false;
                      widget.audioEngine.seek(Duration(milliseconds: val.round()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(
                          _isDraggingSlider
                              ? Duration(milliseconds: _dragSliderValue.round())
                              : position,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: timestampColor,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: timestampColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Playback Controls Row (Shuffle, Previous, Play/Pause, Next, Repeat)
  Widget _buildPlayerControls(bool isDark) {
    final isShuffle = widget.audioEngine.isShuffle;
    final repeatMode = widget.audioEngine.repeatMode;
    final isRepeatActive = repeatMode != MeloRepeatMode.off;
    final isPlaying = widget.audioEngine.isPlaying;

    const activeColor = MeloColors.primaryTeal;
    final inactiveColor = isDark ? Colors.white : MeloColors.lightTextSecondary;
    final controlColor = isDark ? Colors.white : MeloColors.lightTextPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle Button
        BouncingTap(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.audioEngine.toggleShuffle();
          },
          scaleDown: 0.84,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shuffle_rounded,
                  size: 26,
                  color: isShuffle ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isShuffle ? activeColor : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Previous Track Button
        BouncingTap(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.audioEngine.previous();
          },
          scaleDown: 0.84,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              Icons.skip_previous_rounded,
              size: 42,
              color: controlColor,
            ),
          ),
        ),

        // Large Play/Pause Button
        BouncingTap(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.audioEngine.togglePlayPause();
          },
          scaleDown: 0.88,
          child: Material(
            color: isDark ? Colors.white : MeloColors.tealDeep,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: isDark ? Colors.black45 : MeloColors.tealDeep.withValues(alpha: 0.35),
            child: Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),

        // Next Track Button
        BouncingTap(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.audioEngine.next();
          },
          scaleDown: 0.84,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              Icons.skip_next_rounded,
              size: 42,
              color: controlColor,
            ),
          ),
        ),

        // Repeat Button
        BouncingTap(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.audioEngine.cycleRepeatMode();
          },
          scaleDown: 0.84,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  repeatMode == MeloRepeatMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  size: 26,
                  color: isRepeatActive ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRepeatActive ? activeColor : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Bottom Output Device & Queue Bar
  Widget _buildBottomBar(Track track, bool isDark) {
    final routeAccent = isDark ? MeloColors.primaryTeal : MeloColors.tealDeep;
    final actionColor = isDark ? Colors.white : MeloColors.lightTextPrimary;
    final outputService = AudioOutputService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Audio Device Output Route (Dynamic Bluetooth TWS / Speaker)
          ValueListenableBuilder<AudioOutputDevice>(
            valueListenable: outputService.currentOutput,
            builder: (context, currentDevice, _) {
              return BouncingTap(
                scaleDown: 0.94,
                onTap: _showAudioOutputDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentDevice.icon,
                        size: 19,
                        color: routeAccent,
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          currentDevice.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: routeAccent,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Actions: Share & Queue
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BouncingTap(
                scaleDown: 0.84,
                onTap: () => _shareTrack(track),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.share_outlined,
                    size: 22,
                    color: actionColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              BouncingTap(
                scaleDown: 0.84,
                onTap: () => _showQueueModal(track),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.queue_music_rounded,
                    size: 24,
                    color: actionColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Share Track info
  void _shareTrack(Track track) {
    Clipboard.setData(ClipboardData(text: 'Now Playing: ${track.title} by ${track.artist} on Melo'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${track.title}" to clipboard'),
        backgroundColor: MeloColors.tealDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Audio Output Selector Dialog
  void _showAudioOutputDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outputService = AudioOutputService();
    outputService.refreshOutputs();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ValueListenableBuilder<AudioOutputDevice>(
            valueListenable: outputService.currentOutput,
            builder: (context, activeDev, _) {
              return ValueListenableBuilder<List<AudioOutputDevice>>(
                valueListenable: outputService.availableOutputs,
                builder: (context, devices, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Audio Output Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white70 : MeloColors.lightTextSecondary,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...devices.map((d) {
                        final isSelected = d.id == activeDev.id && d.type == activeDev.type;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Icon(
                            d.icon,
                            color: isSelected
                                ? MeloColors.primaryTeal
                                : (isDark ? Colors.white70 : MeloColors.lightTextSecondary),
                          ),
                          title: Text(
                            d.name,
                            style: TextStyle(
                              color: isSelected
                                  ? MeloColors.primaryTeal
                                  : (isDark ? Colors.white : MeloColors.lightTextPrimary),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            d.isBluetooth
                                ? 'Connected via Bluetooth'
                                : (d.isSpeaker ? 'Built-in phone speaker' : 'Wired audio connection'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : MeloColors.lightTextMuted,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: MeloColors.primaryTeal)
                              : null,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            outputService.switchToDevice(d);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                      // System output switcher button for Android
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(Icons.settings_bluetooth_rounded, color: MeloColors.primaryTeal),
                        title: Text(
                          'Bluetooth & System Media Switcher',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                          ),
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: MeloColors.primaryTeal),
                        onTap: () {
                          outputService.openOutputSettings();
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Options Menu (3 dots)
  void _showOptionsMenu(Track track) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  SongArtwork(
                    track: track,
                    width: 52,
                    height: 52,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : MeloColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color: isDark ? Colors.white12 : MeloColors.lightBorder,
                height: 28,
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: MeloColors.primaryTeal),
                title: Text(
                  'Refresh / Fetch Online Artwork',
                  style: TextStyle(color: isDark ? Colors.white : MeloColors.lightTextPrimary),
                ),
                subtitle: Text(
                  'Fetch latest cover art from iTunes / Deezer',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : MeloColors.lightTextMuted,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = await ArtworkService().fetchOnlineArtwork(track);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(url != null ? 'Artwork updated successfully!' : 'No new online artwork found.'),
                        backgroundColor: MeloColors.tealDeep,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? Colors.white70 : MeloColors.lightTextSecondary,
                ),
                title: Text(
                  'Track Details',
                  style: TextStyle(color: isDark ? Colors.white : MeloColors.lightTextPrimary),
                ),
                subtitle: Text(
                  '${track.extension} • ${track.bitrate != null ? "${track.bitrate} kbps" : "Lossless"} • ${track.album}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : MeloColors.lightTextMuted,
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(
                  Icons.timer_outlined,
                  color: isDark ? Colors.white70 : MeloColors.lightTextSecondary,
                ),
                title: Text(
                  'Sleep Timer',
                  style: TextStyle(color: isDark ? Colors.white : MeloColors.lightTextPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSleepTimerDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
        title: Text(
          'Sleep Timer',
          style: TextStyle(color: isDark ? Colors.white : MeloColors.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 45, 60].map((mins) {
            return ListTile(
              title: Text(
                '$mins Minutes',
                style: TextStyle(color: isDark ? Colors.white : MeloColors.lightTextPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Future.delayed(Duration(minutes: mins), () {
                  widget.audioEngine.togglePlayPause();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sleep timer set for $mins minutes'),
                    backgroundColor: MeloColors.tealDeep,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Up Next Queue & Lyrics Bottom Sheet
  void _showQueueModal(Track currentTrack) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TabBar(
                indicatorColor: MeloColors.primaryTeal,
                labelColor: MeloColors.primaryTeal,
                unselectedLabelColor: isDark ? Colors.white60 : MeloColors.lightTextMuted,
                tabs: const [
                  Tab(icon: Icon(Icons.queue_music_rounded), text: 'Up Next'),
                  Tab(icon: Icon(Icons.lyrics_rounded), text: 'Lyrics'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildQueueList(isDark),
                    _buildLyrics(currentTrack, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueList(bool isDark) {
    final queue = widget.audioEngine.queue;
    final currentIndex = widget.audioEngine.currentIndex;

    if (queue.isEmpty) {
      return Center(
        child: Text(
          'Queue is empty',
          style: TextStyle(color: isDark ? Colors.white60 : MeloColors.lightTextSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: queue.length,
      itemBuilder: (context, i) {
        final t = queue[i];
        final isCur = i == currentIndex;

        return TrackRow(
          key: ValueKey(t.id),
          track: t,
          index: i,
          isCurrent: isCur,
          isPlaying: widget.audioEngine.isPlaying,
          onTap: () => widget.audioEngine.playTrack(t),
          onToggleFavorite: () => widget.libraryRepo.toggleFavorite(t.id),
          onPlayNext: () => widget.audioEngine.playNext(t),
          onAddToQueue: () => widget.audioEngine.addToQueue(t),
        );
      },
    );
  }

  Widget _buildLyrics(Track track, bool isDark) {
    final lyrics = track.lyrics ??
        '♪ Instrumental / Offline Track ♪\n\n[00:04.00] Immersive frequencies floating in space\n[00:08.50] Deep organic tones, no internet required\n[00:12.00] Instant playback pulsing in your headphones\n[00:16.00] Pure offline sound, crystal clear clarity\n[00:20.00] Melo beats continue...';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        lyrics,
        style: TextStyle(
          fontSize: 15,
          height: 1.9,
          color: isDark ? Colors.white : MeloColors.lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
