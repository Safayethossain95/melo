import 'package:flutter/material.dart';

/// Interactive bouncy tap wrapper that zooms out slightly when clicked
/// and springs/bounces back with an organic, lively physical feel.
class BouncingTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration forwardDuration;
  final Duration reverseDuration;
  final HitTestBehavior behavior;

  const BouncingTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.88,
    this.forwardDuration = const Duration(milliseconds: 90),
    this.reverseDuration = const Duration(milliseconds: 220),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.forwardDuration,
      reverseDuration: widget.reverseDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) async {
    if (_controller.value < 0.5) {
      await _controller.forward();
    }
    if (mounted) {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
