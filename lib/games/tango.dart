import 'package:flutter/material.dart';
import 'package:lazy_games/providers/tango_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:provider/provider.dart';

class TangoScreen extends StatefulWidget {
  const TangoScreen({super.key});

  @override
  State<TangoScreen> createState() => _TangoScreenState();
}

class _TangoScreenState extends State<TangoScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<TangoProvider>(context, listen: false)
            .newGame(difficulty: 'Easy');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TangoProvider>(context);

    Widget statusWidget;
    if (provider.isWinner) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonGreen,
        borderRadius: 20,
        child: const Text(
          'TANGO SOLVED! ☀️🌙',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    } else {
      final size = provider.gridSize;
      final half = size ~/ 2;
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonOrange.withOpacity(0.4),
        borderRadius: 20,
        child: Text(
          'Each row & col: $half ☀️ + $half 🌙  |  No 3 in a row',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }

    return GameShell(
      title: 'Tango',
      rules:
          'Fill every cell with either ☀️ Sun or 🌙 Moon.\n'
          '• No 3 identical symbols in a row or column.\n'
          '• Each row and column must have equal numbers of suns and moons.\n'
          'Tap a cell to cycle: empty → ☀️ → 🌙 → empty.\n'
          'Red cells indicate rule violations.',
      statusWidget: statusWidget,
      isWinner: provider.isWinner,
      winSubtitle: 'TANGO SOLVED!',
      isInProgress: provider.board.any((v) => v != tangoEmpty),
      onReset: () => provider.newGame(difficulty: provider.difficulty),
      child: Column(
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
                  onTap: () => provider.newGame(difficulty: diff),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    borderRadius: 24,
                    borderColor: active
                        ? AppTheme.neonOrange.withOpacity(0.6)
                        : Colors.white.withOpacity(0.08),
                    fillColor: active
                        ? AppTheme.neonOrange.withOpacity(0.15)
                        : Colors.white.withOpacity(0.02),
                    child: Text(
                      diff,
                      style: AppTheme.labelCaps.copyWith(
                        color: active ? Colors.white : AppTheme.textSecondary,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Grid
          GlassContainer(
            padding: const EdgeInsets.all(10),
            borderColor: AppTheme.neonOrange.withOpacity(0.2),
            borderRadius: 16,
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: provider.gridSize,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: provider.gridSize * provider.gridSize,
                itemBuilder: (context, index) {
                  final val = provider.board[index];
                  final isGiven = provider.puzzle.givens.containsKey(index);
                  final hasError = provider.hasCellError(index);

                  Color bgColor;
                  Color borderColor;
                  if (hasError) {
                    bgColor = AppTheme.neonPink.withOpacity(0.15);
                    borderColor = AppTheme.neonPink;
                  } else if (isGiven) {
                    bgColor = Colors.white.withOpacity(0.1);
                    borderColor = Colors.white.withOpacity(0.4);
                  } else if (val == tangoSun) {
                    bgColor = const Color(0xFFFFD700).withOpacity(0.12);
                    borderColor = const Color(0xFFFFD700).withOpacity(0.5);
                  } else if (val == tangoMoon) {
                    bgColor = AppTheme.neonViolet.withOpacity(0.12);
                    borderColor = AppTheme.neonViolet.withOpacity(0.5);
                  } else {
                    bgColor = Colors.white.withOpacity(0.03);
                    borderColor = Colors.white.withOpacity(0.1);
                  }

                  return GestureDetector(
                    onTap: () {
                      provider.tapCell(index);
                      AudioService.instance.gameMove();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(
                          provider.gridSize <= 4 ? 12 : 8,
                        ),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: _buildCellContent(val, isGiven, provider.gridSize),
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

  Widget _buildCellContent(int val, bool isGiven, int gridSize) {
    final fontSize = gridSize <= 4 ? 28.0 : 20.0;
    if (val == tangoSun) {
      return Text(
        '☀️',
        style: TextStyle(fontSize: fontSize),
      );
    } else if (val == tangoMoon) {
      return Text(
        '🌙',
        style: TextStyle(fontSize: fontSize),
      );
    }
    return const SizedBox.shrink();
  }
}
