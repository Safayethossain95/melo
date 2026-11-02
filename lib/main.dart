import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_scaffold.dart';
import 'core/theme/melo_theme.dart';
import 'pages/onboarding_scan_screen.dart';
import 'services/artwork_service.dart';
import 'services/audio_engine.dart';
import 'services/audio_output_service.dart';
import 'services/library_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Filter benign Flutter web engine assertion on browser window/viewport resize
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('ViewInsets cannot be negative')) {
      return;
    }
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    if (error.toString().contains('ViewInsets cannot be negative')) {
      return true;
    }
    return false;
  };

  await ArtworkService().init();
  await AudioOutputService().init();

  final audioEngine = MeloAudioEngine();
  await audioEngine.init();

  final libraryRepo = LibraryRepository();
  await libraryRepo.init();

  final prefs = await SharedPreferences.getInstance();
  final hasOverride = prefs.getBool('melo_theme_override') ?? false;
  final bool initialDark;
  if (hasOverride) {
    initialDark = prefs.getBool('melo_theme_dark') ?? true;
  } else {
    final sysBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    initialDark = sysBrightness == Brightness.dark;
  }
  final isFirstLaunch = prefs.getBool('melo_first_launch') ?? true;

  // Connect play tracking
  audioEngine.onTrackPlayed = (track) {
    libraryRepo.recordTrackPlayed(track);
  };

  runApp(MeloApp(
    audioEngine: audioEngine,
    libraryRepo: libraryRepo,
    initialDarkMode: initialDark,
    hasUserOverride: hasOverride,
    initialFirstLaunch: isFirstLaunch,
  ));
}

class MeloApp extends StatefulWidget {
  final MeloAudioEngine audioEngine;
  final LibraryRepository libraryRepo;
  final bool initialDarkMode;
  final bool hasUserOverride;
  final bool initialFirstLaunch;

  const MeloApp({
    super.key,
    required this.audioEngine,
    required this.libraryRepo,
    required this.initialDarkMode,
    required this.hasUserOverride,
    required this.initialFirstLaunch,
  });

  @override
  State<MeloApp> createState() => _MeloAppState();
}

class _MeloAppState extends State<MeloApp> with WidgetsBindingObserver {
  late bool _isDarkMode;
  late bool _hasUserThemeOverride;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isDarkMode = widget.initialDarkMode;
    _hasUserThemeOverride = widget.hasUserOverride;
    _showOnboarding = widget.initialFirstLaunch;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Once dark mode toggle is switched by the user, remember it and NEVER auto switch!
    if (!_hasUserThemeOverride) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      setState(() {
        _isDarkMode = brightness == Brightness.dark;
      });
    }
  }

  void _toggleTheme(bool dark) async {
    setState(() {
      _isDarkMode = dark;
      _hasUserThemeOverride = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('melo_theme_dark', dark);
    await prefs.setBool('melo_theme_override', true);
  }

  @override
  Widget build(BuildContext context) {
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
