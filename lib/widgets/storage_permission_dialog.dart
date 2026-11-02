import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/melo_theme.dart';
import '../services/library_repository.dart';
import 'bouncing_tap.dart';

class StoragePermissionDialog extends StatefulWidget {
  final LibraryRepository libraryRepo;
  final VoidCallback? onGranted;

  const StoragePermissionDialog({
    super.key,
    required this.libraryRepo,
    this.onGranted,
  });

  /// Static helper to display the popup with smooth glassmorphism transition
  static Future<bool?> show(
    BuildContext context, {
    required LibraryRepository libraryRepo,
    VoidCallback? onGranted,
  }) {
    if (kIsWeb) return Future.value(true);

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Permission Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return StoragePermissionDialog(
          libraryRepo: libraryRepo,
          onGranted: onGranted,
        );
      },
    );
  }

  @override
  State<StoragePermissionDialog> createState() => _StoragePermissionDialogState();
}

class _StoragePermissionDialogState extends State<StoragePermissionDialog> {
  bool _isRequesting = false;
  bool _showSettingsPrompt = false;

  Future<void> _handleGrant() async {
    setState(() => _isRequesting = true);
    HapticFeedback.mediumImpact();

    try {
      final granted = await widget.libraryRepo.requestStoragePermission();

      if (!mounted) return;

      if (granted) {
        widget.onGranted?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Storage permission granted! Discovering music...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: MeloColors.tealDeep,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() {
          _isRequesting = false;
          _showSettingsPrompt = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _handleOpenSettings() async {
    HapticFeedback.lightImpact();
    await widget.libraryRepo.openPermissionSettings();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? MeloColors.darkSurface1 : MeloColors.lightSurface1;
    final borderColor = isDark ? MeloColors.darkBorder : MeloColors.lightBorder;
    final titleColor = isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary;
    final subtitleColor = isDark ? MeloColors.darkTextSecondary : MeloColors.lightTextSecondary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: isDark ? 0.92 : 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: borderColor.withValues(alpha: isDark ? 0.35 : 0.20),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.12),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: MeloColors.primaryTeal.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Icon Header
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MeloColors.primaryTeal.withValues(alpha: 0.14),
                        border: Border.all(
                          color: MeloColors.primaryTeal.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MeloColors.primaryTeal.withValues(alpha: 0.22),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _showSettingsPrompt ? Icons.lock_person_rounded : Icons.folder_shared_rounded,
                        color: MeloColors.primaryTeal,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      _showSettingsPrompt ? 'Action Required in Settings' : 'File Access Needed',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Description
                    Text(
                      _showSettingsPrompt
                          ? 'Storage permission is currently restricted. Please enable "Allow access to manage all files" or "Music and audio" in system settings.'
                          : 'To discover, organize, and play your offline music library, Melo needs permission to read audio files from your device storage.',
                      style: TextStyle(
                        fontSize: 13.8,
                        height: 1.45,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Feature highlights (Privacy & Offline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.graphic_eq_rounded,
                            title: 'Local Audio Discovery',
                            subtitle: 'Plays MP3, FLAC, WAV, AAC & M4A tracks stored on your device.',
                            isDark: isDark,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          _buildFeatureRow(
                            icon: Icons.shield_rounded,
                            title: '100% Offline & Private',
                            subtitle: 'Your files are never uploaded or tracked anywhere.',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons Row / Column
                    if (_showSettingsPrompt) ...[
                      // Open Settings Button
                      BouncingTap(
                        scaleDown: 0.94,
                        onTap: _handleOpenSettings,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [MeloColors.primaryTeal, MeloColors.tealDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: MeloColors.primaryTeal.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Open App Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Cancel Button
                      BouncingTap(
                        scaleDown: 0.95,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            'Maybe Later',
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Grant Permission Primary Button
                      BouncingTap(
                        scaleDown: 0.94,
                        onTap: _isRequesting ? null : _handleGrant,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [MeloColors.primaryTeal, MeloColors.tealDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: MeloColors.primaryTeal.withValues(alpha: 0.38),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isRequesting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Grant File Access',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Dismiss Button
                      BouncingTap(
                        scaleDown: 0.95,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Text(
                            'Not Now',
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: MeloColors.primaryTeal,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : MeloColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : MeloColors.lightTextMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
