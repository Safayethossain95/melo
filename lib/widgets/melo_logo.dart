import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';

class MeloLogo extends StatelessWidget {
  final double fontSize;
  final bool showGlow;
  final Color? color;

  const MeloLogo({
    super.key,
    this.fontSize = 24,
    this.showGlow = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = color ?? (isDark ? MeloColors.darkTextPrimary : MeloColors.lightTextPrimary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sound wave vector glyph
        Container(
          width: fontSize * 1.15,
          height: fontSize * 1.15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [MeloColors.primaryTeal, MeloColors.tealDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: MeloColors.primaryTeal.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: CustomPaint(
              size: Size(fontSize * 0.65, fontSize * 0.65),
              painter: _SoundWaveGlyphPainter(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 9),
        // Wordmark text: 'melo' lowercase with dot
        Text.rich(
          TextSpan(
            text: 'melo',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: primaryTextColor,
            ),
            children: [
              TextSpan(
                text: '.',
                style: TextStyle(
                  color: MeloColors.tealLight,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoundWaveGlyphPainter extends CustomPainter {
  final Color color;

  _SoundWaveGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // 4 soundwave bars of varying heights
    final bars = [
      (x: w * 0.15, top: h * 0.35, bottom: h * 0.65),
      (x: w * 0.38, top: h * 0.15, bottom: h * 0.85),
      (x: w * 0.62, top: h * 0.25, bottom: h * 0.75),
      (x: w * 0.85, top: h * 0.40, bottom: h * 0.60),
    ];

    for (final bar in bars) {
      canvas.drawLine(
        Offset(bar.x, bar.top),
        Offset(bar.x, bar.bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWaveGlyphPainter oldDelegate) => false;
}
