import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background subtle grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(
                painter: BackgroundGridPainter(),
              ),
            ),
          ),
          
          // Logo & Title
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glow Puzzle Icon
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: LogoPainter(),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        Text(
                          'LAZY GAMES',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 36,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              const Shadow(
                                color: AppTheme.neonCyan,
                                blurRadius: 15,
                              ),
                              const Shadow(
                                color: AppTheme.neonViolet,
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A MIND GAMES SUITE',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.8),
                            fontSize: 14,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Loading Indicator Bottom
          Positioned(
            bottom: 80,
            left: 50,
            right: 50,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 4,
                    width: 200,
                    color: Colors.white10,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'LOADING STAGES...',
                  style: TextStyle(
                    color: AppTheme.neonCyan.withOpacity(0.6),
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    // Draw interlocking puzzle outline
    final path = Path();
    
    // Draw neon cyan piece
    paint.color = AppTheme.neonCyan;
    path.moveTo(width * 0.1, height * 0.1);
    path.lineTo(width * 0.4, height * 0.1);
    // circle connector
    path.arcToPoint(
      Offset(width * 0.6, height * 0.1),
      radius: Radius.circular(width * 0.1),
      clockwise: true,
    );
    path.lineTo(width * 0.9, height * 0.1);
    path.lineTo(width * 0.9, height * 0.4);
    path.arcToPoint(
      Offset(width * 0.9, height * 0.6),
      radius: Radius.circular(height * 0.1),
      clockwise: false,
    );
    path.lineTo(width * 0.9, height * 0.9);
    path.lineTo(width * 0.6, height * 0.9);
    path.arcToPoint(
      Offset(width * 0.4, height * 0.9),
      radius: Radius.circular(width * 0.1),
      clockwise: true,
    );
    path.lineTo(width * 0.1, height * 0.9);
    path.lineTo(width * 0.1, height * 0.6);
    path.arcToPoint(
      Offset(width * 0.1, height * 0.4),
      radius: Radius.circular(height * 0.1),
      clockwise: false,
    );
    path.close();

    // Shadow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.neonCyan.withOpacity(0.4)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(path, paint);

    // Draw inner cross neon violet piece
    final innerPaint = Paint()
      ..color = AppTheme.neonViolet
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final innerPath = Path();
    innerPath.moveTo(width * 0.3, height * 0.5);
    innerPath.lineTo(width * 0.7, height * 0.5);
    innerPath.moveTo(width * 0.5, height * 0.3);
    innerPath.lineTo(width * 0.5, height * 0.7);

    canvas.drawPath(
      innerPath,
      Paint()
        ..color = AppTheme.neonViolet.withOpacity(0.4)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    double gridStep = 40.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
