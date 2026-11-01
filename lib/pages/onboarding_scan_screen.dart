import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../services/library_repository.dart';
import '../widgets/glass_container.dart';
import '../widgets/melo_logo.dart';

class OnboardingScanScreen extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final VoidCallback onComplete;

  const OnboardingScanScreen({
    super.key,
    required this.libraryRepo,
    required this.onComplete,
  });

  @override
  State<OnboardingScanScreen> createState() => _OnboardingScanScreenState();
}

class _OnboardingScanScreenState extends State<OnboardingScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasCheckedPermission = false;
  bool _hasPermission = false;
  bool _scanStarted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _checkPermissionAndAutoStart();
  }

  Future<void> _checkPermissionAndAutoStart() async {
    final granted = await widget.libraryRepo.hasStoragePermission();
    if (!mounted) return;
    setState(() {
      _hasCheckedPermission = true;
      _hasPermission = granted;
    });

    if (granted) {
      _startScanning();
    }
  }

  void _startScanning() {
    setState(() => _scanStarted = true);
    widget.libraryRepo.runInitialScan();
  }

  Future<void> _requestAndScan() async {
    final granted = await widget.libraryRepo.requestStoragePermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = granted;
      _scanStarted = true;
    });
    widget.libraryRepo.runInitialScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeloColors.darkBgBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MeloLogo(fontSize: 38),
              const SizedBox(height: 10),
              const Text(
                '100% Offline • Zero Telemetry • Instant Sound',
                style: TextStyle(
                  color: MeloColors.darkTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              if (!_scanStarted && !_hasPermission && _hasCheckedPermission) ...[
                // Permission Request Card
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MeloColors.primaryTeal.withValues(alpha: 0.15),
                          border: Border.all(
                            color: MeloColors.primaryTeal.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.folder_shared_rounded,
                          color: MeloColors.tealLight,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Full Drive Storage Access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: MeloColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'To automatically find and organize all your music across your device storage and SD cards, Melo needs storage permission.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: MeloColors.darkTextMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeloColors.primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: MeloColors.primaryTeal.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _requestAndScan,
                        icon: const Icon(Icons.security_update_good_rounded, size: 20),
                        label: const Text(
                          'Grant Storage Access',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _startScanning,
                        child: const Text(
                          'Continue with Sample Tracks',
                          style: TextStyle(
                            color: MeloColors.darkTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Animated Teal Radar Wave Rings
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final t = _pulseController.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ring
                        Transform.scale(
                          scale: 1.0 + (t * 0.8),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MeloColors.primaryTeal.withValues(alpha: (1.0 - t) * 0.45),
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        // Middle Ring
                        Transform.scale(
                          scale: 1.0 + ((t + 0.5) % 1.0 * 0.6),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MeloColors.tealLight.withValues(alpha: (1.0 - ((t + 0.5) % 1.0)) * 0.55),
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        // Center Pulsing Orb
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [MeloColors.tealLight, MeloColors.tealDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MeloColors.primaryTeal.withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Status and Counter
                ListenableBuilder(
                  listenable: widget.libraryRepo,
                  builder: (context, _) {
                    final isScanning = widget.libraryRepo.isScanning;
                    final count = widget.libraryRepo.scannedFileCount;
                    final folder = widget.libraryRepo.currentScanFolder;

                    return Column(
                      children: [
                        Text(
                          isScanning ? 'Finding your music…' : 'Library Ready!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: MeloColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            isScanning
                                ? 'Scanning: $folder'
                                : '${widget.libraryRepo.tracks.length} tracks cataloged in ${widget.libraryRepo.crates.length} crates',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: MeloColors.darkTextMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Live Counter Capsule
                        GlassContainer(
                          borderRadius: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.music_note_rounded,
                                size: 16,
                                color: MeloColors.primaryTeal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count files detected',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: MeloColors.tealLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Open App Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MeloColors.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: MeloColors.primaryTeal.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: widget.onComplete,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text(
                    'Open Melo Player',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
}
