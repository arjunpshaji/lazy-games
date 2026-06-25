import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../services/audio_service.dart';

class GlassButton extends StatefulWidget {
  final Widget label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isFullWidth;
  final double borderRadius;
  final bool isPrimary;
  final bool hasShimmer;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.color,
    this.isFullWidth = true,
    this.borderRadius = 24.0, // rounded-xl (24px) for controls in the design system
    this.isPrimary = true,
    this.hasShimmer = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.hasShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasShimmer != oldWidget.hasShimmer) {
      if (widget.hasShimmer) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      AudioService.instance.buttonTap();
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
    final resolvedColor = widget.isPrimary ? Colors.white : widget.color;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (hasIcon) ...[
          IconTheme(
            data: IconThemeData(
              color: resolvedColor,
              size: 20,
            ),
            child: widget.icon!,
          ),
          const SizedBox(width: 8),
        ],
        DefaultTextStyle.merge(
          style: TextStyle(
            color: resolvedColor,
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
      // Primary: Dynamic gradient based on theme color, 1px white border, medium elevation blur
      container = GlassContainer(
        borderRadius: widget.borderRadius,
        borderWidth: 1.0,
        borderColor: Colors.white.withOpacity(0.30),
        elevation: GlassElevation.medium,
        primaryColor: widget.color,
        gradient: LinearGradient(
          colors: [
            widget.color,
            widget.color.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: buttonContent,
      );
    } else {
      // Secondary/Ghost: No fill, 1.5px matching border, high-blur backdrop
      container = GlassContainer(
        borderRadius: widget.borderRadius,
        borderWidth: 1.5,
        borderColor: widget.color.withOpacity(0.40),
        fillColor: Colors.white.withOpacity(0.02),
        elevation: GlassElevation.high, // high-blur backdrop
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: buttonContent,
      );
    }

    Widget buildContainer(Widget containerWidget) {
      if (!widget.hasShimmer) return containerWidget;
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final double t = _shimmerController.value;
          // Map t: sweep in the first 45%, pause for the rest of the cycle
          final double progress;
          if (t < 0.45) {
            progress = t / 0.45;
          } else {
            progress = 1.0;
          }
          final double startX = -3.0 + 4.5 * progress;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              containerWidget,
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(startX, -1.0),
                          end: Alignment(startX + 1.5, 1.0),
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.24),
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    final childContainer = buildContainer(container);

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
          child: childContainer,
        ),
      ),
    );
  }
}

