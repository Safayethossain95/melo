import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';

class WaveProgressBar extends StatefulWidget {
  final ValueNotifier<Duration> positionNotifier;
  final ValueNotifier<Duration> durationNotifier;
  final List<double> peaks;
  final Function(Duration) onSeek;
  final double height;

  const WaveProgressBar({
    super.key,
    required this.positionNotifier,
    required this.durationNotifier,
    required this.peaks,
    required this.onSeek,
    this.height = 32.0,
  });

  @override
  State<WaveProgressBar> createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<WaveProgressBar> {
  bool _isDragging = false;
  double _dragPercent = 0.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.durationNotifier,
      builder: (context, totalDuration, _) {
        final totalMs = totalDuration.inMilliseconds;

        return ValueListenableBuilder<Duration>(
          valueListenable: widget.positionNotifier,
          builder: (context, currentPosition, _) {
            final currentMs = currentPosition.inMilliseconds;
            final playbackPercent = totalMs > 0
                ? (_isDragging ? _dragPercent : (currentMs / totalMs).clamp(0.0, 1.0))
                : 0.0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragPercent = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPercent = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (totalMs > 0) {
                      final targetMs = (_dragPercent * totalMs).round();
                      widget.onSeek(Duration(milliseconds: targetMs));
                    }
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  onTapDown: (details) {
                    final percent = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    if (totalMs > 0) {
                      final targetMs = (percent * totalMs).round();
                      widget.onSeek(Duration(milliseconds: targetMs));
                    }
                  },
                  child: SizedBox(
                    width: width,
                    height: widget.height,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(width, widget.height),
                        painter: _WaveformPainter(
                          peaks: widget.peaks,
                          progress: playbackPercent,
                          activeGradient: const LinearGradient(
                            colors: [MeloColors.tealLight, MeloColors.primaryTeal],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          inactiveColor: const Color(0x335B7476),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  final Gradient activeGradient;
  final Color inactiveColor;

  _WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.activeGradient,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final barCount = peaks.length;
    final totalSpacing = size.width * 0.35;
    final barSpacing = totalSpacing / (barCount - 1);
    final barWidth = (size.width - totalSpacing) / barCount;
    final midY = size.height / 2;

    final progressX = size.width * progress;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final activePaint = Paint()
      ..shader = activeGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing) + (barWidth / 2);
      final normalizedPeak = peaks[i].clamp(0.15, 1.0);
      final barHalfHeight = (size.height * 0.42) * normalizedPeak;

      final top = midY - barHalfHeight;
      final bottom = midY + barHalfHeight;

      final isPast = x <= progressX;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        isPast ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.peaks != peaks;
  }
}
