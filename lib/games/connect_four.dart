import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lazy_games/providers/connect_four_provider.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  late NetworkManager _netManager;
  late ConnectFourProvider _provider;
  bool _wasMyTurn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<ConnectFourProvider>(context, listen: false);

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      _provider.setupGame(isNetwork: isNetwork, role: role);
      _wasMyTurn = _provider.isMyTurn;
      _provider.addListener(_onProviderChanged);

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'c4_drop') {
            final col = packet['data']['column'] as int;
            _provider.handleNetworkDrop(col);
          } else if (packet['type'] == 'c4_reset') {
            _provider.setupGame(isNetwork: true, role: role);
          }
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ConnectFourProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    Widget statusWidget;
    if (provider.winner != 0) {
      String winnerText;
      if (provider.winner == 3) {
        winnerText = "MATCH DRAW!";
      } else {
        if (provider.isNetworkGame) {
          final iWon =
              (provider.myRole == 'host' && provider.winner == 1) ||
              (provider.myRole == 'client' && provider.winner == 2);
          winnerText = iWon ? "YOU WIN!" : "OPPONENT WINS!";
        } else {
          winnerText = provider.winner == 1
              ? "PLAYER 1 WINS!"
              : "PLAYER 2 WINS!";
        }
      }
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(
          color: provider.winner == 3 ? Colors.grey : AppTheme.neonGreen,
        ),
        child: Text(
          winnerText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    } else {
      String turnText;
      final isMyTurn = provider.isMyTurn;
      if (provider.isNetworkGame) {
        turnText = isMyTurn ? "YOUR TURN" : "OPPONENT'S TURN";
      } else {
        turnText = provider.isPlayer1Turn
            ? "PLAYER 1'S TURN (CYAN)"
            : "PLAYER 2'S TURN (VIOLET)";
      }

      statusWidget = _PulsingTurnIndicator(
        text: turnText,
        color: provider.isPlayer1Turn ? AppTheme.neonCyan : AppTheme.neonViolet,
        pulse: provider.isNetworkGame ? isMyTurn : true,
      );
    }

    final iWon =
        (provider.myRole == 'host' && provider.winner == 1) ||
        (provider.myRole == 'client' && provider.winner == 2);
    final isWinner =
        provider.winner != 0 &&
        provider.winner != 3 &&
        (!provider.isNetworkGame || iWon);
    final winSubtitle = provider.isNetworkGame
        ? 'YOU WON!'
        : (provider.winner == 1 ? 'PLAYER 1 WINS!' : 'PLAYER 2 WINS!');

    return GameShell(
      title: 'Connect Four',
      rules:
          'Select a column to drop a chip. First to align 4 chips in a row (horizontally, vertically, or diagonally) wins.',
      statusWidget: statusWidget,
      isWinner: isWinner,
      winSubtitle: winSubtitle,
      isInProgress:
          provider.winner == 0 && provider.board.any((cell) => cell != 0),
      onReset:
          provider.isNetworkGame &&
              provider.myRole != 'host' &&
              provider.winner != 0
          ? null
          : () {
              if (provider.isNetworkGame) {
                _provider.setupGame(isNetwork: true, role: provider.myRole);
                netManager.sendMessage('c4_reset', {});
              } else {
                _provider.setupGame(isNetwork: false, role: 'host');
              }
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isNetworkGame) ...[
            Text(
              "Your Color: ${provider.myRole == 'host' ? 'Cyan' : 'Violet'}",
              style: TextStyle(
                color: provider.myRole == 'host'
                    ? AppTheme.neonCyan
                    : AppTheme.neonViolet,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Column Selectors (Top Row Arrows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (col) {
              return Expanded(
                child: IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  color: provider.isMyTurn && provider.winner == 0
                      ? (provider.isPlayer1Turn
                            ? AppTheme.neonCyan
                            : AppTheme.neonViolet)
                      : Colors.white24,
                  onPressed: () {
                    if (provider.isMyTurn && provider.winner == 0) {
                      final success = provider.dropDisc(col);
                      if (success) {
                        AudioService.instance.gameMove();
                        if (provider.isNetworkGame) {
                          netManager.sendMessage('c4_drop', {'column': col});
                        }
                      }
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Connect 4 Board Frame
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[900]?.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              // border: Border.all(color: Colors.blue[600]!, width: 3),
              border: provider.isPlayer1Turn
                  ? Border.all(color: AppTheme.neonCyan, width: 3)
                  : Border.all(color: AppTheme.neonViolet, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[900]!.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final cell = provider.board[index];
                final isWinning = provider.winningCells.contains(index);

                Color discColor = Colors.transparent;
                if (cell == 1) {
                  discColor = AppTheme.neonCyan;
                } else if (cell == 2) {
                  discColor = AppTheme.neonViolet;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black26, // cutout slot
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWinning ? AppTheme.neonGreen : Colors.blue[800]!,
                      width: isWinning ? 3.0 : 1.5,
                    ),
                    boxShadow: isWinning
                        ? [
                            BoxShadow(
                              color: AppTheme.neonGreen.withOpacity(0.6),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    heightFactor: 0.85,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.bounceOut,
                      decoration: BoxDecoration(
                        color: discColor,
                        shape: BoxShape.circle,
                        boxShadow: cell != 0
                            ? [
                                BoxShadow(
                                  color: discColor.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : [],
                      ),
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

  @override
  void dispose() {
    try {
      _provider.removeListener(_onProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final isMyTurn = _provider.isMyTurn;
    if (_provider.isNetworkGame &&
        isMyTurn &&
        !_wasMyTurn &&
        _provider.winner == 0) {
      HapticFeedback.lightImpact();
    }
    _wasMyTurn = isMyTurn;
  }
}

class _PulsingTurnIndicator extends StatefulWidget {
  final String text;
  final Color color;
  final bool pulse;

  const _PulsingTurnIndicator({
    required this.text,
    required this.color,
    required this.pulse,
  });

  @override
  State<_PulsingTurnIndicator> createState() => _PulsingTurnIndicatorState();
}

class _PulsingTurnIndicatorState extends State<_PulsingTurnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingTurnIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final glow = _animation.value;
        final scale = widget.pulse ? 1.0 + (0.04 * glow) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.06 + 0.08 * glow),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.color.withOpacity(0.3 + 0.7 * glow),
                width: 1.5 + 1.0 * glow,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.1 + 0.4 * glow),
                  blurRadius: 8 + 12 * glow,
                  spreadRadius: 0.5 + 1.5 * glow,
                ),
              ],
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: widget.color.withOpacity(0.6 * glow),
                    blurRadius: 6 * glow,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
