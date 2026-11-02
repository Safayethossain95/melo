import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';

class LiveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? color;

  const LiveVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 16,
    this.height = 36.0,
    this.color,
  });

  @override
  State<LiveVisualizer> createState() => _LiveVisualizerState();
}

class _LiveVisualizerState extends State<LiveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _randomPhase = [];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    for (int i = 0; i < widget.barCount; i++) {
      _randomPhase.add(rng.nextDouble() * 2 * pi);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant LiveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * pi;
          final baseColor = widget.color ?? MeloColors.primaryTeal;

        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (index) {
              final phase = _randomPhase[index];
              // Sine wave motion with harmonic perturbation
              double energy = widget.isPlaying
                  ? (sin(t * 2.5 + phase) * 0.45 +
                      cos(t * 1.5 + phase * 2) * 0.35 +
                      0.6).clamp(0.12, 1.0)
                  : 0.15;

              final barHeight = (widget.height * energy).clamp(4.0, widget.height);
              final barWidth = widget.barCount <= 4 ? 3.0 : 3.5;
              final barMargin = widget.barCount <= 4 ? 1.5 : 2.0;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: barMargin),
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MeloColors.tealLight,
                      baseColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: widget.isPlaying
                      ? [
                          BoxShadow(
                            color: MeloColors.primaryTeal.withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    ),
  );
}
}
