import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import 'latency_probe.dart';

enum MeloRepeatMode { off, all, one }

class MeloAudioEngine extends ChangeNotifier {
  static final MeloAudioEngine _instance = MeloAudioEngine._internal();
  factory MeloAudioEngine() => _instance;
  MeloAudioEngine._internal();

  // Dual-deck players: Deck A and Deck B
  late AudioPlayer _playerA;
  late AudioPlayer _playerB;
  bool _usePlayerA = true;

  AudioPlayer get _activePlayer => _usePlayerA ? _playerA : _playerB;
  AudioPlayer get _standbyPlayer => _usePlayerA ? _playerB : _playerA;

  // Optimistic & Audio State
  Track? _currentTrack;
  Track? _preloadedTrack;
  bool _isPlaying = false;
  bool _isBuffering = false;
  MeloRepeatMode _repeatMode = MeloRepeatMode.off;
  bool _isShuffle = false;
  double _volume = 1.0;
  bool _isMuted = false;

  // Queue
  List<Track> _queue = [];
  List<Track> _shuffledQueue = [];
  int _currentIndex = -1;

  // High-performance decoupled position notifier for Seek Bar (60fps without widget rebuilds)
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> bufferedPositionNotifier = ValueNotifier(Duration.zero);

  // Rapid-input safety: Monotonically increasing request token
  int _requestToken = 0;
  int _consecutiveErrors = 0;

  // Latency Probe
  final LatencyProbe _probe = LatencyProbe();

  // Subscriptions
  StreamSubscription? _posSubA;
  StreamSubscription? _posSubB;
  StreamSubscription? _stateSubA;
  StreamSubscription? _stateSubB;

  // Callbacks
  Function(Track track)? onTrackPlayed;
  Function(String error)? onError;

  // Getters
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  MeloRepeatMode get repeatMode => _repeatMode;
  bool get isShuffle => _isShuffle;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  List<Track> get queue => _isShuffle ? _shuffledQueue : _queue;
  int get currentIndex => _currentIndex;

  /// Initialize and pre-warm audio players
  Future<void> init() async {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();

    _setupListeners(_playerA, true);
    _setupListeners(_playerB, false);

    // Warm up volume
    await _playerA.setVolume(_volume);
    await _playerB.setVolume(_volume);
  }

  void _setupListeners(AudioPlayer player, bool isPlayerA) {
    player.positionStream.listen((pos) {
      if ((isPlayerA && _usePlayerA) || (!isPlayerA && !_usePlayerA)) {
        positionNotifier.value = pos;
      }
    });

    player.durationStream.listen((dur) {
      if ((isPlayerA && _usePlayerA) || (!isPlayerA && !_usePlayerA)) {
        if (dur != null) {
          durationNotifier.value = dur;
        }
      }
    });

    player.bufferedPositionStream.listen((buf) {
      if ((isPlayerA && _usePlayerA) || (!isPlayerA && !_usePlayerA)) {
        bufferedPositionNotifier.value = buf;
      }
    });

    player.playerStateStream.listen((state) {
      final isActive = (isPlayerA && _usePlayerA) || (!isPlayerA && !_usePlayerA);
      if (!isActive) return;

      final playing = state.playing;
      final processing = state.processingState;

      _isBuffering = processing == ProcessingState.buffering ||
          processing == ProcessingState.loading;

      if (playing && processing == ProcessingState.ready) {
        _probe.recordComplete();
      }

      if (processing == ProcessingState.completed) {
        _onTrackFinished();
      }

      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  /// Instant Playback: Play track immediately with optimistic UI
  Future<void> playTrack(Track track, {List<Track>? newQueue, int? targetBudgetMs}) async {
    final token = ++_requestToken;

    // Latency Probe trigger
    _probe.startAction(
      action: 'Click to Sound',
      targetBudgetMs: targetBudgetMs ?? (track.uri.endsWith('.flac') || track.uri.endsWith('.wav') ? 150 : 100),
      trackTitle: track.title,
    );

    // 1. Optimistic UI update (<5ms)
    _currentTrack = track;
    _isPlaying = true;
    _isBuffering = false;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = track.duration;

    if (newQueue != null) {
      _queue = List.from(newQueue);
      _rebuildShuffledQueue();
      _currentIndex = queue.indexWhere((t) => t.id == track.id);
    } else {
      _currentIndex = queue.indexWhere((t) => t.id == track.id);
    }

    notifyListeners();

    // Trigger history / play count callback asynchronously
    onTrackPlayed?.call(track);

    // 2. Audio execution
    bool started = false;
    try {
      // Check if standby player already has this preloaded
      if (_preloadedTrack?.id == track.id) {
        _preloadedTrack = null;
        try {
          await _activePlayer.pause();
          _usePlayerA = !_usePlayerA;
          await _activePlayer.play();
          started = true;
        } catch (deckError) {
          if (kDebugMode) print('Standby deck swap failed, falling back to direct load: $deckError');
          _usePlayerA = !_usePlayerA; // Revert active player
        }
      }

      if (!started) {
        _preloadedTrack = null;
        await _loadAudioSource(_activePlayer, track);
        if (_requestToken != token) return; // Discard stale request
        await _activePlayer.play();
      }

      _consecutiveErrors = 0;
      _probe.recordComplete();

      // 3. Asynchronously preload the next track on the standby player
      _preloadNextTrack();
    } catch (e) {
      if (_requestToken != token) return;
      if (kDebugMode) print('Audio playback error for "${track.title}": $e');

      _consecutiveErrors++;
      track.isUnavailable = true;
      _isPlaying = false;
      notifyListeners();

      // Limit auto-skip cascade to at most 2 tracks to prevent skipping through the whole library
      if (_consecutiveErrors < queue.length && _consecutiveErrors <= 2) {
        onError?.call('Could not play "${track.title}". Skipping to next track.');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_requestToken == token) {
            next();
          }
        });
      } else {
        _consecutiveErrors = 0;
        onError?.call('Could not play "${track.title}". Please verify file availability and storage permissions.');
      }
    }
  }

