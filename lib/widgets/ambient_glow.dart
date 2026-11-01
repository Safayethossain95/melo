import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';

class AmbientGlow extends StatelessWidget {
  final Color? dominantColor;
  final Widget child;
  final double opacity;
  final double blurRadius;

  const AmbientGlow({
    super.key,
    this.dominantColor,
    required this.child,
    this.opacity = 0.28,
    this.blurRadius = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = dominantColor ?? MeloColors.primaryTeal;
    final blendTeal = Color.lerp(primary, MeloColors.primaryTeal, 0.45)!;

    return Stack(
      children: [
        // Ambient soft blurred gradient orb
        Positioned(
          top: -120,
          right: -80,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: 480,
            height: 480,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  blendTeal.withValues(alpha: opacity),
                  MeloColors.tealDeep.withValues(alpha: opacity * 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  MeloColors.tealDeep.withValues(alpha: isDark ? opacity * 0.35 : opacity * 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Child content
        child,
      ],
    );
  }
}
