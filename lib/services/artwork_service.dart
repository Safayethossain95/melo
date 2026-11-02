import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';

class ArtworkService extends ChangeNotifier {
  static final ArtworkService _instance = ArtworkService._internal();
  factory ArtworkService() => _instance;
  ArtworkService._internal();

  // In-memory caches for fast, zero-delay lookups
  final Map<String, Uint8List> _embeddedArtCache = {};
  final Map<String, String> _onlineUrlCache = {};
  final Set<String> _pendingLookups = {};

  SharedPreferences? _prefs;
  Directory? _localArtworkDir;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      if (!kIsWeb) {
        String? basePath;
        if (Platform.isAndroid) {
          try {
            const channel = MethodChannel('com.melo.app/audio_output');
            basePath = await channel.invokeMethod<String>('getAppStoragePath');
          } catch (_) {}
        }
        basePath ??= Platform.environment['LOCALAPPDATA'] ??
            Platform.environment['APPDATA'] ??
            Directory.current.path;

        _localArtworkDir = Directory('$basePath/melo_artwork');
        if (!_localArtworkDir!.existsSync()) {
          _localArtworkDir!.createSync(recursive: true);
        }
      }
    } catch (e) {
      if (kDebugMode) print('ArtworkService init error: $e');
    }
  }

  /// Get embedded art bytes from cache or read from local audio file
  Future<Uint8List?> getEmbeddedArt(Track track) async {
    if (kIsWeb) return null;

    if (_embeddedArtCache.containsKey(track.id)) {
      return _embeddedArtCache[track.id];
    }

    if (track.isAsset || track.uri.startsWith('assets/')) {
      return null;
    }

    try {
      final tag = await AudioTags.read(track.uri);
      if (tag != null && tag.pictures.isNotEmpty) {
        final bytes = tag.pictures.first.bytes;
        _embeddedArtCache[track.id] = bytes;
        notifyListeners();
        return bytes;
      }
    } catch (e) {
      if (kDebugMode) print('Error reading embedded art for ${track.title}: $e');
    }

    return null;
  }

  /// Check whether embedded art is already cached in memory
  Uint8List? getCachedEmbeddedArt(String trackId) => _embeddedArtCache[trackId];

  /// Returns the saved local image file on disk if already downloaded
  File? getLocalArtworkFile(Track track) {
    if (kIsWeb) return null;

    // 1. Check if track.artworkUrl is already a valid local file path
    if (track.artworkUrl != null &&
        track.artworkUrl!.isNotEmpty &&
        !track.artworkUrl!.startsWith('http') &&
        !track.artworkUrl!.startsWith('blob:')) {
      final f = File(track.artworkUrl!);
      if (f.existsSync()) return f;
    }

    // 2. Check in local storage directory
    if (_localArtworkDir != null) {
      final fileKey = _cacheFileKey(track);
      final f = File('${_localArtworkDir!.path}/$fileKey.jpg');
      if (f.existsSync()) return f;
    }

    // 3. Check in persistent preferences
    final key = _cacheKey(track);
    final savedPath = _prefs?.getString(key);
    if (savedPath != null &&
        savedPath.isNotEmpty &&
        !savedPath.startsWith('http') &&
        !savedPath.startsWith('blob:')) {
      final f = File(savedPath);
      if (f.existsSync()) return f;
    }

    return null;
  }

  /// Get online artwork URL or local file path if available
  String? getCachedOnlineUrl(Track track) {
    // Check local storage file first
    final local = getLocalArtworkFile(track);
    if (local != null && local.existsSync()) {
      track.artworkUrl = local.path;
      return local.path;
    }

    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      return track.artworkUrl;
    }
    if (_onlineUrlCache.containsKey(track.id)) {
      return _onlineUrlCache[track.id];
    }
    final key = _cacheKey(track);
    final cached = _prefs?.getString(key);
    if (cached != null && cached.isNotEmpty) {
      _onlineUrlCache[track.id] = cached;
      track.artworkUrl = cached;
      return cached;
    }
    return null;
  }

  String _cacheKey(Track track) {
    final cleanTitle = track.title.trim().toLowerCase();
    final cleanArtist = track.artist.trim().toLowerCase();
    return 'art_url_${cleanTitle}_$cleanArtist';
  }

  String _cacheFileKey(Track track) {
    final cleanTitle = track.title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final cleanArtist = track.artist.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final hash = (cleanTitle.hashCode ^ cleanArtist.hashCode).abs();
    final shortTitle = cleanTitle.substring(0, min(14, cleanTitle.length));
    return '${shortTitle}_$hash';
  }

  /// Check internet reachability safely without crashing
  Future<bool> hasInternet() async {
    if (kIsWeb) return true;
    try {
      final res = await http.get(Uri.parse('https://apple.com')).timeout(const Duration(seconds: 3));
      return res.statusCode > 0;
    } catch (_) {
      return true; // Fallback to attempting request
    }
  }

  /// Fetch album art from internet, save to local storage, and return local file path
  Future<String?> fetchOnlineArtwork(Track track) async {
    // 1. Check if already saved in local storage on disk
    final localFile = getLocalArtworkFile(track);
    if (localFile != null && localFile.existsSync()) {
      track.artworkUrl = localFile.path;
      _onlineUrlCache[track.id] = localFile.path;
      return localFile.path;
    }

    final lookupId = track.id;
    if (_pendingLookups.contains(lookupId)) return null;
    _pendingLookups.add(lookupId);

    try {
      final online = await hasInternet();
      if (!online) {
        _pendingLookups.remove(lookupId);
        return null;
      }

      // 2. Search via iTunes Search API (HD 600x600 artwork)
      String? remoteUrl = await _fetchFromITunes(track);

      // 3. Fallback to Deezer Search API if iTunes returned no results
      remoteUrl ??= await _fetchFromDeezer(track);

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        String finalArtworkPath = remoteUrl;

        // 4. Download and save image bytes to app's local storage permanently
        if (!kIsWeb && _localArtworkDir != null) {
          try {
            final imgRes = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 8));
            if (imgRes.statusCode == 200 && imgRes.bodyBytes.isNotEmpty) {
              final fileKey = _cacheFileKey(track);
              final savedFile = File('${_localArtworkDir!.path}/$fileKey.jpg');
              await savedFile.writeAsBytes(imgRes.bodyBytes);
              if (savedFile.existsSync()) {
                finalArtworkPath = savedFile.path;
              }
            }
          } catch (e) {
            if (kDebugMode) print('Failed to save image bytes to local storage: $e');
          }
        }

        _onlineUrlCache[track.id] = finalArtworkPath;
        track.artworkUrl = finalArtworkPath;
        final key = _cacheKey(track);
        await _prefs?.setString(key, finalArtworkPath);
        notifyListeners();
        return finalArtworkPath;
      }
    } catch (e) {
      if (kDebugMode) print('Online artwork fetch failed for ${track.title}: $e');
    } finally {
      _pendingLookups.remove(lookupId);
    }

    return null;
  }

  /// Automatically batch fetch and save missing thumbnails to local storage during library scan
  Future<void> fetchAndCacheArtworksForTracks(List<Track> tracks) async {
    if (kIsWeb) return;

    final needingArtwork = <Track>[];
    for (final track in tracks) {
      if (track.isAsset) continue;
      // Skip if already in memory
      if (getCachedEmbeddedArt(track.id) != null) continue;
      // Skip if already exists in local disk storage
      final local = getLocalArtworkFile(track);
      if (local != null && local.existsSync()) {
        track.artworkUrl = local.path;
        continue;
      }
      needingArtwork.add(track);
    }

    if (needingArtwork.isEmpty) return;

    final online = await hasInternet();
    if (!online) return;

    // Concurrently fetch in chunks of 3 to avoid overwhelming bandwidth
    for (int i = 0; i < needingArtwork.length; i += 3) {
      final chunk = needingArtwork.sublist(i, min(i + 3, needingArtwork.length));
      await Future.wait(chunk.map((t) async {
        try {
          await fetchOnlineArtwork(t);
        } catch (_) {}
      }));
      // Brief breathing pause between batches
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<String?> _fetchFromITunes(Track track) async {
    final cleanTitle = _cleanSongQuery(track.title);
    final cleanArtist = track.artist.contains('Unknown') ? '' : _cleanSongQuery(track.artist);
    final query = '$cleanTitle $cleanArtist'.trim();
    if (query.isEmpty) return null;

    String? art = await _searchITunesQuery(query);
    if (art == null && cleanArtist.isNotEmpty && cleanTitle.isNotEmpty) {
      // Fallback search with title only
      art = await _searchITunesQuery(cleanTitle);
    }
    return art;
  }

  Future<String?> _searchITunesQuery(String query) async {
    final uri = Uri.parse(
      'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=1',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final rawArt = first['artworkUrl100'] as String?;
          if (rawArt != null && rawArt.isNotEmpty) {
            // Upgrade 100x100 to 600x600 ultra-clear cover art
            return rawArt.replaceAll('100x100bb', '600x600bb');
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchFromDeezer(Track track) async {
    // Deezer does not provide CORS headers for direct browser fetch requests.
    // On web, direct requests fail with browser CORS errors. Native apps (Android, iOS, desktop)
    // bypass browser CORS and can query Deezer directly.
    if (kIsWeb) return null;

    final cleanTitle = _cleanSongQuery(track.title);
    final cleanArtist = track.artist.contains('Unknown') ? '' : _cleanSongQuery(track.artist);
    final query = '$cleanTitle $cleanArtist'.trim();
    if (query.isEmpty) return null;

    final uri = Uri.parse(
      'https://api.deezer.com/search?q=${Uri.encodeComponent(query)}&limit=1',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final album = first['album'] as Map<String, dynamic>?;
          if (album != null) {
            final cover = (album['cover_xl'] ?? album['cover_big'] ?? album['cover_medium']) as String?;
            if (cover != null && cover.isNotEmpty) {
              return cover;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String _cleanSongQuery(String text) {
    // Strip file extensions, brackets, remaster tags, etc. for better search accuracy
    return text
        .replaceAll(RegExp(r'\.(mp3|wav|flac|m4a|aac|ogg)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), '')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim();
  }
}
