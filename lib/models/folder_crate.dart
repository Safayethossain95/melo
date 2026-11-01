import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import 'track.dart';

class FolderCrate {
  final String folderPath;
  final String folderName;
  final List<Track> tracks;
  final List<FolderCrate> subfolders;

  FolderCrate({
    required this.folderPath,
    required this.folderName,
    required this.tracks,
    this.subfolders = const [],
  });

  int get trackCount => tracks.length;

  Duration get totalDuration {
    int totalMs = 0;
    for (final t in tracks) {
      totalMs += t.duration.inMilliseconds;
    }
    return Duration(milliseconds: totalMs);
  }

  /// 3 stacked sleeves colors for the crate visual
  List<Color> get sleeveColors {
    final hash = folderName.hashCode.abs();
    final palette = [
      MeloColors.primaryTeal,
      MeloColors.tealDeep,
      const Color(0xFF2DD4BF),
      const Color(0xFF0284C7), // Blue-teal
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
    ];

    return [
      palette[hash % palette.length],
      palette[(hash ~/ 3 + 2) % palette.length],
      palette[(hash ~/ 7 + 4) % palette.length],
    ];
  }
}