  Future<void> _loadAudioSource(AudioPlayer player, Track track) async {
    final uri = track.uri.trim();

    // 1. Asset track
    if (track.isAsset || uri.startsWith('assets/')) {
      final assetPath = uri.startsWith('/') ? uri.substring(1) : uri;
      try {
        await player.setAsset(assetPath);
      } catch (_) {
        await player.setAudioSource(AudioSource.uri(Uri.parse('asset:///$assetPath')));
      }
      return;
    }

    // 2. Network stream
    if (uri.startsWith('http://') || uri.startsWith('https://')) {
      await player.setUrl(uri);
      return;
    }

    // 3. Local file path
    String cleanPath = uri;
    if (cleanPath.startsWith('file://')) {
      try {
        cleanPath = Uri.parse(cleanPath).toFilePath();
      } catch (_) {}
    }

    try {
      await player.setFilePath(cleanPath);
    } catch (_) {
      // Fallback: try as file URI audio source
      await player.setAudioSource(AudioSource.uri(Uri.file(cleanPath)));
    }
  }

  /// Asynchronously prepare standby deck with next queue item
  void _preloadNextTrack() {
    if (queue.isEmpty) return;
    int nextIdx = _currentIndex + 1;
    if (nextIdx >= queue.length) {
      if (_repeatMode == MeloRepeatMode.all) {
        nextIdx = 0;
      } else {
        return;
      }
    }

    final nextTrack = queue[nextIdx];

    // Only mark preloaded once loading successfully completes
    _loadAudioSource(_standbyPlayer, nextTrack).then((_) {
      _preloadedTrack = nextTrack;
    }).catchError((_) {
      _preloadedTrack = null;
    });
  }

  void _onTrackFinished() {
    if (_repeatMode == MeloRepeatMode.one && _currentTrack != null) {
      seek(Duration.zero);
      _activePlayer.play();
    } else {
      next(budgetMs: 30);
    }
  }

  /// Play / Pause toggle
  Future<void> togglePlayPause() async {
    if (_currentTrack == null && queue.isNotEmpty) {
      playTrack(queue.first);
      return;
    }

    _probe.startAction(
      action: _isPlaying ? 'Pause' : 'Resume',
      targetBudgetMs: 20,
      trackTitle: _currentTrack?.title ?? 'Unknown',
    );

    // Optimistic flip
    _isPlaying = !_isPlaying;
    notifyListeners();

    if (_isPlaying) {
      await _activePlayer.play();
    } else {
      await _activePlayer.pause();
    }
    _probe.recordComplete();
  }

