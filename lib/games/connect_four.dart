import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connect_four_provider.dart';
import '../../services/network_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';
import '../../widgets/animated_neon_container.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  late NetworkManager _netManager;
  late ConnectFourProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<ConnectFourProvider>(context, listen: false);
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      _provider.setupGame(isNetwork: isNetwork, role: role);

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
          final iWon = (provider.myRole == 'host' && provider.winner == 1) ||
                       (provider.myRole == 'client' && provider.winner == 2);
          winnerText = iWon ? "YOU WIN!" : "OPPONENT WINS!";
        } else {
          winnerText = provider.winner == 1 ? "PLAYER 1 WINS!" : "PLAYER 2 WINS!";
        }
      }
      statusWidget = AnimatedNeonContainer(
        color: provider.winner == 3 ? Colors.grey : AppTheme.neonGreen,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(winnerText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      );
    } else {
      String turnText;
      final isMyTurn = provider.isMyTurn;
      if (provider.isNetworkGame) {
        turnText = isMyTurn ? "YOUR TURN" : "OPPONENT'S TURN";
      } else {
        turnText = provider.isPlayer1Turn ? "PLAYER 1'S TURN (CYAN)" : "PLAYER 2'S TURN (VIOLET)";
      }

      statusWidget = AnimatedNeonContainer(
        color: provider.isPlayer1Turn ? AppTheme.neonCyan : AppTheme.neonViolet,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(turnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }

    return GameShell(
      title: 'Connect Four',
      rules: 'Select a column to drop a chip. First to align 4 chips in a row (horizontally, vertically, or diagonally) wins.',
      statusWidget: statusWidget,
      onReset: provider.isNetworkGame && provider.myRole != 'host'
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
                color: provider.myRole == 'host' ? AppTheme.neonCyan : AppTheme.neonViolet,
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
                      ? (provider.isPlayer1Turn ? AppTheme.neonCyan : AppTheme.neonViolet)
                      : Colors.white24,
                  onPressed: () {
                    if (provider.isMyTurn && provider.winner == 0) {
                      final success = provider.dropDisc(col);
                      if (success && provider.isNetworkGame) {
                        netManager.sendMessage('c4_drop', {'column': col});
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
              border: Border.all(color: Colors.blue[600]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[900]!.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
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
                    boxShadow: isWinning ? [
                      BoxShadow(
                        color: AppTheme.neonGreen.withOpacity(0.6),
                        blurRadius: 10,
                      )
                    ] : [],
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
                        boxShadow: cell != 0 ? [
                          BoxShadow(
                            color: discColor.withOpacity(0.5),
                            blurRadius: 6,
                          )
                        ] : [],
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
}
