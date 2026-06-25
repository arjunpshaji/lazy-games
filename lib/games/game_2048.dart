import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_2048_provider.dart';
import '../../services/network_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';
import '../../widgets/animated_neon_container.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late NetworkManager _netManager;
  late Game2048Provider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<Game2048Provider>(context, listen: false);
      
      _provider.setupGame();

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == '2048_score') {
            final oppScore = packet['data']['score'] as int;
            _provider.updateOpponentScore(oppScore);
          } else if (packet['type'] == '2048_reset') {
            _provider.setupGame();
          }
        };
      }
    });
  }

  void _onSwipe(String direction) {
    _provider.handleSwipe(direction);
    final netManager = Provider.of<NetworkManager>(context, listen: false);
    if (netManager.isConnected) {
      netManager.sendMessage('2048_score', {'score': _provider.score});
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<Game2048Provider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    // Keyboard handling helper
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _onSwipe('left');
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) _onSwipe('right');
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) _onSwipe('up');
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) _onSwipe('down');
        }
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) _onSwipe('up');
          if (details.primaryVelocity! > 300) _onSwipe('down');
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) _onSwipe('left');
          if (details.primaryVelocity! > 300) _onSwipe('right');
        },
        child: GameShell(
          title: '2048',
          rules: 'Swipe up, down, left, or right (or use Keyboard Arrow Keys) to slide tiles. Matching tiles merge and double. Reach 2048 to win!',
          statusWidget: _buildScoreHeader(provider, netManager.isConnected),
          onReset: () {
            provider.setupGame();
            if (netManager.isConnected) {
              netManager.sendMessage('2048_reset', {});
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.isGameOver)
                AnimatedNeonContainer(
                  color: AppTheme.neonPink,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Text('GAME OVER!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ),
              if (provider.isWon)
                AnimatedNeonContainer(
                  color: AppTheme.neonGreen,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Text('YOU REACHED 2048!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ),

              // 4x4 Grid Layout
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final val = provider.board[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        decoration: _getTileDecoration(val),
                        alignment: Alignment.center,
                        child: Text(
                          val == 0 ? '' : '$val',
                          style: TextStyle(
                            fontSize: val >= 1024 ? 14 : val >= 128 ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: _getTileTextColor(val),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Swipe on board or use Arrow Keys to play',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeader(Game2048Provider provider, bool isNetwork) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Your Score
        _buildScoreBox("YOUR SCORE", provider.score, AppTheme.neonCyan),
        
        // Network Opponent Score or Legend
        if (isNetwork)
          _buildScoreBox("OPPONENT SCORE", provider.opponentScore, AppTheme.neonPink)
        else
          _buildScoreBox("BEST RATING", 2048, AppTheme.neonGreen),
      ],
    );
  }

  Widget _buildScoreBox(String label, int val, Color color) {
    return AnimatedNeonContainer(
      color: color,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('$val', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BoxDecoration _getTileDecoration(int val) {
    if (val == 0) {
      return BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      );
    }

    // Custom gradient glow depending on values
    Color tileGlowColor = Colors.white;
    switch (val) {
      case 2:
        tileGlowColor = AppTheme.neonCyan.withOpacity(0.3);
        break;
      case 4:
        tileGlowColor = AppTheme.neonCyan.withOpacity(0.6);
        break;
      case 8:
        tileGlowColor = AppTheme.neonOrange.withOpacity(0.4);
        break;
      case 16:
        tileGlowColor = AppTheme.neonOrange.withOpacity(0.8);
        break;
      case 32:
        tileGlowColor = AppTheme.neonPink.withOpacity(0.5);
        break;
      case 64:
        tileGlowColor = AppTheme.neonPink.withOpacity(0.9);
        break;
      case 128:
        tileGlowColor = AppTheme.neonViolet.withOpacity(0.4);
        break;
      case 256:
        tileGlowColor = AppTheme.neonViolet.withOpacity(0.8);
        break;
      case 512:
        tileGlowColor = AppTheme.neonGreen.withOpacity(0.5);
        break;
      case 1024:
        tileGlowColor = AppTheme.neonGreen.withOpacity(0.8);
        break;
      case 2048:
        tileGlowColor = Colors.amber;
        break;
      default:
        tileGlowColor = Colors.amberAccent;
    }

    return BoxDecoration(
      color: tileGlowColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: tileGlowColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: tileGlowColor.withOpacity(0.2),
          blurRadius: 8,
        ),
      ],
    );
  }

  Color _getTileTextColor(int val) {
    switch (val) {
      case 2:
      case 4:
        return AppTheme.neonCyan;
      case 8:
      case 16:
        return AppTheme.neonOrange;
      case 32:
      case 64:
        return AppTheme.neonPink;
      case 128:
      case 256:
        return AppTheme.neonViolet;
      case 512:
      case 1024:
        return AppTheme.neonGreen;
      default:
        return Colors.amber;
    }
  }
}
