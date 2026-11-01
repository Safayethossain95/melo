import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../services/audio_engine.dart';
import '../services/latency_probe.dart';
import '../services/library_repository.dart';
import '../widgets/glass_container.dart';
import '../widgets/melo_logo.dart';

class SettingsPage extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final MeloAudioEngine audioEngine;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const SettingsPage({
    super.key,
    required this.libraryRepo,
    required this.audioEngine,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _crossfadeDuration = 2.0;
  bool _gaplessPlayback = true;
  bool _replayGain = true;
  bool _keepAudioAwake = false;
  bool? _storagePermissionGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await widget.libraryRepo.hasStoragePermission();
    if (mounted) {
      setState(() => _storagePermissionGranted = granted);
    }
  }

  Future<void> _requestPermission() async {
    final granted = await widget.libraryRepo.requestStoragePermission();
    if (mounted) {
      setState(() => _storagePermissionGranted = granted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission restricted. Please enable it in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => widget.libraryRepo.openPermissionSettings(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All Drive Storage permission granted!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 24.0,
            vertical: isMobile ? 16.0 : 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Preferences, library management, and audio playback engine',
                style: TextStyle(fontSize: 13, color: MeloColors.primaryTeal, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // 1. Library & Storage Section
              _buildSectionHeader('Library & Folders'),
              const SizedBox(height: 10),
              GlassContainer(
                borderRadius: 18,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: _storagePermissionGranted == true ? Icons.check_circle_rounded : Icons.folder_special_rounded,
                      title: 'All Drive Storage Access',
                      subtitle: _storagePermissionGranted == true
                          ? 'Full drive access granted (auto-scans phone storage & SD cards)'
                          : 'Permission required to auto-discover all songs across all storage drives',
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _storagePermissionGranted == true ? MeloColors.tealDeep : MeloColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _requestPermission,
                        child: Text(_storagePermissionGranted == true ? 'Permissions' : 'Grant Access'),
                      ),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    _buildActionTile(
                      icon: Icons.create_new_folder_rounded,
                      title: 'Add Folder to Library',
                      subtitle: 'Select specific local folders to include in automatic crate indexing',
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: MeloColors.primaryTeal, foregroundColor: Colors.white),
                        onPressed: () => widget.libraryRepo.importFolder(),
                        child: const Text('Add Folder'),
                      ),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    _buildActionTile(
                      icon: Icons.audio_file_rounded,
                      title: 'Import Audio Files',
                      subtitle: 'Pick audio files directly (.mp3, .flac, .wav, .ogg, .m4a)',
                      trailing: OutlinedButton(
                        onPressed: () => widget.libraryRepo.importFiles(),
                        child: const Text('Pick Files'),
                      ),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    _buildActionTile(
                      icon: Icons.refresh_rounded,
                      title: 'Rescan All Drives',
                      subtitle: 'Scan internal storage, SD cards, and folders for all music',
                      trailing: OutlinedButton(
                        onPressed: () async {
                          await widget.libraryRepo.runInitialScan();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Rescan complete: ${widget.libraryRepo.tracks.length} tracks cataloged in ${widget.libraryRepo.crates.length} crates.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Rescan Now'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Playback & Audio Engine Section
              _buildSectionHeader('Instant Audio Engine'),
              const SizedBox(height: 10),
              GlassContainer(
                borderRadius: 18,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    // Crossfade
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Crossfade Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Smooth transition duration between tracks', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                          ],
                        ),
                        Text(
                          '${_crossfadeDuration.toStringAsFixed(1)}s',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: MeloColors.primaryTeal),
                        ),
                      ],
                    ),
                    Slider(
                      value: _crossfadeDuration,
                      min: 0.0,
                      max: 12.0,
                      divisions: 24,
                      onChanged: (val) => setState(() => _crossfadeDuration = val),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    // Gapless toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gapless Playback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Zero silence between consecutive tracks', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                      value: _gaplessPlayback,
                      activeThumbColor: MeloColors.primaryTeal,
                      onChanged: (val) => setState(() => _gaplessPlayback = val),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    // ReplayGain toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Volume Normalization (ReplayGain)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Balances volume across varied audio masters', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                      value: _replayGain,
                      activeThumbColor: MeloColors.primaryTeal,
                      onChanged: (val) => setState(() => _replayGain = val),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    // Keep audio awake toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Keep Audio Output Awake', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Holds audio device awake to eliminate Bluetooth startup latency', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                      value: _keepAudioAwake,
                      activeThumbColor: MeloColors.primaryTeal,
                      onChanged: (val) => setState(() => _keepAudioAwake = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Appearance & Diagnostics
              _buildSectionHeader('Appearance & Performance Diagnostics'),
              const SizedBox(height: 10),
              GlassContainer(
                borderRadius: 18,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Theme (Default)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Toggle between deep ink-teal black and soft light theme', style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                      value: widget.isDarkMode,
                      activeThumbColor: MeloColors.primaryTeal,
                      onChanged: widget.onThemeToggle,
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    _buildActionTile(
                      icon: Icons.speed_rounded,
                      title: 'Instant Playback Latency Probe',
                      subtitle: 'Show real-time click-to-sound performance overlay (Ctrl+Shift+L)',
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeloColors.tealDeep,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => LatencyProbe().toggleOverlay(),
                        child: const Text('Toggle Overlay'),
                      ),
                    ),
                    const Divider(color: MeloColors.darkBorder),
                    _buildActionTile(
                      icon: Icons.delete_sweep_rounded,
                      title: 'Clear Cache & Reset Library',
                      subtitle: 'Wipe saved index and restore default sample tracks',
                      trailing: TextButton(
                        onPressed: () {
                          widget.libraryRepo.clearCache();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache cleared and sample library restored.')),
                          );
                        },
                        child: const Text('Reset', style: TextStyle(color: MeloColors.favoriteRed)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. About Melo
              _buildSectionHeader('About Melo'),
              const SizedBox(height: 10),
              GlassContainer(
                borderRadius: 18,
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MeloLogo(fontSize: 24),
                    SizedBox(height: 8),
                    Text(
                      'Version 1.0.0 • Pure Offline Desktop & Mobile Architecture\n'
                      'Built with Flutter, just_audio, and high-performance Canvas rendering.\n'
                      'Zero network calls, zero accounts, zero analytics.',
                      style: TextStyle(fontSize: 12, color: MeloColors.darkTextMuted, height: 1.6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: MeloColors.tealLight,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        if (isNarrow) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: MeloColors.primaryTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: trailing,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(icon, size: 22, color: MeloColors.primaryTeal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: MeloColors.darkTextMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        );
      },
    );
  }
}
