import 'package:flutter/material.dart';
import 'package:lazy_games/providers/zip_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:provider/provider.dart';

class ZipScreen extends StatefulWidget {
  const ZipScreen({super.key});

  @override
  State<ZipScreen> createState() => _ZipScreenState();
}

class _ZipScreenState extends State<ZipScreen> {
  bool _initialized = false;
  // Key for the grid widget so we can hit-test local positions.
  final GlobalKey _gridKey = GlobalKey();
  String? _feedbackMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<ZipProvider>(context, listen: false)
            .newGame(difficulty: 'Easy');
      });
    }
  }

  // Convert a global drag offset to a cell index in the grid.
  int? _offsetToCell(Offset globalPos, ZipProvider provider) {
    final RenderBox? box =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPos);
    final size = box.size;
    final cellW = size.width / provider.gridSize;
    final cellH = size.height / provider.gridSize;
    final col = (local.dx / cellW).floor();
    final row = (local.dy / cellH).floor();
    if (col < 0 || col >= provider.gridSize) return null;
    if (row < 0 || row >= provider.gridSize) return null;
    return row * provider.gridSize + col;
  }

  void _updateFeedback(ZipProvider provider) {
    if (provider.path.isEmpty) {
      setState(() => _feedbackMessage = "Start drawing from '1'!");
      return;
    }

    final size = provider.gridSize;
    final total = size * size;
    final path = provider.path;
    final endpoints = provider.endpoints;

    // Check starting point
    if (path.first != endpoints.first) {
      setState(() => _feedbackMessage = "The path must start at '1'!");
      return;
    }

    // Check unvisited endpoints
    final unvisited = <int>[];
    for (int i = 0; i < endpoints.length; i++) {
      if (!path.contains(endpoints[i])) {
        unvisited.add(i + 1);
      }
    }
    if (unvisited.isNotEmpty) {
      setState(() => _feedbackMessage = "Visit all numbers! Missing: ${unvisited.join(', ')}");
      return;
    }

    // Check order of endpoints
    int lastIdx = -1;
    bool inOrder = true;
    for (final ep in endpoints) {
      final idx = path.indexOf(ep);
      if (idx != -1) {
        if (idx < lastIdx) {
          inOrder = false;
          break;
        }
        lastIdx = idx;
      }
    }
    if (!inOrder) {
      setState(() => _feedbackMessage = "Connect numbers in order: 1 ➔ 2 ➔ 3...");
      return;
    }

    // Check coverage
    if (path.length < total) {
      setState(() => _feedbackMessage = "All squares must be touched! Cover every cell.");
      return;
    }

    // Winner!
    setState(() => _feedbackMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ZipProvider>(context);

    Widget statusWidget;
    if (provider.isWinner) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonGreen,
        borderRadius: 20,
        child: const Text(
          'PATH COMPLETE! ✅',
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
        borderColor: AppTheme.neonCyan.withOpacity(0.4),
        borderRadius: 20,
        child: Text(
          'Cells covered: ${provider.path.length} / ${provider.gridSize * provider.gridSize}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return GameShell(
      title: 'Zip',
      rules:
          'Draw a continuous path starting from 1, visiting each numbered stop in order (1→2→3…), '
          'and covering EVERY cell in the grid. Drag to draw; backtrack by dragging over visited cells. '
          'Tap "Reset Path" to start over.',
      statusWidget: statusWidget,
      isWinner: provider.isWinner,
      winSubtitle: 'PATH COMPLETE!',
      isInProgress: provider.path.isNotEmpty && !provider.isWinner,
      onReset: () {
        provider.newGame(difficulty: provider.difficulty);
        setState(() => _feedbackMessage = null);
      },
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
                  onTap: () {
                    provider.newGame(difficulty: diff);
                    setState(() => _feedbackMessage = null);
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    borderRadius: 24,
                    borderColor: active
                        ? AppTheme.neonCyan.withOpacity(0.6)
                        : Colors.white.withOpacity(0.08),
                    fillColor: active
                        ? AppTheme.neonCyan.withOpacity(0.15)
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
          const SizedBox(height: 16),

          // Grid
          GlassContainer(
            padding: const EdgeInsets.all(10),
            borderColor: AppTheme.neonCyan.withOpacity(0.2),
            borderRadius: 16,
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onPanStart: (details) {
                  final cell = _offsetToCell(details.globalPosition, provider);
                  if (cell != null) {
                    setState(() => _feedbackMessage = null);
                    provider.startDraw(cell);
                    AudioService.instance.gameMove();
                  }
                },
                onPanUpdate: (details) {
                  final cell = _offsetToCell(details.globalPosition, provider);
                  if (cell != null) provider.continueDraw(cell);
                },
                onPanEnd: (_) {
                  provider.endDraw();
                  _updateFeedback(provider);
                },
                child: GridView.builder(
                  key: _gridKey,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: provider.gridSize,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: provider.gridSize * provider.gridSize,
                  itemBuilder: (context, index) {
                    final inPath = provider.path.contains(index);
                    final pathIdx = provider.path.indexOf(index);
                    final isHead = provider.path.isNotEmpty &&
                        provider.path.last == index;
                    final epNum = provider.endpointNumber(index);
                    final isEndpoint = epNum != null;

                    Color cellColor;
                    if (isHead && inPath) {
                      cellColor = AppTheme.neonCyan.withOpacity(0.8);
                    } else if (inPath) {
                      // Gradient along path: lighter for more recent
                      final ratio = pathIdx / provider.gridSize / provider.gridSize;
                      cellColor = AppTheme.neonCyan.withOpacity(
                        0.15 + ratio * 0.45,
                      );
                    } else {
                      cellColor = Colors.white.withOpacity(0.04);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(
                          provider.gridSize <= 4 ? 10 : 7,
                        ),
                        border: Border.all(
                          color: isEndpoint
                              ? AppTheme.neonCyan
                              : Colors.white.withOpacity(0.12),
                          width: isEndpoint ? 2 : 0.5,
                        ),
                        boxShadow: isHead
                            ? [
                                BoxShadow(
                                  color: AppTheme.neonCyan.withOpacity(0.6),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: isEndpoint
                          ? Text(
                              '$epNum',
                              style: TextStyle(
                                fontSize: provider.gridSize <= 4 ? 22 : 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color:
                                        AppTheme.neonCyan.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hint/Feedback message
          if (_feedbackMessage != null && !provider.isWinner) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withOpacity(0.08),
                border: Border.all(
                  color: AppTheme.neonPink.withOpacity(0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _feedbackMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Reset path button
          TextButton.icon(
            onPressed: () {
              provider.resetPath();
              setState(() => _feedbackMessage = null);
            },
            icon: const Icon(Icons.undo, color: AppTheme.neonPink),
            label: const Text(
              'Reset Path',
              style: TextStyle(color: AppTheme.neonPink),
            ),
          ),
        ],
      ),
    );
  }
}
