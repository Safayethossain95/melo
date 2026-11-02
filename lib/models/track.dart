class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final Duration duration;
  final String uri;
  final bool isAsset;
  final String folderPath;
  final String folderName;
  final int? bitrate;
  final int? year;
  final String? genre;
  final int? fileSize;
  final String? lyrics;
  final List<double> waveformPeaks;
  bool isFavorite;
  int playCount;
  final DateTime addedDate;
  bool isUnavailable;
  String? artworkUrl;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist = '',
    required this.duration,
    required this.uri,
    this.isAsset = false,
    required this.folderPath,
    required this.folderName,
    this.bitrate,
    this.year,
    this.genre,
    this.fileSize,
    this.lyrics,
    List<double>? waveformPeaks,
    this.isFavorite = false,
    this.playCount = 0,
    DateTime? addedDate,
    this.isUnavailable = false,
    this.artworkUrl,
  })  : waveformPeaks = waveformPeaks ?? _generateApproximatedPeaks(id),
        addedDate = addedDate ?? DateTime.now();

  static List<double> _generateApproximatedPeaks(String seed) {
    // 48 normalized bars (0.15 to 1.0) deterministic to track id
    final hash = seed.hashCode;
    final peaks = <double>[];
    for (int i = 0; i < 48; i++) {
      final v = ((hash * (i + 13) * 31) % 100).abs() / 100.0;
      peaks.add(0.2 + (v * 0.75));
    }
    return peaks;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtist': albumArtist,
      'durationMs': duration.inMilliseconds,
      'uri': uri,
      'isAsset': isAsset,
      'folderPath': folderPath,
      'folderName': folderName,
      'bitrate': bitrate,
      'year': year,
      'genre': genre,
      'fileSize': fileSize,
      'lyrics': lyrics,
      'waveformPeaks': waveformPeaks,
      'isFavorite': isFavorite,
      'playCount': playCount,
      'addedDate': addedDate.toIso8601String(),
      'isUnavailable': isUnavailable,
      'artworkUrl': artworkUrl,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      albumArtist: map['albumArtist'] as String? ?? '',
      duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
      uri: map['uri'] as String,
      isAsset: map['isAsset'] as bool? ?? false,
      folderPath: map['folderPath'] as String? ?? 'Music',
      folderName: map['folderName'] as String? ?? 'Music',
      bitrate: map['bitrate'] as int?,
      year: map['year'] as int?,
      genre: map['genre'] as String?,
      fileSize: map['fileSize'] as int?,
      lyrics: map['lyrics'] as String?,
      waveformPeaks: (map['waveformPeaks'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          _generateApproximatedPeaks(map['id'] as String),
      isFavorite: map['isFavorite'] as bool? ?? false,
      playCount: map['playCount'] as int? ?? 0,
      addedDate: map['addedDate'] != null
          ? DateTime.tryParse(map['addedDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isUnavailable: map['isUnavailable'] as bool? ?? false,
      artworkUrl: map['artworkUrl'] as String?,
    );
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    Duration? duration,
    String? uri,
    bool? isAsset,
    String? folderPath,
    String? folderName,
    int? bitrate,
    int? year,
    String? genre,
    int? fileSize,
    String? lyrics,
    List<double>? waveformPeaks,
    bool? isFavorite,
    int? playCount,
    DateTime? addedDate,
    bool? isUnavailable,
    String? artworkUrl,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      isAsset: isAsset ?? this.isAsset,
      folderPath: folderPath ?? this.folderPath,
      folderName: folderName ?? this.folderName,
      bitrate: bitrate ?? this.bitrate,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      fileSize: fileSize ?? this.fileSize,
      lyrics: lyrics ?? this.lyrics,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      addedDate: addedDate ?? this.addedDate,
      isUnavailable: isUnavailable ?? this.isUnavailable,
      artworkUrl: artworkUrl ?? this.artworkUrl,
    );
  }

  String get extension {
    final dotIdx = uri.lastIndexOf('.');
    if (dotIdx != -1 && dotIdx < uri.length - 1) {
      return uri.substring(dotIdx + 1).toUpperCase();
    }
    return 'AUDIO';
  }
}
