import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassButton extends StatefulWidget {
  final Widget label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isFullWidth;
  final double borderRadius;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.color,
    this.isFullWidth = true,
    this.borderRadius = 24.0, // rounded-xl (24px) for controls in the design system
    this.isPrimary = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _scale = 0.95; // Juicy press feedback
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasIcon = widget.icon != null;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (hasIcon) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        DefaultTextStyle.merge(
          style: TextStyle(
            color: widget.isPrimary ? Colors.white : widget.color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
          child: widget.label,
        ),
      ],
    );

    Widget container;

    if (widget.isPrimary) {
      // Primary: Gradient fill, 1px white border, medium elevation blur
      container = GlassContainer(
        borderRadius: widget.borderRadius,
        borderWidth: 1.0,
        borderColor: Colors.white.withOpacity(0.30),
        elevation: GlassElevation.medium,
        primaryColor: widget.color,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7000FF), // Electric Purple
            const Color(0xFF00EEFC), // Vibrant Cyan
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: buttonContent,
      );
    } else {
      // Secondary/Ghost: No fill, 1.5px semi-transparent white border, high-blur backdrop
      container = GlassContainer(
        borderRadius: widget.borderRadius,
        borderWidth: 1.5,
        borderColor: Colors.white.withOpacity(0.25),
        fillColor: Colors.white.withOpacity(0.02),
        elevation: GlassElevation.high, // high-blur backdrop
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: buttonContent,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: container,
        ),
      ),
    );
  }
}