  /// Next track (<30ms budget)
  Future<void> next({int budgetMs = 30}) async {
    if (queue.isEmpty) return;

    int nextIdx = _currentIndex + 1;
    if (nextIdx >= queue.length) {
      if (_repeatMode == MeloRepeatMode.all) {
        nextIdx = 0;
      } else {
        await _activePlayer.pause();
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }

    await playTrack(queue[nextIdx], targetBudgetMs: budgetMs);
  }

  /// Previous track (<30ms budget)
  Future<void> previous({int budgetMs = 30}) async {
    if (queue.isEmpty) return;

    // If more than 3 seconds in, restart track
    if (positionNotifier.value.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    int prevIdx = _currentIndex - 1;
    if (prevIdx < 0) {
      prevIdx = queue.length - 1;
    }

    await playTrack(queue[prevIdx], targetBudgetMs: budgetMs);
  }

  /// Seek (<50ms budget)
  Future<void> seek(Duration position) async {
    _probe.startAction(
      action: 'Seek',
      targetBudgetMs: 50,
      trackTitle: _currentTrack?.title ?? 'Seek',
    );

    positionNotifier.value = position;
    await _activePlayer.seek(position);
    _probe.recordComplete();
  }

  /// Set Volume
  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    _isMuted = _volume == 0;
    await _activePlayer.setVolume(_volume);
    await _standbyPlayer.setVolume(_volume);
    notifyListeners();
  }

  /// Toggle Mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final targetVol = _isMuted ? 0.0 : (_volume > 0 ? _volume : 0.8);
    await _activePlayer.setVolume(targetVol);
    await _standbyPlayer.setVolume(targetVol);
    notifyListeners();
  }

  /// Toggle Shuffle
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _rebuildShuffledQueue();
    if (_currentTrack != null) {
      _currentIndex = queue.indexWhere((t) => t.id == _currentTrack!.id);
    }
    _preloadNextTrack();
    notifyListeners();
  }

  void _rebuildShuffledQueue() {
    if (_isShuffle) {
      final copy = List<Track>.from(_queue);
      if (_currentTrack != null) {
        copy.removeWhere((t) => t.id == _currentTrack!.id);
        copy.shuffle();
        copy.insert(0, _currentTrack!);
      } else {
        copy.shuffle();
      }
      _shuffledQueue = copy;
    } else {
      _shuffledQueue.clear();
    }
  }

  /// Cycle Repeat Mode
  void cycleRepeatMode() {
    switch (_repeatMode) {
      case MeloRepeatMode.off:
        _repeatMode = MeloRepeatMode.all;
        break;
      case MeloRepeatMode.all:
        _repeatMode = MeloRepeatMode.one;
        break;
      case MeloRepeatMode.one:
        _repeatMode = MeloRepeatMode.off;
        break;
    }
    _preloadNextTrack();
    notifyListeners();
  }

  /// Reorder queue
  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    _rebuildShuffledQueue();
    if (_currentTrack != null) {
      _currentIndex = queue.indexWhere((t) => t.id == _currentTrack!.id);
    }
    _preloadNextTrack();
    notifyListeners();
  }

  /// Add track next
  void playNext(Track track) {
    if (_queue.isEmpty) {
      playTrack(track);
      return;
    }
    final insertIdx = _currentIndex + 1;
    _queue.insert(insertIdx.clamp(0, _queue.length), track);
    _rebuildShuffledQueue();
    _preloadNextTrack();
    notifyListeners();
  }

  /// Add to queue end
  void addToQueue(Track track) {
    _queue.add(track);
    _rebuildShuffledQueue();
    _preloadNextTrack();
    notifyListeners();
  }

  /// Clear Queue
  void clearQueue() {
    if (_currentTrack != null) {
      _queue = [_currentTrack!];
      _shuffledQueue = [_currentTrack!];
      _currentIndex = 0;
    } else {
      _queue.clear();
      _shuffledQueue.clear();
      _currentIndex = -1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _posSubA?.cancel();
    _posSubB?.cancel();
    _stateSubA?.cancel();
    _stateSubB?.cancel();
    _playerA.dispose();
    _playerB.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    bufferedPositionNotifier.dispose();
    super.dispose();
  }
}
