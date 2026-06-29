import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidGlassBackground extends StatefulWidget {
  const LiquidGlassBackground({super.key});

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Cached shaders to prevent allocating them on every paint tick
  Shader? _shaderBlob1;
  Shader? _shaderBlob2;
  Shader? _shaderBlob3;
  Shader? _shaderBlob4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initShaders();
  }

  void _initShaders() {
    Shader createShader(double radius, Color baseColor) {
      return RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.55),
          baseColor.withValues(alpha: 0.35),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    }

    _shaderBlob1 = createShader(180, const Color(0xFF00F0FF));
    _shaderBlob2 = createShader(210, const Color(0xFFC000FF));
    _shaderBlob3 = createShader(170, const Color(0xFFFF007F));
    _shaderBlob4 = createShader(150, const Color(0xFF00FF66));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shaderBlob1 == null ||
        _shaderBlob2 == null ||
        _shaderBlob3 == null ||
        _shaderBlob4 == null) {
      return Container(color: const Color(0xFF08090E));
    }

    return Stack(
      children: [
        // Pure deep dark base
        Container(color: const Color(0xFF08090E)),
        // Animated liquid blobs painted via CustomPainter for high performance
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: BlobsPainter(
                animationValue: _controller.value,
                shaderBlob1: _shaderBlob1!,
                shaderBlob2: _shaderBlob2!,
                shaderBlob3: _shaderBlob3!,
                shaderBlob4: _shaderBlob4!,
              ),
            );
          },
        ),
        // Deep gradient to anchor UI readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x4D08090E), // 30% opacity
                Color(0x8C08090E), // 55% opacity
                Color(0xD908090E), // 85% opacity
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BlobsPainter extends CustomPainter {
  final double animationValue;
  final Shader shaderBlob1;
  final Shader shaderBlob2;
  final Shader shaderBlob3;
  final Shader shaderBlob4;

  BlobsPainter({
    required this.animationValue,
    required this.shaderBlob1,
    required this.shaderBlob2,
    required this.shaderBlob3,
    required this.shaderBlob4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    void drawBlob(Canvas canvas, Offset center, double radius, Shader shader) {
      final paint = Paint()..shader = shader;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawCircle(Offset.zero, radius, paint);
      canvas.restore();
    }

    // Blob 1: Cyan
    final blob1Center = Offset(
      (0.25 + 0.15 * math.sin(t)) * w,
      (0.3 + 0.12 * math.cos(t)) * h,
    );
    drawBlob(canvas, blob1Center, 180, shaderBlob1);

    // Blob 2: Violet
    final blob2Center = Offset(
      (0.75 + 0.12 * math.cos(t * 0.8 + 1.0)) * w,
      (0.6 + 0.18 * math.sin(t * 0.8 + 1.0)) * h,
    );
    drawBlob(canvas, blob2Center, 210, shaderBlob2);

    // Blob 3: Pink
    final blob3Center = Offset(
      (0.45 + 0.15 * math.sin(t * 1.2 + 2.0)) * w,
      (0.75 + 0.1 * math.cos(t * 1.5 + 2.0)) * h,
    );
    drawBlob(canvas, blob3Center, 170, shaderBlob3);

    // Blob 4: Soft Emerald Green
    final blob4Center = Offset(
      (0.15 + 0.1 * math.cos(t * 0.5 + 3.0)) * w,
      (0.85 + 0.08 * math.sin(t * 0.6 + 3.0)) * h,
    );
    drawBlob(canvas, blob4Center, 150, shaderBlob4);
  }

  @override
  bool shouldRepaint(covariant BlobsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
