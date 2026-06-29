import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lottie/lottie.dart';
import 'glass_button.dart';
import 'glass_container.dart';

class WinOverlay extends StatelessWidget {
  final bool isVisible;
  final String title;
  final String subtitle;
  final VoidCallback? onPlayAgain;
  /// When true, hides Play Again and shows 'Waiting for host to restart...' instead.
  /// Set when the local player is the non-host in a LAN or online session.
  final bool isOnlineOrNetworkGuest;

  const WinOverlay({
    super.key,
    required this.isVisible,
    this.title = 'CONGRATULATIONS!',
    required this.subtitle,
    this.onPlayAgain,
    this.isOnlineOrNetworkGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: isVisible
          ? Stack(
              key: const ValueKey('win_overlay_content'),
              alignment: Alignment.center,
              children: [
                // 1. Blur and Dark Background Overlay
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: AppTheme.darkBackground.withOpacity(0.75),
                    ),
                  ),
                ),

                // 2. Crackers Lottie Animation in Background
                Positioned.fill(
                  child: Lottie.asset(
                    'assets/lottie/crackers.json',
                    fit: BoxFit.cover,
                    repeat: true,
                  ),
                ),

                // 3. Central Card — orientation-aware layout
                SafeArea(
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      final isLandscape = orientation == Orientation.landscape;
                      return Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLandscape ? 16 : 24,
                            vertical: isLandscape ? 8 : 16,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isLandscape ? 600 : 400,
                            ),
                            child: GlassContainer(
                              elevation: GlassElevation.high,
                              borderColor: AppTheme.neonCyan.withOpacity(0.35),
                              borderRadius: 28,
                              padding: EdgeInsets.all(isLandscape ? 16 : 28),
                              child: isLandscape
                                  ? _buildLandscapeContent(context)
                                  : _buildPortraitContent(context),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  /// Portrait: trophy stacked above text and buttons.
  Widget _buildPortraitContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Lottie.asset(
            'assets/lottie/trophy.json',
            width: 180,
            height: 180,
            repeat: true,
          ),
        ),
        const SizedBox(height: 12),
        ..._textContent(),
        const SizedBox(height: 28),
        ..._buttons(context),
      ],
    );
  }

  /// Landscape: trophy on the left, text + buttons on the right.
  Widget _buildLandscapeContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/lottie/trophy.json',
          width: 110,
          height: 110,
          repeat: true,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._textContent(),
              const SizedBox(height: 16),
              ..._buttons(context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _textContent() {
    return [
      Text(
        title,
        textAlign: TextAlign.center,
        style: AppTheme.headlineMd.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: AppTheme.neonPink,
          shadows: [
            Shadow(color: AppTheme.neonPink.withOpacity(0.65), blurRadius: 16),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: AppTheme.bodyLg.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.neonCyan,
          shadows: [
            Shadow(color: AppTheme.neonCyan.withOpacity(0.5), blurRadius: 10),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buttons(BuildContext context) {
    if (!isOnlineOrNetworkGuest && onPlayAgain != null) {
      return [
        GlassButton(
          label: const Text('PLAY AGAIN'),
          color: AppTheme.neonViolet,
          onPressed: onPlayAgain,
          isPrimary: true,
        ),
        const SizedBox(height: 10),
        GlassButton(
          label: const Text('MAIN MENU'),
          color: AppTheme.neonCyan,
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: false,
        ),
      ];
    } else {
      return [
        Text(
          isOnlineOrNetworkGuest
              ? 'Waiting for host to restart...'
              : 'Waiting for host to restart...',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMd.copyWith(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        GlassButton(
          label: const Text('MAIN MENU'),
          color: AppTheme.neonCyan,
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: false,
        ),
      ];
    }
  }
}
