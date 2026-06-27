import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/checkers_provider.dart';
import '../../services/network_manager.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';

class CheckersScreen extends StatefulWidget {
  const CheckersScreen({super.key});

  @override
  State<CheckersScreen> createState() => _CheckersScreenState();
}

class _CheckersScreenState extends State<CheckersScreen> {
  late NetworkManager _netManager;
  late CheckersProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<CheckersProvider>(context, listen: false);
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      _provider.setupGame(isNetwork: isNetwork, role: role);

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'checkers_move') {
            final from = packet['data']['from'] as int;
            final to = packet['data']['to'] as int;
            _provider.handleNetworkMove(from, to);
          } else if (packet['type'] == 'checkers_reset') {
            _provider.setupGame(isNetwork: true, role: role);
          }
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CheckersProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    Widget statusWidget;
    if (provider.winner != 0) {
      String winnerText;
      if (provider.isNetworkGame) {
        final iWon = (provider.myRole == 'host' && provider.winner == 1) ||
                     (provider.myRole == 'client' && provider.winner == 2);
        winnerText = iWon ? "YOU WIN!" : "OPPONENT WINS!";
      } else {
        winnerText = provider.winner == 1 ? "PINK WINS!" : "CYAN WINS!";
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
        turnText = provider.isPlayer1Turn ? "PLAYER 1'S TURN (PINK)" : "PLAYER 2'S TURN (CYAN)";
      }

      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(
          color: provider.isPlayer1Turn ? AppTheme.neonPink : AppTheme.neonCyan,
        ),
        child: Text(turnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }

    final iWon = (provider.myRole == 'host' && provider.winner == 1) ||
                 (provider.myRole == 'client' && provider.winner == 2);
    final isWinner = provider.winner != 0 && (!provider.isNetworkGame || iWon);
    final winSubtitle = provider.isNetworkGame
        ? 'YOU WON!'
        : (provider.winner == 1 ? 'PINK WINS!' : 'CYAN WINS!');

    return GameShell(
      title: 'Checkers',
      rules: 'Select your pieces and move diagonally forward on dark squares. Capture opponent pieces by jumping over them. Reach the end to get crowned King!',
      statusWidget: statusWidget,
      isWinner: isWinner,
      winSubtitle: winSubtitle,
      isInProgress: provider.winner == 0,
      onReset: provider.isNetworkGame && provider.myRole != 'host' && provider.winner != 0
          ? null
          : () {
              if (provider.isNetworkGame) {
                _provider.setupGame(isNetwork: true, role: provider.myRole);
                netManager.sendMessage('checkers_reset', {});
              } else {
                _provider.setupGame(isNetwork: false, role: 'host');
              }
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isNetworkGame) ...[
            Text(
              "Your Color: ${provider.myRole == 'host' ? 'Pink' : 'Cyan'}",
              style: TextStyle(
                color: provider.myRole == 'host' ? AppTheme.neonPink : AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 8x8 Checkers Board Frame
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: 64,
                itemBuilder: (context, index) {
                  final row = index ~/ 8;
                  final col = index % 8;
                  final isDarkSquare = (row + col) % 2 != 0;
                  final piece = provider.board[index];
                  final isSelected = provider.selectedPiece == index;
                  final isValidMove = provider.validMoves.contains(index);

                  Color squareColor = isDarkSquare ? Colors.black45 : Colors.white.withOpacity(0.04);
                  if (isValidMove) {
                    squareColor = AppTheme.neonGreen.withOpacity(0.15);
                  }

                  return GestureDetector(
                    onTap: () {
                      if (provider.isMyTurn && provider.winner == 0) {
                        if (isDarkSquare) {
                          if (isValidMove) {
                            final fromIdx = provider.selectedPiece;
                            final success = provider.makeMove(index);
                            if (success) {
                              AudioService.instance.gameMove();
                              if (provider.isNetworkGame) {
                                netManager.sendMessage('checkers_move', {
                                  'from': fromIdx,
                                  'to': index,
                                });
                              }
                            }
                          } else {
                            provider.selectPiece(index);
                          }
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: squareColor,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.neonGreen
                              : isValidMove
                                  ? AppTheme.neonGreen.withOpacity(0.5)
                                  : Colors.transparent,
                          width: (isSelected || isValidMove) ? 1.5 : 0,
                        ),
                      ),
                      child: Center(
                        child: _buildPiece(piece),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiece(int piece) {
    if (piece == 0) return const SizedBox.shrink();

    final isP1 = piece == 1 || piece == 2;
    final isKing = piece == 2 || piece == 4;
    final pieceColor = isP1 ? AppTheme.neonPink : AppTheme.neonCyan;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: pieceColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: pieceColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: pieceColor.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: isKing
          ? const Icon(
              Icons.star,
              color: Colors.amber,
              size: 14,
            )
          : null,
    );
  }
}
