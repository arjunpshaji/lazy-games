import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/memory_match_provider.dart';
import '../../services/network_manager.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  late NetworkManager _netManager;
  late MemoryMatchProvider _provider;

  final List<String> _cardEmojis = [
    '🐶', '✈️', '🍕', '🚀',
    '🎨', '🎵', '🏆', '🎮'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<MemoryMatchProvider>(context, listen: false);
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'memory_setup') {
            final cards = List<int>.from(packet['data']['cards']);
            _provider.setupGame(isNetwork: true, role: role, preShuffledCards: cards);
          } else if (packet['type'] == 'memory_tap') {
            final idx = packet['data']['index'] as int;
            _provider.handleNetworkTap(idx);
          } else if (packet['type'] == 'memory_reset') {
            _generateAndSyncNetworkGame();
          }
        };

        if (role == 'host') {
          _generateAndSyncNetworkGame();
        }
      } else {
        _provider.setupGame(isNetwork: false, role: role);
      }
    });
  }

  void _generateAndSyncNetworkGame() {
    final cards = List.generate(8, (i) => i) + List.generate(8, (i) => i);
    cards.shuffle();
    
    _provider.setupGame(isNetwork: true, role: 'host', preShuffledCards: cards);
    _netManager.sendMessage('memory_setup', {'cards': cards});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemoryMatchProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    Widget statusWidget;
    if (provider.isGameOver) {
      String winnerText;
      if (provider.player1Score == provider.player2Score) {
        winnerText = "MATCH DRAW!";
      } else {
        final win1 = provider.player1Score > provider.player2Score;
        if (provider.isNetworkGame) {
          final iWon = (provider.myRole == 'host' && win1) || (provider.myRole == 'client' && !win1);
          winnerText = iWon ? "YOU WIN!" : "OPPONENT WINS!";
        } else {
          winnerText = win1 ? "PLAYER 1 WINS!" : "PLAYER 2 WINS!";
        }
      }
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonGreen),
        child: Text(winnerText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      );
    } else {
      String turnText;
      final isMyTurn = provider.isMyTurn;
      if (provider.isNetworkGame) {
        turnText = isMyTurn ? "YOUR TURN" : "OPPONENT'S TURN";
      } else {
        turnText = provider.isPlayer1Turn ? "PLAYER 1'S TURN" : "PLAYER 2'S TURN";
      }

      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(
          color: provider.isPlayer1Turn ? AppTheme.neonCyan : AppTheme.neonViolet,
        ),
        child: Text(turnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }

    final hasWinner = provider.isGameOver && provider.player1Score != provider.player2Score;
    final win1 = provider.player1Score > provider.player2Score;
    final iWon = provider.isNetworkGame &&
        ((provider.myRole == 'host' && win1) || (provider.myRole == 'client' && !win1));

    final isWinner = provider.isNetworkGame ? (provider.isGameOver && iWon) : hasWinner;
    final winSubtitle = provider.isNetworkGame
        ? 'YOU WON!'
        : (win1 ? 'PLAYER 1 WINS!' : 'PLAYER 2 WINS!');

    return GameShell(
      title: 'Memory Match',
      rules: 'Flip cards and find matching pairs. Find a match to earn another turn. Complete all pairs to finish the game.',
      statusWidget: statusWidget,
      isWinner: isWinner,
      winSubtitle: winSubtitle,
      onReset: provider.isNetworkGame && provider.myRole != 'host'
          ? null
          : () {
              if (provider.isNetworkGame) {
                _generateAndSyncNetworkGame();
                netManager.sendMessage('memory_reset', {});
              } else {
                provider.setupGame(isNetwork: false, role: 'host');
              }
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scores Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerScore(
                provider.isNetworkGame ? (provider.myRole == 'host' ? "YOU (P1)" : "OPPONENT (P1)") : "PLAYER 1",
                provider.player1Score,
                AppTheme.neonCyan,
                provider.isPlayer1Turn,
              ),
              _buildPlayerScore(
                provider.isNetworkGame ? (provider.myRole == 'client' ? "YOU (P2)" : "OPPONENT (P2)") : "PLAYER 2",
                provider.player2Score,
                AppTheme.neonViolet,
                !provider.isPlayer1Turn,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4x4 Cards Grid
          if (provider.cards.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  final isFlipped = provider.flipped[index];
                  final isMatched = provider.matched[index];
                  
                  return GestureDetector(
                    onTap: () async {
                      if (provider.isMyTurn && !isFlipped && !isMatched && !provider.isWaiting) {
                        AudioService.instance.cardFlip();
                        final success = await provider.handleCardTap(index);
                        if (success && provider.isNetworkGame) {
                          netManager.sendMessage('memory_tap', {'index': index});
                        }
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: _transitionBuilder,
                      layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
                      child: isFlipped || isMatched
                          ? Container(
                              key: const ValueKey(true),
                              decoration: BoxDecoration(
                                color: isMatched ? AppTheme.neonGreen.withOpacity(0.1) : AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMatched ? AppTheme.neonGreen : AppTheme.neonCyan,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _cardEmojis[provider.cards[index]],
                                style: const TextStyle(fontSize: 32),
                              ),
                            )
                          : Container(
                              key: const ValueKey(false),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.neonViolet.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.help_outline, color: Colors.white, size: 28),
                            ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String label, int score, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: isActive ? color : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    final rotateAnim = Tween<double>(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: child,
      builder: (context, child) {
        final isUnder = (const ValueKey(true) != child?.key);
        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        tilt = isUnder ? -tilt : tilt;
        final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
        return Transform(
          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}
