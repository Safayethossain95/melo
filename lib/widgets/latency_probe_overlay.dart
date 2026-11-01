import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../services/latency_probe.dart';
import 'glass_container.dart';

class LatencyProbeOverlay extends StatelessWidget {
  const LatencyProbeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final probe = LatencyProbe();

    return ListenableBuilder(
      listenable: probe,
      builder: (context, _) {
        if (!probe.overlayVisible) return const SizedBox.shrink();

        final avg = probe.averageLatency.toStringAsFixed(1);
        final p95 = probe.p95Latency;
        final metrics = probe.metrics;

        return Positioned(
          top: 70,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 380,
              child: GlassContainer(
                borderRadius: 18.0,
                blur: 24.0,
                backgroundColor: MeloColors.darkBgBase.withValues(alpha: 0.92),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: MeloColors.tealLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Instant Playback Probe',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MeloColors.darkTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              color: MeloColors.darkTextMuted,
                              onPressed: probe.clearMetrics,
                              tooltip: 'Clear metrics',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: MeloColors.darkTextMuted,
                              onPressed: probe.toggleOverlay,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Summary Stats
                    Row(
                      children: [
                        _buildStatCard('Avg Latency', '${avg}ms', MeloColors.primaryTeal),
                        const SizedBox(width: 8),
                        _buildStatCard('p95 Latency', '${p95}ms', p95 <= 100 ? MeloColors.tealLight : MeloColors.warningAmber),
                        const SizedBox(width: 8),
                        _buildStatCard('Budget', '<100ms', MeloColors.darkTextSecondary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: MeloColors.darkBorder, height: 1),
                    const SizedBox(height: 8),
                    // History list
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: metrics.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'Interact with player to log latency events',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MeloColors.darkTextMuted,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: metrics.length,
                              itemBuilder: (context, i) {
                                final m = metrics[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.action,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: MeloColors.darkTextPrimary,
                                              ),
                                            ),
                                            Text(
                                              m.trackTitle,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: MeloColors.darkTextMuted,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: m.passed
                                              ? MeloColors.primaryTeal.withValues(alpha: 0.15)
                                              : MeloColors.favoriteRed.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: m.passed
                                                ? MeloColors.primaryTeal.withValues(alpha: 0.4)
                                                : MeloColors.favoriteRed.withValues(alpha: 0.4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          '${m.latencyMs}ms (${m.passed ? "PASS" : "FAIL"})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: m.passed ? MeloColors.tealLight : MeloColors.favoriteRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Toggle overlay anytime with Ctrl+Shift+L',
                        style: TextStyle(
                          fontSize: 10,
                          color: MeloColors.darkTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: MeloColors.darkSurface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MeloColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: MeloColors.darkTextMuted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
