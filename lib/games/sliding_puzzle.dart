import 'package:flutter/material.dart';
import 'package:lazy_games/providers/sliding_puzzle_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/lottie_loader.dart';
import 'package:provider/provider.dart';

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key});

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  late NetworkManager _netManager;
  late SlidingPuzzleProvider _provider;
  bool _netInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<SlidingPuzzleProvider>(context, listen: false);
      _netInitialized = true;

      _provider.setupGame();

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;
      final role = _netManager.role == NetworkRole.host ? 'host' : 'client';

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'sp_setup') {
            final layout = List<int>.from(packet['data']['layout']);
            _provider.setupNetworkPuzzle(layout);
          } else if (packet['type'] == 'sp_won') {
            _provider.markOpponentWon();
          } else if (packet['type'] == 'sp_reset') {
            _generateAndSyncNetworkGame();
          }
        };

        if (role == 'host') {
          _generateAndSyncNetworkGame();
        }
      } else {
        _provider.startPuzzle();
      }
    });
  }

  void _generateAndSyncNetworkGame() async {
    await _provider.startPuzzle();
    if (!mounted) return;
    _netManager.sendMessage('sp_setup', {'layout': _provider.board});
  }

  @override
  void dispose() {
    if (_netInitialized) _netManager.onMessageReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SlidingPuzzleProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    Widget statusWidget;
    if (provider.isWon) {
      statusWidget = AnimatedNeonContainer(
        color: AppTheme.neonGreen,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonGreen),
        child: const Text(
          'YOU SOLVED IT!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    } else if (provider.isOpponentWon) {
      statusWidget = AnimatedNeonContainer(
        color: AppTheme.neonPink,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonPink),
        child: const Text(
          'OPPONENT WON THE RACE!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    } else {
      statusWidget = Text(
        'Moves: ${provider.moves}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppTheme.textSecondary,
        ),
      );
    }

    return GameShell(
      title: 'Sliding Puzzle',
      rules:
          'Tap a tile adjacent to the empty cell to slide it. Re-arrange all numbers from 1 to 15 sequentially from top-left to bottom-right.',
      statusWidget: statusWidget,
      isWinner: provider.isWon,
      winSubtitle: 'YOU SOLVED IT!',
      isInProgress:
          (!provider.isWon && !provider.isOpponentWon) && provider.moves > 0,
      onReset:
          netManager.isConnected &&
              netManager.role != NetworkRole.host &&
              (provider.isWon || provider.isOpponentWon)
          ? null
          : () {
              if (netManager.isConnected) {
                if (netManager.role == NetworkRole.host) {
                  _generateAndSyncNetworkGame();
                  netManager.sendMessage('sp_reset', {});
                } else {
                  netManager.sendMessage('sp_reset', {});
                }
              } else {
                provider.startPuzzle();
              }
            },
      child: provider.isLoading
          ? const Center(child: LottieLoader(size: 220))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.board.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: 16,
                        itemBuilder: (context, index) {
                          final tileVal = provider.board[index];

                          if (tileVal == 0) {
                            return const SizedBox.shrink(); // Empty slot
                          }

                          // Check if in correct final spot to give helpful visual hint
                          final isCorrect = tileVal == index + 1;
                          final neonColor = isCorrect
                              ? AppTheme.neonGreen
                              : AppTheme.neonOrange;

                          return GestureDetector(
                            onTap: () {
                              final moved = provider.moveTile(index);
                              if (moved) {
                                AudioService.instance.tileSlide();
                                if (provider.isWon && netManager.isConnected) {
                                  netManager.sendMessage('sp_won', {});
                                }
                              }
                            },
                            child: AnimatedNeonContainer(
                              color: neonColor,
                              borderWidth: 1.5,
                              borderRadius: 12,
                              alignment: Alignment.center,
                              child: Text(
                                '$tileVal',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect
                                      ? AppTheme.neonGreen
                                      : Colors.white,
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
