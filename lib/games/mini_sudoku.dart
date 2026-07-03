import 'package:flutter/material.dart';
import 'package:lazy_games/providers/mini_sudoku_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:lazy_games/widgets/lottie_loader.dart';
import 'package:provider/provider.dart';

class MiniSudokuScreen extends StatefulWidget {
  const MiniSudokuScreen({super.key});

  @override
  State<MiniSudokuScreen> createState() => _MiniSudokuScreenState();
}

class _MiniSudokuScreenState extends State<MiniSudokuScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<MiniSudokuProvider>(
          context,
          listen: false,
        ).generateNewGame(difficulty: 'Easy');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MiniSudokuProvider>(context);

    Widget statusWidget;
    if (provider.isLoading) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonCyan.withOpacity(0.4),
        borderRadius: 20,
        child: const Text(
          'Generating puzzle...',
          style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
        ),
      );
    } else if (provider.isWinner) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonGreen,
        borderRadius: 20,
        child: const Text(
          'MINI ZUDOKU SOLVED! 🎉',
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return GameShell(
      title: 'Mini Zudoku',
      rules:
          'Fill the 4×4 grid so every row, column, and 2×2 box contains the numbers 1 to 4. '
          'Tap a cell, then tap a number to fill it. Use note mode to pencil in candidates. '
          'Red highlights mean a conflict exists.',
      statusWidget: statusWidget,
      isWinner: provider.isWinner,
      winSubtitle: 'MINI ZUDOKU SOLVED!',
      isInProgress: !provider.isWinner &&
          provider.board.any((v) => v != 0) &&
          !provider.board.every((v) => v == 0),
      onReset: provider.isLoading
          ? null
          : () => provider.generateNewGame(difficulty: provider.difficulty),
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
                // Difficulty selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['Easy', 'Medium', 'Hard'].map((diff) {
                    final active = provider.difficulty == diff;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: GestureDetector(
                        onTap: () => provider.generateNewGame(difficulty: diff),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          borderRadius: 24,
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
                const SizedBox(height: 20),

                // 4x4 Grid — larger cells than 9x9 Sudoku
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderColor: Colors.white.withOpacity(0.08),
                  borderRadius: 16,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemCount: 16,
                        itemBuilder: (context, index) {
                          final row = index ~/ 4;
                          final col = index % 4;
                          final val = provider.board[index];
                          final isStarting = provider.puzzle[index] != 0;
                          final isSelected = provider.selectedCell == index;
                          final hasConflict = provider.hasConflict(index);

                          // Thick border between 2x2 boxes
                          final borderLeft =
                              (col == 2) ? 2.5 : 0.5;
                          final borderTop =
                              (row == 2) ? 2.5 : 0.5;

                          return GestureDetector(
                            onTap: () => provider.selectCell(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.neonCyan.withOpacity(0.22)
                                    : isStarting
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: col == 2
                                        ? Colors.white70
                                        : Colors.white24,
                                    width: borderLeft,
                                  ),
                                  top: BorderSide(
                                    color: row == 2
                                        ? Colors.white70
                                        : Colors.white24,
                                    width: borderTop,
                                  ),
                                  right: const BorderSide(
                                    color: Colors.white24,
                                    width: 0.5,
                                  ),
                                  bottom: const BorderSide(
                                    color: Colors.white24,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: hasConflict
                                    ? Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppTheme.neonPink
                                              .withOpacity(0.15),
                                          border: Border.all(
                                            color: AppTheme.neonPink,
                                            width: 1.5,
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

                // Controls toolbar
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  borderRadius: 24,
                  borderColor: Colors.white.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
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
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.neonPink,
                        ),
                        iconSize: 28,
                        onPressed: provider.deleteNumber,
                        tooltip: 'Delete cell value',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Number pad (1–4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    final num = i + 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: InkWell(
                          onTap: () {
                            final success = provider.inputNumber(num);
                            if (success) AudioService.instance.gameMove();
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: GlassContainer(
                              borderRadius: 24,
                              borderWidth: 1.0,
                              borderColor: AppTheme.neonGreen.withOpacity(0.4),
                              fillColor: Colors.white.withOpacity(0.02),
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(
                                  '$num',
                                  style: const TextStyle(
                                    fontSize: 26,
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
          fontSize: 28,
          fontWeight: isStarting ? FontWeight.w900 : FontWeight.bold,
          color: isStarting ? Colors.white : AppTheme.neonCyan,
          shadows: isStarting
              ? []
              : [Shadow(color: AppTheme.neonCyan.withOpacity(0.8), blurRadius: 6)],
        ),
      );
    }
    if (cellNotes.isNotEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(2),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final noteVal = index + 1;
          final hasNote = cellNotes.contains(noteVal);
          return Center(
            child: Text(
              hasNote ? '$noteVal' : '',
              style: TextStyle(
                fontSize: 9,
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
