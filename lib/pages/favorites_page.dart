import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/audio_engine.dart';
import '../services/library_repository.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/track_row.dart';
import 'playlists_page.dart';

class FavoritesPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;
  final int initialTab;

  const FavoritesPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
    this.initialTab = 0,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.libraryRepo,
      builder: (context, _) {
        final favorites = widget.libraryRepo.favorites;
        final playlists = widget.libraryRepo.playlists;

        return AmbientGlow(
          dominantColor: _selectedTab == 0 ? MeloColors.favoriteRed : MeloColors.primaryTeal,
          opacity: 0.15,
          child: Column(
            children: [
              // Segmented Tab Switcher (Favorites | Playlists)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Row(
                  children: [
                    _buildTabPill(
                      index: 0,
                      title: 'Favorites',
                      count: favorites.length,
                      icon: Icons.favorite_rounded,
                      activeColor: MeloColors.favoriteRed,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildTabPill(
                      index: 1,
                      title: 'Playlists',
                      count: playlists.length,
                      icon: Icons.queue_music_rounded,
                      activeColor: MeloColors.primaryTeal,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Active Tab Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildFavoritesContent(favorites, isDark)
                    : PlaylistsPage(
                        libraryRepo: widget.libraryRepo,
                        audioEngine: widget.audioEngine,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabPill({
    required int index,
    required String title,
    required int count,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;

    return Material(
      color: isSelected
          ? activeColor.withValues(alpha: isDark ? 0.22 : 0.15)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.6)
                  : (isDark ? Colors.white10 : Colors.black12),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? activeColor
                    : (isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : MeloColors.lightTextPrimary)
                      : (isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.28)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? activeColor
                        : (isDark ? MeloColors.darkTextMuted : MeloColors.lightTextMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesContent(List<Track> favorites, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final horizPadding = isMobile ? 16.0 : 24.0;
        final vertPadding = isMobile ? 12.0 : 16.0;

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
                    Row(
                      children: [
                        Container(
                          width: isMobile ? 74 : 90,
                          height: isMobile ? 74 : 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
                            gradient: const LinearGradient(
                              colors: [MeloColors.favoriteRed, MeloColors.tealDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MeloColors.favoriteRed.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(Icons.favorite_rounded, color: Colors.white, size: isMobile ? 36 : 44),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loved Tracks',
                                style: TextStyle(
                                  fontSize: isMobile ? 22 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${favorites.length} loved tracks',
                                style: const TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              if (favorites.isNotEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MeloColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => widget.audioEngine.playTrack(favorites.first, newQueue: List.from(favorites)),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: const Text('Play Favorites', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            if (favorites.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 50, color: MeloColors.darkTextMuted),
                        SizedBox(height: 12),
                        Text('No favorite songs yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Tap the + / heart icon on any track to add it here', style: TextStyle(color: MeloColors.darkTextMuted, fontSize: 13)),
                      ],
                    ),
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
                      itemCount: favorites.length,
                      itemBuilder: (context, i) {
                        final t = favorites[i];
                        return TrackRow(
                          key: ValueKey(t.id),
                          track: t,
                          index: i,
                          isCurrent: curTrackId == t.id,
                          isPlaying: isPlaying,
                          onTap: () => widget.audioEngine.playTrack(t, newQueue: List.from(favorites)),
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
  }
}
