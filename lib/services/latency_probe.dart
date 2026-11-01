import 'package:flutter/foundation.dart';

class LatencyMetric {
  final String action;
  final int latencyMs;
  final int targetBudgetMs;
  final DateTime timestamp;
  final String trackTitle;

  LatencyMetric({
    required this.action,
    required this.latencyMs,
    required this.targetBudgetMs,
    required this.timestamp,
    required this.trackTitle,
  });

  bool get passed => latencyMs <= targetBudgetMs;
}

class LatencyProbe extends ChangeNotifier {
  static final LatencyProbe _instance = LatencyProbe._internal();
  factory LatencyProbe() => _instance;
  LatencyProbe._internal();

  final List<LatencyMetric> _metrics = [];
  bool _overlayVisible = false;
  Stopwatch? _currentStopwatch;
  String _currentAction = '';
  int _currentTargetBudget = 100;
  String _currentTrackTitle = '';

  List<LatencyMetric> get metrics => List.unmodifiable(_metrics);
  bool get overlayVisible => _overlayVisible;

  void toggleOverlay() {
    _overlayVisible = !_overlayVisible;
    notifyListeners();
  }

  void setOverlayVisible(bool visible) {
    _overlayVisible = visible;
    notifyListeners();
  }

  /// Start recording latency on user trigger (click, keypress, seek, etc.)
  void startAction({
    required String action,
    required int targetBudgetMs,
    required String trackTitle,
  }) {
    _currentAction = action;
    _currentTargetBudget = targetBudgetMs;
    _currentTrackTitle = trackTitle;
    _currentStopwatch = Stopwatch()..start();
  }

  /// Mark completion when audio engine emits playing / position change
  void recordComplete() {
    if (_currentStopwatch != null && _currentStopwatch!.isRunning) {
      _currentStopwatch!.stop();
      final delta = _currentStopwatch!.elapsedMilliseconds;
      final metric = LatencyMetric(
        action: _currentAction.isEmpty ? 'Play Action' : _currentAction,
        latencyMs: delta,
        targetBudgetMs: _currentTargetBudget,
        timestamp: DateTime.now(),
        trackTitle: _currentTrackTitle.isEmpty ? 'Active Track' : _currentTrackTitle,
      );

      _metrics.insert(0, metric);
      if (_metrics.length > 50) {
        _metrics.removeLast();
      }

      if (kDebugMode) {
        print(
          '[Melo LatencyProbe] ${metric.action} -> ${metric.latencyMs}ms '
          '(Budget: ${metric.targetBudgetMs}ms) [${metric.passed ? "PASS" : "FAIL"}]',
        );
      }

      _currentStopwatch = null;
      notifyListeners();
    }
  }

  void clearMetrics() {
    _metrics.clear();
    notifyListeners();
  }

  double get averageLatency {
    if (_metrics.isEmpty) return 0.0;
    final sum = _metrics.fold<int>(0, (prev, m) => prev + m.latencyMs);
    return sum / _metrics.length;
  }

  int get p95Latency {
    if (_metrics.isEmpty) return 0;
    final sorted = _metrics.map((m) => m.latencyMs).toList()..sort();
    final index = (sorted.length * 0.95).floor().clamp(0, sorted.length - 1);
    return sorted[index];
  }
}
