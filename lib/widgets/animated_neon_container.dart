import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedNeonContainer extends StatefulWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final Duration duration;
  final Color? backgroundColor;

  const AnimatedNeonContainer({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 16.0,
    this.borderWidth = 1.5,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.alignment,
    this.duration = const Duration(seconds: 4),
    this.backgroundColor,
  });

  @override
  State<AnimatedNeonContainer> createState() => _AnimatedNeonContainerState();
}

class _AnimatedNeonContainerState extends State<AnimatedNeonContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: NeonMarqueePainter(
            color: widget.color,
            animationValue: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            margin: widget.margin,
            alignment: widget.alignment,
            decoration: BoxDecoration(
              // Background fill uses specified color or theme default
              color: widget.backgroundColor ?? AppTheme.cardBackground.withOpacity(0.9),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class NeonMarqueePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final double borderRadius;
  final double borderWidth;

  NeonMarqueePainter({
    required this.color,
    required this.animationValue,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Draw a very subtle background/base border so the box outline is visible
    final baseBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = color.withOpacity(0.12);
    canvas.drawRRect(rrect, baseBorderPaint);

    // 2. Create and compute path metrics for the marquee segments
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;

    // Define length of the moving marquee dashes (e.g. 25% of perimeter)
    final segmentLength = totalLength * 0.25;
    final startPos1 = animationValue * totalLength;
    final endPos1 = startPos1 + segmentLength;

    final extractPath = Path();

    // First chasing capsule segment
    if (endPos1 <= totalLength) {
      extractPath.addPath(metric.extractPath(startPos1, endPos1), Offset.zero);
    } else {
      extractPath.addPath(metric.extractPath(startPos1, totalLength), Offset.zero);
      extractPath.addPath(metric.extractPath(0.0, endPos1 - totalLength), Offset.zero);
    }

    // Second chasing capsule segment (opposite side)
    final startPos2 = (startPos1 + totalLength * 0.5) % totalLength;
    final endPos2 = startPos2 + segmentLength;
    if (endPos2 <= totalLength) {
      extractPath.addPath(metric.extractPath(startPos2, endPos2), Offset.zero);
    } else {
      extractPath.addPath(metric.extractPath(startPos2, totalLength), Offset.zero);
      extractPath.addPath(metric.extractPath(0.0, endPos2 - totalLength), Offset.zero);
    }

    // Outer glow paint (blurred)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 4.0
      ..strokeCap = StrokeCap.round
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    // Sharp foreground marquee paint
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Draw the glow layer first, then the sharp line on top
    canvas.drawPath(extractPath, glowPaint);
    canvas.drawPath(extractPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant NeonMarqueePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}
