import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tic_tac_toe_provider.dart';
import '../../services/network_manager.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';
import '../../widgets/glass_container.dart';

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

    // Dynamic Turn status text (glassmorphic styling)
    Widget statusWidget;
    if (provider.winner != null) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: provider.winner == 'Draw' ? Colors.grey : AppTheme.neonGreen,
        borderRadius: 24, // rounded-xl (24px) for controls
        child: Text(
          provider.winner == 'Draw' ? "MATCH DRAW!" : "PLAYER ${provider.winner} WINS!",
          style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    } else {
      final isMyTurn = provider.isMyTurn;
      final currentSymbol = provider.isXTurn ? 'X' : 'O';
      final label = provider.isNetworkGame
          ? (isMyTurn ? "YOUR TURN ($currentSymbol)" : "OPPONENT'S TURN ($currentSymbol)")
          : "TURN: PLAYER $currentSymbol";

      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: provider.isXTurn ? AppTheme.neonCyan.withOpacity(0.5) : AppTheme.neonViolet.withOpacity(0.5),
        borderRadius: 24, // rounded-xl (24px) for controls
        child: Text(
          label,
          style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    }

    final isWinner = provider.winner != null &&
        provider.winner != 'Draw' &&
        (!provider.isNetworkGame || provider.winner == provider.mySymbol);
    final winSubtitle = provider.isNetworkGame
        ? 'YOU WON!'
        : 'PLAYER ${provider.winner} WINS!';

    return GameShell(
      title: 'Tic Tac Toe',
      rules: 'Take turns placing X or O. Get 3 in a row horizontally, vertically, or diagonally to win. Play locally or sync moves with a friend over the local network.',
      statusWidget: statusWidget,
      isWinner: isWinner,
      winSubtitle: winSubtitle,
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
              style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
          ],
          
          // 3x3 Grid Board wrapped in a large glass pane
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderColor: Colors.white.withOpacity(0.08),
            borderRadius: 16, // rounded-lg (16px) for base cards
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final val = provider.board[index];
                  final isWinningCell = provider.winningLine.contains(index);
                  
                  Color cellBorderColor = Colors.white.withOpacity(0.08);
                  if (isWinningCell) {
                    cellBorderColor = AppTheme.neonGreen.withOpacity(0.8);
                  } else if (val == 'X') {
                    cellBorderColor = AppTheme.neonCyan.withOpacity(0.4);
                  } else if (val == 'O') {
                    cellBorderColor = AppTheme.neonViolet.withOpacity(0.4);
                  }

                  return GestureDetector(
                    onTap: () {
                      if (provider.isMyTurn && provider.board[index] == '' && provider.winner == null) {
                        final success = provider.makeMove(index);
                        if (success) {
                          if (provider.winner == 'Draw') {
                            AudioService.instance.draw();
                          } else {
                            AudioService.instance.gameMove();
                          }
                          if (provider.isNetworkGame) {
                            netManager.sendMessage('ttt_move', {'index': index});
                          }
                        }
                      }
                    },
                    child: GlassContainer(
                      borderRadius: 16, // rounded-lg (16px) for cards
                      borderWidth: 1.5,
                      borderColor: cellBorderColor,
                      fillColor: isWinningCell
                          ? AppTheme.neonGreen.withOpacity(0.12)
                          : val == 'X'
                              ? AppTheme.neonCyan.withOpacity(0.04)
                              : val == 'O'
                                  ? AppTheme.neonViolet.withOpacity(0.04)
                                  : Colors.white.withOpacity(0.02),
                      boxShadow: isWinningCell ? [
                        BoxShadow(
                          color: AppTheme.neonGreen.withOpacity(0.25),
                          blurRadius: 12,
                        )
                      ] : [],
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: val == ''
                              ? const SizedBox.shrink()
                              : CustomPaint(
                                  size: const Size(54, 54),
                                  painter: XOIconPainter(symbol: val),
                                ),
                        ),
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
}

class XOIconPainter extends CustomPainter {
  final String symbol;

  XOIconPainter({required this.symbol});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    if (symbol == 'X') {
      paint.color = AppTheme.neonCyan;
      
      // Draw glow layers
      canvas.drawLine(
        Offset(w * 0.15, h * 0.15), Offset(w * 0.85, h * 0.85),
        Paint()
          ..color = AppTheme.neonCyan.withOpacity(0.35)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawLine(
        Offset(w * 0.85, h * 0.15), Offset(w * 0.15, h * 0.85),
        Paint()
          ..color = AppTheme.neonCyan.withOpacity(0.35)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      
      // Draw primary stroke
      canvas.drawLine(Offset(w * 0.15, h * 0.15), Offset(w * 0.85, h * 0.85), paint);
      canvas.drawLine(Offset(w * 0.85, h * 0.15), Offset(w * 0.15, h * 0.85), paint);
    } else {
      paint.color = AppTheme.neonViolet;
      
      // Draw glow layers
      canvas.drawCircle(
        Offset(w / 2, h / 2), w * 0.35,
        Paint()
          ..color = AppTheme.neonViolet.withOpacity(0.35)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      
      // Draw primary stroke
      canvas.drawCircle(Offset(w / 2, h / 2), w * 0.35, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
