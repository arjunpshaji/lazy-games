import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidGlassBackground extends StatefulWidget {
  const LiquidGlassBackground({super.key});

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pure deep dark base
        Container(
          color: const Color(0xFF08090E),
        ),
        // Animated liquid blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * math.pi;

            // Compute coordinates using varying trigonometric functions for organic movement
            final blob1X = 0.25 + 0.15 * math.sin(t);
            final blob1Y = 0.3 + 0.12 * math.cos(t);

            final blob2X = 0.75 + 0.12 * math.cos(t * 0.8 + 1.0);
            final blob2Y = 0.6 + 0.18 * math.sin(t * 0.8 + 1.0);

            final blob3X = 0.45 + 0.15 * math.sin(t * 1.2 + 2.0);
            final blob3Y = 0.75 + 0.1 * math.cos(t * 1.5 + 2.0);

            final blob4X = 0.15 + 0.1 * math.cos(t * 0.5 + 3.0);
            final blob4Y = 0.85 + 0.08 * math.sin(t * 0.6 + 3.0);

            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                return Stack(
                  children: [
                    // Blob 1: Cyan
                    Positioned(
                      left: blob1X * w - 180,
                      top: blob1Y * h - 180,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00F0FF).withOpacity(0.18),
                              const Color(0xFF00F0FF).withOpacity(0.06),
                              const Color(0xFF00F0FF).withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Blob 2: Violet
                    Positioned(
                      left: blob2X * w - 210,
                      top: blob2Y * h - 210,
                      child: Container(
                        width: 420,
                        height: 420,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFC000FF).withOpacity(0.18),
                              const Color(0xFFC000FF).withOpacity(0.06),
                              const Color(0xFFC000FF).withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Blob 3: Pink
                    Positioned(
                      left: blob3X * w - 170,
                      top: blob3Y * h - 170,
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF007F).withOpacity(0.15),
                              const Color(0xFFFF007F).withOpacity(0.05),
                              const Color(0xFFFF007F).withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Blob 4: Soft Emerald Green
                    Positioned(
                      left: blob4X * w - 150,
                      top: blob4Y * h - 150,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00FF66).withOpacity(0.12),
                              const Color(0xFF00FF66).withOpacity(0.04),
                              const Color(0xFF00FF66).withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        // Deep gradient to anchor UI readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF08090E).withOpacity(0.3),
                const Color(0xFF08090E).withOpacity(0.55),
                const Color(0xFF08090E).withOpacity(0.85),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
