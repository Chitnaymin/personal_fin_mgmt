import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const BouncyButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final double _scaleFactor = 0.95;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : _onTapDown,
      onTapUp: widget.onPressed == null ? null : _onTapUp,
      onTapCancel: widget.onPressed == null ? null : _onTapCancel,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: _scaleFactor,
        ).animate(_controller),
        child: widget.child,
      ),
    );
  }
}