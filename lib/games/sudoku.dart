import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sudoku_provider.dart';
import '../../services/network_manager.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_shell.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/lottie_loader.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late NetworkManager _netManager;
  late SudokuProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _netManager = Provider.of<NetworkManager>(context, listen: false);
      _provider = Provider.of<SudokuProvider>(context, listen: false);

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isNetwork = args?['network'] ?? false;

      if (isNetwork) {
        _netManager.onMessageReceived = (packet) {
          if (packet['type'] == 'sudoku_setup') {
            final puzzle = List<int>.from(packet['data']['puzzle']);
            final solution = List<int>.from(packet['data']['solution']);
            _provider.setupNetworkGame(puzzle, solution);
          } else if (packet['type'] == 'sudoku_input') {
            final idx = packet['data']['index'] as int;
            final val = packet['data']['value'] as int;
            final isNote = packet['data']['isNote'] as bool;
            _provider.syncNetworkInput(idx, val, isNote);
          } else if (packet['type'] == 'sudoku_delete') {
            final idx = packet['data']['index'] as int;
            _provider.syncNetworkDelete(idx);
          } else if (packet['type'] == 'sudoku_reset') {
            _provider.generateNewGame(difficulty: _provider.difficulty);
          }
        };

        if (_netManager.role == NetworkRole.host) {
          _generateAndSyncNetworkGame();
        }
      } else {
        _provider.generateNewGame(difficulty: 'Easy');
      }
    });
  }

  Future<void> _generateAndSyncNetworkGame() async {
    await _provider.generateNewGame(difficulty: 'Easy');
    _netManager.sendMessage('sudoku_setup', {
      'puzzle': _provider.puzzle,
      'solution': _provider.solution,
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SudokuProvider>(context);
    final netManager = Provider.of<NetworkManager>(context);
    final isNetwork = netManager.isConnected;

    Widget statusWidget;
    if (provider.isLoading) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonCyan.withOpacity(0.4),
        borderRadius: 20,
        child: const Text(
          'Generating board in background...',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (provider.isWinner) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonGreen,
        borderRadius: 20,
        child: const Text(
          'SUDOKU SOLVED!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    } else {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonGreen.withOpacity(0.4),
        borderRadius: 20,
        child: Text(
          'Difficulty: ${provider.difficulty}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return GameShell(
      title: 'Sudoku',
      rules:
          'Fill the 9x9 board. Row, column, and 3x3 box must have numbers 1-9. Use notes for pencil marks. Red highlights show conflicts.',
      statusWidget: statusWidget,
      isWinner: provider.isWinner,
      winSubtitle: 'YOU SOLVED THE SUDOKU!',
      isInProgress:
          !provider.isWinner && !listEquals(provider.board, provider.puzzle),
      onReset:
          provider.isLoading ||
              (isNetwork &&
                  netManager.role != NetworkRole.host &&
                  provider.isWinner)
          ? null
          : () {
              if (isNetwork) {
                _generateAndSyncNetworkGame();
                netManager.sendMessage('sudoku_reset', {});
              } else {
                provider.generateNewGame(difficulty: provider.difficulty);
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
                // Difficulty Selectors (Local only) - styled as glass pills
                if (!isNetwork) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Easy', 'Medium', 'Hard'].map((diff) {
                      final active = provider.difficulty == diff;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: GestureDetector(
                          onTap: () =>
                              provider.generateNewGame(difficulty: diff),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            borderRadius: 24, // rounded-xl (24px) for controls
                            borderColor: active
                                ? AppTheme.neonGreen.withOpacity(0.6)
                                : Colors.white.withOpacity(0.08),
                            fillColor: active
                                ? AppTheme.neonGreen.withOpacity(0.15)
                                : Colors.white.withOpacity(0.02),
                            child: Text(
                              diff,
                              style: AppTheme.labelCaps.copyWith(
                                color: active
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 9x9 Grid Board wrapped in a frosted glass panel
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderColor: Colors.white.withOpacity(0.08),
                  borderRadius: 16, // rounded-lg (16px) for base cards
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 9,
                            ),
                        itemCount: 81,
                        itemBuilder: (context, index) {
                          final row = index ~/ 9;
                          final col = index % 9;
                          final val = provider.board[index];
                          final isStarting = provider.puzzle[index] != 0;
                          final isSelected = provider.selectedCell == index;
                          final hasConflict = provider.hasConflict(index);

                          // 3x3 thick borders styling
                          double borderLeft = (col % 3 == 0 && col > 0)
                              ? 1.5
                              : 0.5;
                          double borderTop = (row % 3 == 0 && row > 0)
                              ? 1.5
                              : 0.5;

                          return GestureDetector(
                            onTap: () => provider.selectCell(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.neonCyan.withOpacity(0.2)
                                    : isStarting
                                    ? Colors.white.withOpacity(0.02)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: col % 3 == 0 && col > 0
                                        ? Colors.white60
                                        : Colors.white12,
                                    width: borderLeft,
                                  ),
                                  top: BorderSide(
                                    color: row % 3 == 0 && row > 0
                                        ? Colors.white60
                                        : Colors.white12,
                                    width: borderTop,
                                  ),
                                  right: const BorderSide(
                                    color: Colors.white12,
                                    width: 0.5,
                                  ),
                                  bottom: const BorderSide(
                                    color: Colors.white12,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: hasConflict
                                    ? Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.neonPink,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: AppTheme.neonPink.withOpacity(
                                            0.12,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: _buildCellValue(
                                          val,
                                          provider.notes[index],
                                          isStarting,
                                        ),
                                      )
                                    : _buildCellValue(
                                        val,
                                        provider.notes[index],
                                        isStarting,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Controls & Pad wrapped in a glass container toolbar
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  borderRadius: 24, // rounded-xl (24px) for controls
                  borderColor: Colors.white.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Note toggle
                      IconButton(
                        icon: Icon(
                          provider.isNoteMode ? Icons.edit : Icons.edit_off,
                          color: provider.isNoteMode
                              ? AppTheme.neonCyan
                              : AppTheme.textSecondary,
                        ),
                        iconSize: 28,
                        onPressed: provider.toggleNoteMode,
                        tooltip: 'Toggle Note Mode',
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.neonPink,
                        ),
                        iconSize: 28,
                        onPressed: () {
                          final cellIdx = provider.selectedCell;
                          final success = provider.deleteNumber();
                          if (success && isNetwork) {
                            netManager.sendMessage('sudoku_delete', {
                              'index': cellIdx,
                            });
                          }
                        },
                        tooltip: 'Delete cell value',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Number Pad (1-9) using Frosted glass key buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(9, (i) {
                    final num = i + 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            final cellIdx = provider.selectedCell;
                            final isNote = provider.isNoteMode;
                            final success = provider.inputNumber(num);
                            if (success) {
                              AudioService.instance.gameMove();
                              if (isNetwork) {
                                netManager.sendMessage('sudoku_input', {
                                  'index': cellIdx,
                                  'value': num,
                                  'isNote': isNote,
                                });
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: GlassContainer(
                              borderRadius:
                                  24, // rounded-xl (24px) for controls
                              borderWidth: 1.0,
                              borderColor: AppTheme.neonGreen.withOpacity(0.4),
                              fillColor: Colors.white.withOpacity(0.02),
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(
                                  '$num',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
    );
  }

  Widget _buildCellValue(int val, List<int> cellNotes, bool isStarting) {
    if (val != 0) {
      return Text(
        '$val',
        style: TextStyle(
          fontSize: 18,
          fontWeight: isStarting ? FontWeight.w900 : FontWeight.bold,
          color: isStarting ? Colors.white : AppTheme.neonCyan,
          shadows: isStarting
              ? []
              : [
                  Shadow(
                    color: AppTheme.neonCyan.withOpacity(0.8),
                    blurRadius: 6,
                  ),
                ],
        ),
      );
    }

    if (cellNotes.isNotEmpty) {
      // Notes grid layout (3x3 tiny cells)
      return GridView.builder(
        padding: const EdgeInsets.all(2),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final noteVal = index + 1;
          final hasNote = cellNotes.contains(noteVal);
          return Center(
            child: Text(
              hasNote ? '$noteVal' : '',
              style: TextStyle(
                fontSize: 8,
                color: AppTheme.neonGreen.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
