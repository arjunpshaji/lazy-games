import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassElevation { low, medium, high }

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color? borderColor;
  final Color? fillColor;
  final double? blurSigma;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final GlassElevation elevation;
  final Color? primaryColor;
  final bool hasRimLighting;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.borderWidth = 1.0,
    this.borderColor,
    this.fillColor,
    this.blurSigma,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.boxShadow,
    this.elevation = GlassElevation.low,
    this.primaryColor,
    this.hasRimLighting = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolve design system defaults based on elevation
    double defaultBlur;
    Color defaultFill;
    Color defaultBorder;

    switch (elevation) {
      case GlassElevation.low:
        defaultBlur = 20.0;
        defaultFill = Colors.white.withOpacity(0.10);
        defaultBorder = Colors.white.withOpacity(0.15);
        break;
      case GlassElevation.medium:
        defaultBlur = 40.0;
        defaultFill = Colors.white.withOpacity(0.15);
        defaultBorder = Colors.white.withOpacity(0.30);
        break;
      case GlassElevation.high:
        defaultBlur = 64.0;
        defaultFill = Colors.white.withOpacity(0.25);
        defaultBorder = Colors.white.withOpacity(0.35);
        break;
    }

    final finalBlur = blurSigma ?? defaultBlur;
    final finalFillColor = fillColor ?? defaultFill;
    final finalBorderColor = borderColor ?? defaultBorder;

    // 2. Resolve soft outer glows for medium elevation active elements
    final List<BoxShadow> resolvedShadows = [];
    if (boxShadow != null) {
      resolvedShadows.addAll(boxShadow!);
    }
    if (elevation == GlassElevation.medium) {
      resolvedShadows.add(
        BoxShadow(
          color: (primaryColor ?? const Color(0xFF7000FF)).withOpacity(0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: resolvedShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: finalBlur, sigmaY: finalBlur),
          child: CustomPaint(
            foregroundPainter: GlassBorderPainter(
              borderRadius: borderRadius,
              borderWidth: borderWidth,
              outerBorderColor: finalBorderColor,
              hasRimLighting: hasRimLighting,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: gradient == null ? finalFillColor : null,
                gradient: gradient,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Color outerBorderColor;
  final bool hasRimLighting;

  GlassBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.outerBorderColor,
    required this.hasRimLighting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Draw outer stroke
    final outerPaint = Paint()
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..color = outerBorderColor;

    final outerRRect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius - borderWidth / 2),
    );
    canvas.drawRRect(outerRRect, outerPaint);

    // 2. Draw inner linear gradient stroke (Rim Lighting)
    if (hasRimLighting &&
        size.width > borderWidth * 2 &&
        size.height > borderWidth * 2) {
      final rimPaint = Paint()
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.40),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect.deflate(borderWidth));

      final rimRRect = RRect.fromRectAndRadius(
        rect.deflate(borderWidth + 0.5),
        Radius.circular(borderRadius - borderWidth - 0.5),
      );
      canvas.drawRRect(rimRRect, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GlassBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.outerBorderColor != outerBorderColor ||
        oldDelegate.hasRimLighting != hasRimLighting;
  }
}
