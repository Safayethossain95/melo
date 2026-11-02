import 'dart:async';
import 'dart:convert';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
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

  /// Get online artwork URL if available in memory, track model, or persistent cache
  String? getCachedOnlineUrl(Track track) {
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

  /// Fetch album art from internet (iTunes -> Deezer fallback) if no local art exists
  Future<String?> fetchOnlineArtwork(Track track) async {
    // Check if already in cache
    final cached = getCachedOnlineUrl(track);
    if (cached != null) return cached;

    final lookupId = track.id;
    if (_pendingLookups.contains(lookupId)) return null;
    _pendingLookups.add(lookupId);

    try {
      final online = await hasInternet();
      if (!online) {
        _pendingLookups.remove(lookupId);
        return null;
      }

      // 1. Search via iTunes Search API (no key required, supports HD 600x600 artwork)
      String? url = await _fetchFromITunes(track);

      // 2. Fallback to Deezer Search API if iTunes returned no results
      url ??= await _fetchFromDeezer(track);

      if (url != null && url.isNotEmpty) {
        _onlineUrlCache[track.id] = url;
        track.artworkUrl = url;
        final key = _cacheKey(track);
        await _prefs?.setString(key, url);
        notifyListeners();
        return url;
      }
    } catch (e) {
      if (kDebugMode) print('Online artwork fetch failed for ${track.title}: $e');
    } finally {
      _pendingLookups.remove(lookupId);
    }

    return null;
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
