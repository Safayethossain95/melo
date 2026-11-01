import 'dart:convert';
import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/folder_crate.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class LibraryRepository extends ChangeNotifier {
  static final LibraryRepository _instance = LibraryRepository._internal();
  factory LibraryRepository() => _instance;
  LibraryRepository._internal();

  final List<Track> _tracks = [];
  final List<FolderCrate> _crates = [];
  final List<Track> _recentlyPlayed = [];
  final List<Playlist> _playlists = [];
  final List<String> _customFolderPaths = [];

  bool _isFirstLaunch = true;
  bool _isScanning = false;
  int _scannedFileCount = 0;
  String _currentScanFolder = '';

  // Getters
  List<Track> get tracks => List.unmodifiable(_tracks);
  List<FolderCrate> get crates => List.unmodifiable(_crates);
  List<Track> get favorites => _tracks.where((t) => t.isFavorite).toList();
  List<Track> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<String> get customFolderPaths => List.unmodifiable(_customFolderPaths);

  bool get isFirstLaunch => _isFirstLaunch;
  bool get isScanning => _isScanning;
  int get scannedFileCount => _scannedFileCount;
  String get currentScanFolder => _currentScanFolder;

  // Albums & Artists computed views
  Map<String, List<Track>> get albums {
    final map = <String, List<Track>>{};
    for (final t in _tracks) {
      final alb = t.album.isEmpty ? 'Unknown Album' : t.album;
      map.putIfAbsent(alb, () => []).add(t);
    }
    return map;
  }

  Map<String, List<Track>> get artists {
    final map = <String, List<Track>>{};
    for (final t in _tracks) {
      final art = t.artist.isEmpty ? 'Unknown Artist' : t.artist;
      map.putIfAbsent(art, () => []).add(t);
    }
    return map;
  }

  /// Initialize library from offline cache or trigger initial sample library
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('melo_first_launch') ?? true;

    final cachedJson = prefs.getString('melo_tracks_cache');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cachedJson);
        _tracks.clear();
        for (final item in list) {
          _tracks.add(Track.fromMap(item as Map<String, dynamic>));
        }
        _rebuildCrates();
      } catch (e) {
        if (kDebugMode) print('Failed to load cached library: $e');
      }
    }

    final playlistsJson = prefs.getString('melo_playlists_cache');
    if (playlistsJson != null && playlistsJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(playlistsJson);
        _playlists.clear();
        for (final item in list) {
          _playlists.add(Playlist.fromMap(item as Map<String, dynamic>));
        }
      } catch (e) {
        if (kDebugMode) print('Failed to load playlists: $e');
      }
    }

    // If empty, seed initial sample library
    if (_tracks.isEmpty) {
      await seedSampleLibrary();
    }

    notifyListeners();
  }

  /// Seed high-quality offline sample tracks across genres & folders
  Future<void> seedSampleLibrary() async {
    _tracks.clear();

    final samples = [
      Track(
        id: 'seed_1',
        title: 'Cyber Teal',
        artist: 'Neon Horizon',
        album: 'Synthesized Nights',
        duration: const Duration(seconds: 16),
        uri: 'assets/audio/cyber_teal.wav',
        isAsset: true,
        folderPath: 'Synthwave Dreams',
        folderName: 'Synthwave Dreams',
        genre: 'Synthwave',
        year: 2026,
        bitrate: 1411,
        isFavorite: true,
      ),
      Track(
        id: 'seed_2',
        title: 'Midnight Drive',
        artist: 'Neon Horizon',
        album: 'Synthesized Nights',
        duration: const Duration(seconds: 15),
        uri: 'assets/audio/midnight_drive.wav',
        isAsset: true,
        folderPath: 'Synthwave Dreams',
        folderName: 'Synthwave Dreams',
        genre: 'Synthwave',
        year: 2026,
        bitrate: 1411,
      ),
      Track(
        id: 'seed_3',
        title: 'Lo-Fi Rain',
        artist: 'Coffee & Books',
        album: 'Tokyo After Dark',
        duration: const Duration(seconds: 18),
        uri: 'assets/audio/lofi_rain.wav',
        isAsset: true,
        folderPath: 'Chill Lo-Fi',
        folderName: 'Chill Lo-Fi',
        genre: 'Lo-Fi',
        year: 2025,
        bitrate: 1411,
        isFavorite: true,
      ),
      Track(
        id: 'seed_4',
        title: 'Morning Coffee',
        artist: 'Coffee & Books',
        album: 'Tokyo After Dark',
        duration: const Duration(seconds: 16),
        uri: 'assets/audio/morning_coffee.wav',
        isAsset: true,
        folderPath: 'Chill Lo-Fi',
        folderName: 'Chill Lo-Fi',
        genre: 'Acoustic',
        year: 2025,
        bitrate: 1411,
      ),
      Track(
        id: 'seed_5',
        title: 'Deep Ocean Sub',
        artist: 'Solitude Lab',
        album: 'Ethereal Frequencies',
        duration: const Duration(seconds: 20),
        uri: 'assets/audio/deep_ocean.wav',
        isAsset: true,
        folderPath: 'Ambient Focus',
        folderName: 'Ambient Focus',
        genre: 'Ambient',
        year: 2026,
        bitrate: 1411,
      ),
    ];

    _tracks.addAll(samples);
    _rebuildCrates();

    // Default starter playlist
    if (_playlists.isEmpty) {
      _playlists.add(
        Playlist(
          id: 'pl_chill',
          name: 'Late Night Coding',
          description: 'Lo-fi beats & ambient frequencies for deep focus.',
          trackIds: ['seed_1', 'seed_3', 'seed_5'],
        ),
      );
    }

    await _saveToStorage();
    notifyListeners();
  }

  static const Set<String> _audioExtensions = {
    '.mp3',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
    '.m4a',
    '.aac',
    '.wma',
    '.aiff',
    '.mid',
    '.mka',
  };

  /// Check whether storage permissions are granted
  Future<bool> hasStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    final manage = await Permission.manageExternalStorage.isGranted;
    if (manage) return true;

    final audio = await Permission.audio.isGranted;
    if (audio) return true;

    final storage = await Permission.storage.isGranted;
    return storage;
  }

  /// Request permissions to read all drives/storage (MANAGE_EXTERNAL_STORAGE + Audio + Storage)
  Future<bool> requestStoragePermission({bool requestManage = true}) async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    // 1. First attempt All Files Access (Manage External Storage)
    if (requestManage) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    }

    // 2. Request Android 13+ READ_MEDIA_AUDIO
    final audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted) return true;

    // 3. Request Legacy READ_EXTERNAL_STORAGE
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Open Android App Settings so the user can grant permission manually if permanently denied
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  /// Returns storage search roots for Android, Desktop, and user added folders
  List<Directory> _getSearchRoots() {
    final List<Directory> roots = [];
    if (kIsWeb) return roots;

    if (Platform.isAndroid) {
      // 1. Primary internal storage root (/storage/emulated/0)
      final primary = Directory('/storage/emulated/0');
      if (primary.existsSync()) {
        roots.add(primary);
      } else {
        final sdcard = Directory('/sdcard');
        if (sdcard.existsSync()) roots.add(sdcard);
      }

      // 2. Secondary storage / SD Cards / USB drives in /storage
      final storageDir = Directory('/storage');
      if (storageDir.existsSync()) {
        try {
          final entries = storageDir.listSync(followLinks: false);
          for (final e in entries) {
            if (e is Directory) {
              final name = e.path.split(RegExp(r'[\\/]')).last;
              if (name != 'emulated' && name != 'self' && !name.startsWith('.')) {
                roots.add(e);
              }
            }
          }
        } catch (_) {}
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final music = Directory('$userProfile\\Music');
        final downloads = Directory('$userProfile\\Downloads');
        if (music.existsSync()) roots.add(music);
        if (downloads.existsSync()) roots.add(downloads);
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final music = Directory('$home/Music');
        final downloads = Directory('$home/Downloads');
        if (music.existsSync()) roots.add(music);
        if (downloads.existsSync()) roots.add(downloads);
      }
    }

    // Add any custom folders user imported
    for (final customPath in _customFolderPaths) {
      final d = Directory(customPath);
      if (d.existsSync() && !roots.any((r) => r.path == d.path)) {
        roots.add(d);
      }
    }

    return roots;
  }

  /// Recursive directory traversal collecting all audio files
  Future<void> _traverseDirectory(
    Directory dir,
    Set<String> visited,
    List<File> audioFiles, {
    int maxDepth = 8,
    int currentDepth = 0,
  }) async {
    if (currentDepth > maxDepth) return;
    final path = dir.path;
    if (visited.contains(path)) return;
    visited.add(path);

    final dirName = path.split(RegExp(r'[\\/]')).last;

    // Skip hidden folders (.nomedia, .thumbnails, etc.) and restricted system folders
    if (dirName.startsWith('.')) return;
    if (path.contains('/Android/data') || path.contains('/Android/obb')) return;

    // Skip folder if .nomedia exists
    try {
      final noMedia = File('$path/.nomedia');
      if (noMedia.existsSync()) return;
    } catch (_) {}

    _currentScanFolder = dirName.isEmpty ? path : dirName;
    _scannedFileCount = audioFiles.length;
    notifyListeners();

    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final p = entity.path.toLowerCase();
          final dotIndex = p.lastIndexOf('.');
          if (dotIndex != -1 && _audioExtensions.contains(p.substring(dotIndex))) {
            audioFiles.add(entity);
            if (audioFiles.length % 5 == 0) {
              _scannedFileCount = audioFiles.length;
              notifyListeners();
              await Future.delayed(Duration.zero);
            }
          }
        } else if (entity is Directory) {
          await _traverseDirectory(
            entity,
            visited,
            audioFiles,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1,
          );
        }
      }
    } catch (_) {
      // Ignore unreadable/permission-protected directories
    }
  }

  /// Parse audio metadata from file using AudioTags
  Future<Track> _fileToTrack(File file, int index) async {
    Tag? tag;
    try {
      tag = await AudioTags.read(file.path);
    } catch (_) {}

    final fileName = file.path.split(RegExp(r'[\\/]')).last;
    final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final parentFolder = file.parent.path.split(RegExp(r'[\\/]')).last;

    int? size;
    try {
      size = file.lengthSync();
    } catch (_) {}

    return Track(
      id: 'local_${file.path.hashCode}_$index',
      title: (tag?.title != null && tag!.title!.trim().isNotEmpty)
          ? tag.title!.trim()
          : nameWithoutExt,
      artist: (tag?.trackArtist != null && tag!.trackArtist!.trim().isNotEmpty)
          ? tag.trackArtist!.trim()
          : ((tag?.albumArtist != null && tag!.albumArtist!.trim().isNotEmpty)
              ? tag.albumArtist!.trim()
              : 'Unknown Artist'),
      album: (tag?.album != null && tag!.album!.trim().isNotEmpty)
          ? tag.album!.trim()
          : (parentFolder.isNotEmpty ? parentFolder : 'Unknown Album'),
      duration: (tag?.duration != null && tag!.duration! > 0)
          ? Duration(seconds: tag.duration!)
          : const Duration(seconds: 180),
      uri: file.path,
      isAsset: false,
      folderPath: file.parent.path,
      folderName: parentFolder.isEmpty ? 'Internal Storage' : parentFolder,
      genre: (tag?.genre != null && tag!.genre!.trim().isNotEmpty) ? tag.genre!.trim() : 'Local Audio',
      year: tag?.year,
      fileSize: size,
    );
  }

  /// Scan device storage (internal + SD cards) for all audio files
  Future<void> runInitialScan() async {
    _isScanning = true;
    _scannedFileCount = 0;
    _currentScanFolder = 'Requesting storage permission…';
    notifyListeners();

    // 1. Request permissions on Android
    await requestStoragePermission();

    // 2. Discover search roots across all drives
    final roots = _getSearchRoots();
    final List<File> collectedFiles = [];
    final Set<String> visited = {};

    for (final root in roots) {
      if (root.existsSync()) {
        await _traverseDirectory(root, visited, collectedFiles);
      }
    }

    _currentScanFolder = 'Indexing track tags…';
    notifyListeners();

    // 3. Process tags and add tracks
    if (collectedFiles.isNotEmpty) {
      // Remove asset seed tracks once real local audio files are found
      _tracks.removeWhere((t) => t.isAsset);

      final existingUris = _tracks.map((t) => t.uri).toSet();

      for (int i = 0; i < collectedFiles.length; i++) {
        final file = collectedFiles[i];
        if (existingUris.contains(file.path)) continue;

        final track = await _fileToTrack(file, i);
        _tracks.add(track);

        if (i % 10 == 0) {
          _scannedFileCount = _tracks.length;
          notifyListeners();
          await Future.delayed(Duration.zero);
        }
      }

      _rebuildCrates();
      await _saveToStorage();
    } else {
      // If no local tracks found, retain/seed sample library so app remains playable
      if (_tracks.isEmpty) {
        await seedSampleLibrary();
      }
    }

    _isFirstLaunch = false;
    _isScanning = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('melo_first_launch', false);

    notifyListeners();
  }

  /// Import files via native file picker (supports all platforms)
  Future<int> importFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'wav', 'ogg', 'opus', 'm4a', 'aac', 'wma', 'aiff', 'mid', 'mka'],
    );

    if (files.isEmpty) return 0;

    int added = 0;
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final path = file.path;
      if (path == null) continue;
      if (_tracks.any((t) => t.uri == path)) continue;

      final track = await _fileToTrack(File(path), i);
      _tracks.add(track);
      added++;
    }

    if (added > 0) {
      _rebuildCrates();
      await _saveToStorage();
      notifyListeners();
    }
    return added;
  }

  /// Pick Directory and scan all audio inside it
  Future<void> importFolder() async {
    final dirPath = await FilePicker.getDirectoryPath();
    if (dirPath == null) return;

    if (!_customFolderPaths.contains(dirPath)) {
      _customFolderPaths.add(dirPath);
    }

    _isScanning = true;
    _currentScanFolder = dirPath;
    notifyListeners();

    final dir = Directory(dirPath);
    final List<File> collectedFiles = [];
    final Set<String> visited = {};
    if (dir.existsSync()) {
      await _traverseDirectory(dir, visited, collectedFiles);
    }

    final existingUris = _tracks.map((t) => t.uri).toSet();
    for (int i = 0; i < collectedFiles.length; i++) {
      final file = collectedFiles[i];
      if (existingUris.contains(file.path)) continue;
      final track = await _fileToTrack(file, i);
      _tracks.add(track);
    }

    _isScanning = false;
    _rebuildCrates();
    await _saveToStorage();
    notifyListeners();
  }

  void _rebuildCrates() {
    _crates.clear();
    final Map<String, List<Track>> folderMap = {};

    for (final t in _tracks) {
      folderMap.putIfAbsent(t.folderName, () => []).add(t);
    }

    for (final entry in folderMap.entries) {
      _crates.add(
        FolderCrate(
          folderPath: entry.value.first.folderPath,
          folderName: entry.key,
          tracks: entry.value,
        ),
      );
    }
  }

  /// Toggle Favorite
  void toggleFavorite(String trackId) {
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx != -1) {
      _tracks[idx].isFavorite = !_tracks[idx].isFavorite;
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Record Track Played
  void recordTrackPlayed(Track track) {
    final idx = _tracks.indexWhere((t) => t.id == track.id);
    if (idx != -1) {
      _tracks[idx].playCount++;
    }

    _recentlyPlayed.removeWhere((t) => t.id == track.id);
    _recentlyPlayed.insert(0, track);
    if (_recentlyPlayed.length > 40) {
      _recentlyPlayed.removeLast();
    }

    _saveToStorage();
    notifyListeners();
  }

  /// Create Playlist
  void createPlaylist(String name, {String description = ''}) {
    final pl = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      trackIds: [],
    );
    _playlists.add(pl);
    _saveToStorage();
    notifyListeners();
  }

  /// Rename Playlist
  void renamePlaylist(String id, String newName) {
    final pl = _playlists.firstWhere((p) => p.id == id, orElse: () => _playlists.first);
    pl.name = newName;
    _saveToStorage();
    notifyListeners();
  }

  /// Delete Playlist
  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _saveToStorage();
    notifyListeners();
  }

  /// Add track to playlist
  void addTrackToPlaylist(String playlistId, String trackId) {
    final pl = _playlists.firstWhere((p) => p.id == playlistId);
    if (!pl.trackIds.contains(trackId)) {
      pl.trackIds.add(trackId);
      _saveToStorage();
      notifyListeners();
    }
  }

  /// Remove track from playlist
  void removeTrackFromPlaylist(String playlistId, String trackId) {
    final pl = _playlists.firstWhere((p) => p.id == playlistId);
    pl.trackIds.remove(trackId);
    _saveToStorage();
    notifyListeners();
  }

  /// Clear all cache & restore defaults
  Future<void> clearCache() async {
    _tracks.clear();
    _crates.clear();
    _recentlyPlayed.clear();
    _playlists.clear();
    _customFolderPaths.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('melo_tracks_cache');
    await prefs.remove('melo_playlists_cache');
    await prefs.setBool('melo_first_launch', true);

    await seedSampleLibrary();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final tracksJson = jsonEncode(_tracks.map((t) => t.toMap()).toList());
    await prefs.setString('melo_tracks_cache', tracksJson);

    final playlistsJson = jsonEncode(_playlists.map((p) => p.toMap()).toList());
    await prefs.setString('melo_playlists_cache', playlistsJson);
  }

  /// Instant fuzzy search
  List<Track> search(String query) {
    if (query.trim().isEmpty) return _tracks;
    final q = query.toLowerCase().trim();
    return _tracks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          t.album.toLowerCase().contains(q) ||
          t.folderName.toLowerCase().contains(q) ||
          (t.genre?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
