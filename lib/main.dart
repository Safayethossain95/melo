import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_scaffold.dart';
import 'core/theme/melo_theme.dart';
import 'pages/onboarding_scan_screen.dart';
import 'services/audio_engine.dart';
import 'services/library_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioEngine = MeloAudioEngine();
  await audioEngine.init();

  final libraryRepo = LibraryRepository();
  await libraryRepo.init();

  // Connect play tracking
  audioEngine.onTrackPlayed = (track) {
    libraryRepo.recordTrackPlayed(track);
  };

  runApp(MeloApp(
    audioEngine: audioEngine,
    libraryRepo: libraryRepo,
  ));
}

class MeloApp extends StatefulWidget {
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;

  const MeloApp({
    super.key,
    required this.audioEngine,
    required this.libraryRepo,
  });

  @override
  State<MeloApp> createState() => _MeloAppState();
}

class _MeloAppState extends State<MeloApp> {
  bool _isDarkMode = true;
  bool _showOnboarding = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('melo_theme_dark') ?? true;
    final firstLaunch = prefs.getBool('melo_first_launch') ?? true;

    setState(() {
      _isDarkMode = isDark;
      _showOnboarding = firstLaunch;
      _isReady = true;
    });
  }

  void _toggleTheme(bool dark) async {
    setState(() => _isDarkMode = dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('melo_theme_dark', dark);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MeloTheme.darkTheme(),
        home: const Scaffold(
          backgroundColor: MeloColors.darkBgBase,
          body: Center(
            child: CircularProgressIndicator(color: MeloColors.primaryTeal),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Melo — Offline Music Player',
      debugShowCheckedModeBanner: false,
      theme: MeloTheme.lightTheme(),
      darkTheme: MeloTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _showOnboarding
          ? OnboardingScanScreen(
              libraryRepo: widget.libraryRepo,
              onComplete: () {
                setState(() => _showOnboarding = false);
              },
            )
          : AppScaffold(
              libraryRepo: widget.libraryRepo,
              audioEngine: widget.audioEngine,
              isDarkMode: _isDarkMode,
              onThemeToggle: _toggleTheme,
            ),
    );
  }
}
