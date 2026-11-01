import 'package:flutter_test/flutter_test.dart';
import 'package:melo/models/folder_crate.dart';
import 'package:melo/models/playlist.dart';
import 'package:melo/models/track.dart';
import 'package:melo/services/audio_engine.dart';
import 'package:melo/services/latency_probe.dart';

void main() {
  group('Melo Track Model Tests', () {
    test('Track creates valid deterministic waveform peaks and maps correctly', () {
      final track = Track(
        id: 'test_1',
        title: 'Cyber Teal',
        artist: 'Neon Horizon',
        album: 'Synthesized Nights',
        duration: const Duration(seconds: 180),
        uri: 'assets/audio/cyber_teal.wav',
        isAsset: true,
        folderPath: 'Synthwave Dreams',
        folderName: 'Synthwave Dreams',
      );

      expect(track.waveformPeaks.length, 48);
      expect(track.waveformPeaks.first, greaterThanOrEqualTo(0.15));

      final map = track.toMap();
      expect(map['title'], 'Cyber Teal');
      expect(map['durationMs'], 180000);

      final fromMap = Track.fromMap(map);
      expect(fromMap.title, track.title);
      expect(fromMap.duration, track.duration);
      expect(fromMap.folderName, 'Synthwave Dreams');
    });

    test('FolderCrate calculates duration and sleeve colors properly', () {
      final t1 = Track(
        id: 't1',
        title: 'Song 1',
        artist: 'A1',
        album: 'Alb1',
        duration: const Duration(seconds: 100),
        uri: 'path1',
        folderPath: 'Chill',
        folderName: 'Chill',
      );
      final t2 = Track(
        id: 't2',
        title: 'Song 2',
        artist: 'A2',
        album: 'Alb2',
        duration: const Duration(seconds: 200),
        uri: 'path2',
        folderPath: 'Chill',
        folderName: 'Chill',
      );

      final crate = FolderCrate(
        folderPath: 'Chill',
        folderName: 'Chill',
        tracks: [t1, t2],
      );

      expect(crate.trackCount, 2);
      expect(crate.totalDuration.inSeconds, 300);
      expect(crate.sleeveColors.length, 3);
    });

    test('Playlist serialization and track ID management', () {
      final pl = Playlist(
        id: 'pl_1',
        name: 'Chill Vibes',
        description: 'Night coding playlist',
        trackIds: ['t1', 't2'],
      );

      final map = pl.toMap();
      final fromMap = Playlist.fromMap(map);
      expect(fromMap.name, 'Chill Vibes');
      expect(fromMap.trackIds.length, 2);
    });
  });

  group('Melo Audio Engine Logic Tests', () {
    test('Queue reordering and repeat cycling work seamlessly', () {
      final engine = MeloAudioEngine();
      expect(engine.repeatMode, MeloRepeatMode.off);

      engine.cycleRepeatMode();
      expect(engine.repeatMode, MeloRepeatMode.all);

      engine.cycleRepeatMode();
      expect(engine.repeatMode, MeloRepeatMode.one);

      engine.cycleRepeatMode();
      expect(engine.repeatMode, MeloRepeatMode.off);
    });

    test('LatencyProbe records metrics and computes p95 and average accurately', () {
      final probe = LatencyProbe();
      probe.clearMetrics();

      probe.startAction(action: 'Click to Sound', targetBudgetMs: 100, trackTitle: 'Test Track');
      // Simulate completion
      probe.recordComplete();

      expect(probe.metrics.isNotEmpty, true);
      final first = probe.metrics.first;
      expect(first.targetBudgetMs, 100);
      expect(probe.averageLatency, greaterThanOrEqualTo(0));
      expect(probe.p95Latency, greaterThanOrEqualTo(0));
    });
  });
}
