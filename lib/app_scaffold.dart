import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/melo_theme.dart';
import 'models/folder_crate.dart';
import 'pages/albums_page.dart';
import 'pages/artists_page.dart';
import 'pages/favorites_page.dart';
import 'pages/folder_detail_page.dart';
import 'pages/folders_page.dart';
import 'pages/home_page.dart';
import 'pages/playlists_page.dart';
import 'pages/recently_played_page.dart';
import 'pages/settings_page.dart';
import 'pages/songs_page.dart';
import 'services/audio_engine.dart';
import 'services/latency_probe.dart';
import 'services/library_repository.dart';
import 'widgets/floating_player_bar.dart';
import 'widgets/latency_probe_overlay.dart';
import 'widgets/melo_logo.dart';
import 'widgets/now_playing_panel.dart';
import 'widgets/track_row.dart';

enum AppNavRoute {
  home,
  folders,
  folderDetail,
  songs,
  albums,
  artists,
  favorites,
  recentlyPlayed,
  playlists,
  settings,
}

class AppScaffold extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const AppScaffold({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  AppNavRoute _currentRoute = AppNavRoute.home;
  FolderCrate? _selectedFolderCrate;
  bool _isRightPanelOpen = false;
  bool _isSidebarCollapsed = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Setup error callback toast
    widget.audioEngine.onError = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: MeloColors.favoriteRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Do not trigger shortcuts when typing in search
    if (_searchFocusNode.hasFocus) return;

    final key = event.logicalKey;
    final isControl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Ctrl+Shift+L: Latency probe overlay
    if (isControl && isShift && key == LogicalKeyboardKey.keyL) {
      LatencyProbe().toggleOverlay();
      return;
    }

    // Ctrl+K or '/': Focus search
    if ((isControl && key == LogicalKeyboardKey.keyK) || key == LogicalKeyboardKey.slash) {
      _searchFocusNode.requestFocus();
      return;
    }

    // Ctrl+,: Settings
    if (isControl && key == LogicalKeyboardKey.comma) {
      setState(() => _currentRoute = AppNavRoute.settings);
      return;
    }

    // Space: Play/Pause
    if (key == LogicalKeyboardKey.space) {
      widget.audioEngine.togglePlayPause();
      return;
    }

    // Shift + Left/Right: Prev/Next
    if (isShift && key == LogicalKeyboardKey.arrowRight) {
      widget.audioEngine.next();
      return;
    }
    if (isShift && key == LogicalKeyboardKey.arrowLeft) {
      widget.audioEngine.previous();
      return;
    }

    // Left/Right: Seek -/+ 5s
    if (key == LogicalKeyboardKey.arrowRight) {
      final currentPos = widget.audioEngine.positionNotifier.value;
      widget.audioEngine.seek(currentPos + const Duration(seconds: 5));
      return;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      final currentPos = widget.audioEngine.positionNotifier.value;
      final target = currentPos - const Duration(seconds: 5);
      widget.audioEngine.seek(target < Duration.zero ? Duration.zero : target);
      return;
    }

    // Up/Down: Volume +/- 5%
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.audioEngine.setVolume(widget.audioEngine.volume + 0.05);
      return;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.audioEngine.setVolume(widget.audioEngine.volume - 0.05);
      return;
    }

    // M: Mute
    if (key == LogicalKeyboardKey.keyM) {
      widget.audioEngine.toggleMute();
      return;
    }

    // S: Shuffle
    if (key == LogicalKeyboardKey.keyS) {
      widget.audioEngine.toggleShuffle();
      return;
    }

    // R: Repeat
    if (key == LogicalKeyboardKey.keyR) {
      widget.audioEngine.cycleRepeatMode();
      return;
    }

    // L: Like current track
    if (key == LogicalKeyboardKey.keyL && widget.audioEngine.currentTrack != null) {
      widget.libraryRepo.toggleFavorite(widget.audioEngine.currentTrack!.id);
      return;
    }
  }

  void _openFolderDetail(FolderCrate crate) {
    setState(() {
      _selectedFolderCrate = crate;
      _currentRoute = AppNavRoute.folderDetail;
    });
  }

  void _toggleNowPlaying() {
    setState(() {
      _isRightPanelOpen = !_isRightPanelOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Scaffold(
            backgroundColor: isDark ? MeloColors.darkBgBase : MeloColors.lightBgBase,
            body: Stack(
              children: [
                // Main Application Layout
                Row(
                  children: [
                    // Left Navigation Sidebar (Desktop/Tablet)
                    if (isDesktop) _buildSidebar(isDark),

                    // Center Content Region
                    Expanded(
                      child: Column(
                        children: [
                          // Global Top Search & Status Bar
                          _buildTopBar(isDark, isDesktop),

                          // Dynamic Page Content or Search Results
                          Expanded(
                            child: _searchController.text.trim().isNotEmpty
                                ? _buildSearchResults(isDark)
                                : _buildActivePage(),
                          ),
                        ],
                      ),
                    ),

                    // Right Now Playing Panel (Desktop Wide)
                    if (isDesktop && _isRightPanelOpen)
                      SizedBox(
                        width: 320,
                        child: NowPlayingPanel(
                          audioEngine: widget.audioEngine,
                          libraryRepo: widget.libraryRepo,
                          onClose: () => setState(() => _isRightPanelOpen = false),
                        ),
                      ),
                  ],
                ),

                // Floating Glass Bottom Player Bar
                Positioned(
                  left: isDesktop ? (_isSidebarCollapsed ? 76 : 240) : 0,
                  right: (isDesktop && _isRightPanelOpen) ? 320 : 0,
                  bottom: 0,
                  child: FloatingPlayerBar(
                    audioEngine: widget.audioEngine,
                    libraryRepo: widget.libraryRepo,
                    onToggleNowPlaying: () {
                      if (isDesktop) {
                        _toggleNowPlaying();
                      } else {
                        // Open bottom modal sheet on mobile
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => FractionallySizedBox(
                            heightFactor: 0.92,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                              child: NowPlayingPanel(
                                audioEngine: widget.audioEngine,
                                libraryRepo: widget.libraryRepo,
                                onClose: () => Navigator.pop(ctx),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Latency Probe Debug Overlay (Ctrl+Shift+L)
                const LatencyProbeOverlay(),
              ],
            ),
            // Bottom navigation bar for mobile compact view
            bottomNavigationBar: !isDesktop ? _buildMobileBottomBar(isDark) : null,
          );
        },
      ),
    );
  }

  Widget _buildTopBar(bool isDark, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 12,
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? MeloColors.darkSurface1.withValues(alpha: 0.5) : MeloColors.lightSurface1.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            const MeloLogo(fontSize: 18),
            const SizedBox(width: 10),
          ],
          // Search Input Field
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? MeloColors.darkSurface2 : MeloColors.lightSurface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: MeloColors.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: isDesktop
                            ? 'Search songs, artists, albums, or folders (Ctrl+K)...'
                            : 'Search songs, artists...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 14 : 8),
          // Latency Probe status button
          IconButton(
            icon: const Icon(Icons.speed_rounded, size: 20),
            color: MeloColors.tealLight,
            tooltip: 'Instant Playback Latency Probe (Ctrl+Shift+L)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => LatencyProbe().toggleOverlay(),
          ),
          // Now Playing toggle (Desktop)
          if (isDesktop)
            IconButton(
              icon: Icon(
                _isRightPanelOpen ? Icons.view_sidebar_rounded : Icons.view_sidebar_outlined,
                size: 20,
              ),
              color: _isRightPanelOpen ? MeloColors.primaryTeal : MeloColors.darkTextSecondary,
              tooltip: 'Toggle Now Playing Panel',
              onPressed: _toggleNowPlaying,
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    final width = _isSidebarCollapsed ? 76.0 : 230.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
        border: Border(
          right: BorderSide(color: isDark ? MeloColors.darkBorder : MeloColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Collapse button
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 12, top: 20, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSidebarCollapsed) const MeloLogo(fontSize: 22),
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                    size: 20,
                  ),
                  color: MeloColors.darkTextSecondary,
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  tooltip: _isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Main Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(AppNavRoute.home, Icons.home_rounded, 'Home'),
                  _buildNavItem(AppNavRoute.folders, Icons.folder_rounded, 'Folders & Crates'),
                  _buildNavItem(AppNavRoute.songs, Icons.music_note_rounded, 'Songs'),
                  _buildNavItem(AppNavRoute.albums, Icons.album_rounded, 'Albums'),
                  _buildNavItem(AppNavRoute.artists, Icons.person_rounded, 'Artists'),
                  const SizedBox(height: 12),
                  if (!_isSidebarCollapsed) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 6),
                      child: Text(
                        'MY COLLECTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                  _buildNavItem(AppNavRoute.favorites, Icons.favorite_rounded, 'Favorites'),
                  _buildNavItem(AppNavRoute.recentlyPlayed, Icons.history_rounded, 'Recently Played'),
                  _buildNavItem(AppNavRoute.playlists, Icons.queue_music_rounded, 'Playlists'),
                ],
              ),
            ),
          ),

          // Bottom Settings Item
          Padding(
            padding: const EdgeInsets.all(10),
            child: _buildNavItem(AppNavRoute.settings, Icons.settings_rounded, 'Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(AppNavRoute route, IconData icon, String title) {
    final isSelected = _currentRoute == route;
    final isDark = widget.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected
            ? MeloColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _searchController.clear();
            setState(() => _currentRoute = route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? MeloColors.primaryTeal
                      : (isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? MeloColors.darkTextPrimary : MeloColors.tealDeep)
                            : (isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomBar(bool isDark) {
    return NavigationBar(
      backgroundColor: isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1,
      indicatorColor: MeloColors.primaryTeal.withValues(alpha: 0.25),
      selectedIndex: _routeToBottomIndex(_currentRoute),
      onDestinationSelected: (idx) {
        _searchController.clear();
        setState(() {
          _currentRoute = _bottomIndexToRoute(idx);
        });
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.folder_rounded), label: 'Folders'),
        NavigationDestination(icon: Icon(Icons.music_note_rounded), label: 'Songs'),
        NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Favorites'),
        NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }

  int _routeToBottomIndex(AppNavRoute route) {
    switch (route) {
      case AppNavRoute.home:
        return 0;
      case AppNavRoute.folders:
      case AppNavRoute.folderDetail:
        return 1;
      case AppNavRoute.songs:
      case AppNavRoute.albums:
      case AppNavRoute.artists:
        return 2;
      case AppNavRoute.favorites:
      case AppNavRoute.recentlyPlayed:
      case AppNavRoute.playlists:
        return 3;
      case AppNavRoute.settings:
        return 4;
    }
  }

  AppNavRoute _bottomIndexToRoute(int index) {
    switch (index) {
      case 0:
        return AppNavRoute.home;
      case 1:
        return AppNavRoute.folders;
      case 2:
        return AppNavRoute.songs;
      case 3:
        return AppNavRoute.favorites;
      case 4:
        return AppNavRoute.settings;
      default:
        return AppNavRoute.home;
    }
  }

  Widget _buildActivePage() {
    switch (_currentRoute) {
      case AppNavRoute.home:
        return HomePage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
          onOpenFolder: _openFolderDetail,
          onNavigateFolders: () => setState(() => _currentRoute = AppNavRoute.folders),
          onNavigateSongs: () => setState(() => _currentRoute = AppNavRoute.songs),
        );
      case AppNavRoute.folders:
        return FoldersPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
          onOpenFolder: _openFolderDetail,
        );
      case AppNavRoute.folderDetail:
        return _selectedFolderCrate != null
            ? FolderDetailPage(
                crate: _selectedFolderCrate!,
                audioEngine: widget.audioEngine,
                libraryRepo: widget.libraryRepo,
                onBack: () => setState(() => _currentRoute = AppNavRoute.folders),
              )
            : FoldersPage(
                libraryRepo: widget.libraryRepo,
                audioEngine: widget.audioEngine,
                onOpenFolder: _openFolderDetail,
              );
      case AppNavRoute.songs:
        return SongsPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
        );
      case AppNavRoute.albums:
        return AlbumsPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
        );
      case AppNavRoute.artists:
        return ArtistsPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
        );
      case AppNavRoute.favorites:
        return FavoritesPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
        );
      case AppNavRoute.recentlyPlayed:
        return RecentlyPlayedPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
        );
      case AppNavRoute.playlists:
        return PlaylistsPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
        );
      case AppNavRoute.settings:
        return SettingsPage(
          libraryRepo: widget.libraryRepo,
          audioEngine: widget.audioEngine,
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        );
    }
  }

  Widget _buildSearchResults(bool isDark) {
    final query = _searchController.text.trim();
    final results = widget.libraryRepo.search(query);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 16 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search results for "$query"',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${results.length} tracks found',
                style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 18),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No tracks match your query', style: TextStyle(color: MeloColors.darkTextMuted)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final t = results[i];
                    return TrackRow(
                      track: t,
                      index: i,
                      isCurrent: widget.audioEngine.currentTrack?.id == t.id,
                      isPlaying: widget.audioEngine.isPlaying,
                      onTap: () => widget.audioEngine.playTrack(t, newQueue: results),
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
