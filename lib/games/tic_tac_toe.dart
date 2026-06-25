import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tic_tac_toe_provider.dart';
import '../../services/network_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';
import '../../widgets/animated_neon_container.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  late NetworkManager _netManager;
  late TicTacToeProvider _provider;

  @override
  void initState() {
    super.initState();
    
    // Defer initialization to after context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<TicTacToeProvider>(context, listen: false);
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';
      
      _provider.setupGame(isNetwork: isNetwork, role: role);

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'ttt_move') {
            final idx = packet['data']['index'] as int;
            _provider.handleNetworkMove(idx);
          } else if (packet['type'] == 'ttt_reset') {
            _provider.resetBoard();
          }
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TicTacToeProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    // Dynamic Turn status text
    Widget statusWidget;
    if (provider.winner != null) {
      statusWidget = AnimatedNeonContainer(
        color: provider.winner == 'Draw' ? Colors.grey : AppTheme.neonGreen,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          provider.winner == 'Draw' ? "MATCH DRAW!" : "PLAYER ${provider.winner} WINS!",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      );
    } else {
      final isMyTurn = provider.isMyTurn;
      final currentSymbol = provider.isXTurn ? 'X' : 'O';
      final label = provider.isNetworkGame
          ? (isMyTurn ? "YOUR TURN ($currentSymbol)" : "OPPONENT'S TURN ($currentSymbol)")
          : "TURN: PLAYER $currentSymbol";

      statusWidget = AnimatedNeonContainer(
        color: provider.isXTurn ? AppTheme.neonCyan : AppTheme.neonViolet,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      );
    }

    return GameShell(
      title: 'Tic Tac Toe',
      rules: 'Take turns placing X or O. Get 3 in a row horizontally, vertically, or diagonally to win. Play locally or sync moves with a friend over the local network.',
      statusWidget: statusWidget,
      onReset: () {
        provider.resetBoard();
        if (provider.isNetworkGame) {
          netManager.sendMessage('ttt_reset', {});
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isNetworkGame) ...[
            Text(
              "Your Symbol: ${provider.mySymbol}",
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
          ],
          
          // 3x3 Grid
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final val = provider.board[index];
                final isWinningCell = provider.winningLine.contains(index);
                
                Color cellBorderColor = Colors.white24;
                if (isWinningCell) {
                  cellBorderColor = AppTheme.neonGreen;
                } else if (val == 'X') {
                  cellBorderColor = AppTheme.neonCyan.withOpacity(0.5);
                } else if (val == 'O') {
                  cellBorderColor = AppTheme.neonViolet.withOpacity(0.5);
                }

                return GestureDetector(
                  onTap: () {
                    if (provider.isMyTurn && provider.board[index] == '' && provider.winner == null) {
                      final success = provider.makeMove(index);
                      if (success && provider.isNetworkGame) {
                        netManager.sendMessage('ttt_move', {'index': index});
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isWinningCell 
                          ? AppTheme.neonGreen.withOpacity(0.15) 
                          : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cellBorderColor, width: 2),
                      boxShadow: isWinningCell ? [
                        BoxShadow(
                          color: AppTheme.neonGreen.withOpacity(0.3),
                          blurRadius: 12,
                        )
                      ] : [],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: val == ''
                            ? const SizedBox.shrink()
                            : CustomPaint(
                                size: const Size(50, 50),
                                painter: XOIconPainter(symbol: val),
                              ),
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

class XOIconPainter extends CustomPainter {
  final String symbol;

  XOIconPainter({required this.symbol});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    if (symbol == 'X') {
      paint.color = AppTheme.neonCyan;
      // Draw glow
      canvas.drawLine(
        Offset(w * 0.1, h * 0.1), Offset(w * 0.9, h * 0.9),
        Paint()
          ..color = AppTheme.neonCyan.withOpacity(0.3)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawLine(
        Offset(w * 0.9, h * 0.1), Offset(w * 0.1, h * 0.9),
        Paint()
          ..color = AppTheme.neonCyan.withOpacity(0.3)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      
      // Draw actual line
      canvas.drawLine(Offset(w * 0.1, h * 0.1), Offset(w * 0.9, h * 0.9), paint);
      canvas.drawLine(Offset(w * 0.9, h * 0.1), Offset(w * 0.1, h * 0.9), paint);
    } else {
      paint.color = AppTheme.neonViolet;
      // Draw glow
      canvas.drawCircle(
        Offset(w / 2, h / 2), w * 0.38,
        Paint()
          ..color = AppTheme.neonViolet.withOpacity(0.3)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      
      // Draw actual circle
      canvas.drawCircle(Offset(w / 2, h / 2), w * 0.38, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
