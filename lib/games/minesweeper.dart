import 'package:flutter/material.dart';
import 'package:lazy_games/providers/minesweeper_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/services/network_manager.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/lottie_loader.dart';
import 'package:provider/provider.dart';

class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key});

  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  late NetworkManager _netManager;
  late MinesweeperProvider _provider;
  bool _tapToFlag = false; // Mobile-friendly toggle
  bool _netInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<MinesweeperProvider>(context, listen: false);
      _netInitialized = true;

      _provider.setupGame();

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'ms_setup') {
            final flatGrid = List<int>.from(packet['data']['grid']);
            _provider.setupNetworkBoard(flatGrid);
          } else if (packet['type'] == 'ms_reveal') {
            final idx = packet['data']['index'] as int;
            _provider.revealCell(idx);
          } else if (packet['type'] == 'ms_flag') {
            final idx = packet['data']['index'] as int;
            _provider.toggleFlag(idx);
          } else if (packet['type'] == 'ms_reset') {
            _provider.setupGame();
          }
        };
      }
    });
  }

  void _onCellTap(int index) {
    if (_provider.isGameOver || _provider.isWon) return;

    if (_tapToFlag) {
      _provider.toggleFlag(index);
      if (_netManager.isConnected) {
        _netManager.sendMessage('ms_flag', {'index': index});
      }
    } else {
      final wasFirstTap = !_provider.firstTapDone;
      _provider.revealCell(index);

      // Sound feedback
      if (_provider.isGameOver) {
        AudioService.instance.mineExplode();
      } else {
        AudioService.instance.gameMove();
      }

      if (_netManager.isConnected) {
        if (wasFirstTap) {
          // Wait briefly for isolate board generation to complete, then sync it
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!mounted) return;
            _netManager.sendMessage('ms_setup', {
              'grid': _provider.getFlatGrid(),
            });
          });
        } else {
          _netManager.sendMessage('ms_reveal', {'index': index});
        }
      }
    }
  }

  @override
  void dispose() {
    if (_netInitialized) _netManager.onMessageReceived = null;
    super.dispose();
  }

  void _onCellLongPress(int index) {
    if (_provider.isGameOver || _provider.isWon) return;
    _provider.toggleFlag(index);
    if (_netManager.isConnected) {
      _netManager.sendMessage('ms_flag', {'index': index});
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MinesweeperProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);

    Widget statusWidget;
    if (provider.isGameOver) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonPink),
        child: const Text(
          'BOOM! GAME OVER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    } else if (provider.isWon) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: AppTheme.neonBorderDecoration(color: AppTheme.neonGreen),
        child: const Text(
          'MINES CLEARED!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    } else {
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag, color: AppTheme.neonGreen, size: 20),
          const SizedBox(width: 6),
          Text(
            'Flags: ${provider.flaggedCount} / ${provider.numMines}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    return GameShell(
      title: 'Minesweeper',
      rules:
          'Tap a cell to reveal it. Numbers represent surrounding mines. Long press a cell (or toggle Flag Mode below) to flag suspected mines. Clear all safe cells to win.',
      statusWidget: statusWidget,
      isWinner: provider.isWon,
      winSubtitle: 'YOU CLEARED THE BOARD!',
      onReset: () {
        provider.setupGame();
        if (netManager.isConnected) {
          netManager.sendMessage('ms_reset', {});
        }
      },
      child: provider.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: LottieLoader(size: 220),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 10x10 Grid
                if (provider.grid.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 10,
                              crossAxisSpacing: 1.5,
                              mainAxisSpacing: 1.5,
                            ),
                        itemCount: 100,
                        itemBuilder: (context, index) {
                          final cell = provider.grid[index];
                          return GestureDetector(
                            onTap: () => _onCellTap(index),
                            onLongPress: () => _onCellLongPress(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: _getCellDecoration(cell),
                              alignment: Alignment.center,
                              child: _buildCellContent(cell),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Flag Mode Toggle for mobile convenience
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 18,
                            color: _tapToFlag
                                ? AppTheme.neonGreen
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          const Text('Flag Mode'),
                        ],
                      ),
                      selected: _tapToFlag,
                      selectedColor: AppTheme.neonGreen.withOpacity(0.15),
                      checkmarkColor: AppTheme.neonGreen,
                      onSelected: (val) {
                        setState(() {
                          _tapToFlag = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  BoxDecoration _getCellDecoration(MinesweeperCell cell) {
    if (cell.isRevealed) {
      if (cell.isMine) {
        return const BoxDecoration(
          color: AppTheme.neonPink,
          borderRadius: BorderRadius.zero,
        );
      }
      return BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.zero,
      );
    }

    return BoxDecoration(
      color: AppTheme.cardBackground,
      border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
    );
  }

  Widget _buildCellContent(MinesweeperCell cell) {
    if (!cell.isRevealed) {
      if (cell.isFlagged) {
        return const Icon(Icons.flag, color: AppTheme.neonGreen, size: 18);
      }
      return const SizedBox.shrink();
    }

    if (cell.isMine) {
      return const Icon(Icons.dangerous, color: Colors.white, size: 18);
    }

    if (cell.neighborMines > 0) {
      Color numColor = AppTheme.neonCyan;
      if (cell.neighborMines == 2) numColor = AppTheme.neonGreen;
      if (cell.neighborMines == 3) numColor = AppTheme.neonPink;
      if (cell.neighborMines >= 4) numColor = AppTheme.neonViolet;

      return Text(
        '${cell.neighborMines}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: numColor,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
