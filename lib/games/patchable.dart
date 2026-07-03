import 'package:flutter/material.dart';
import 'package:lazy_games/providers/patchable_provider.dart';
import 'package:lazy_games/services/audio_service.dart';
import 'package:lazy_games/theme/app_theme.dart';
import 'package:lazy_games/widgets/game_shell.dart';
import 'package:lazy_games/widgets/glass_container.dart';
import 'package:provider/provider.dart';

// 8 distinct piece colors
const _pieceColors = [
  Color(0xFF00BFFF), // cyan
  Color(0xFFFF7043), // orange
  Color(0xFF66BB6A), // green
  Color(0xFFAB47BC), // violet
  Color(0xFFFFD700), // yellow
  Color(0xFFEF5350), // red
  Color(0xFF26C6DA), // teal
  Color(0xFFFF80AB), // pink
];

class PatchableScreen extends StatefulWidget {
  const PatchableScreen({super.key});

  @override
  State<PatchableScreen> createState() => _PatchableScreenState();
}

class _PatchableScreenState extends State<PatchableScreen> {
  bool _initialized = false;
  /// The cell index the user is hovering over during drag.
  int? _hoverCell;
  /// Whether the current hover is a valid placement.
  bool _hoverValid = false;

  final GlobalKey _gridKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<PatchableProvider>(context, listen: false)
            .newGame(difficulty: 'Easy');
      });
    }
  }

  int? _offsetToCell(Offset globalPos, PatchableProvider provider) {
    final RenderBox? box =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPos);
    final s = box.size;
    final cellW = s.width / provider.gridSize;
    final cellH = s.height / provider.gridSize;
    final col = (local.dx / cellW).floor();
    final row = (local.dy / cellH).floor();
    if (col < 0 || col >= provider.gridSize) return null;
    if (row < 0 || row >= provider.gridSize) return null;
    return row * provider.gridSize + col;
  }

  bool _canPlace(PatchableProvider provider, int row, int col) {
    final piece = provider.selectedPiece;
    if (piece == null) return false;
    for (final c in piece.cells) {
      final r2 = row + c[0];
      final c2 = col + c[1];
      if (r2 < 0 || r2 >= provider.gridSize) return false;
      if (c2 < 0 || c2 >= provider.gridSize) return false;
      if (provider.board[r2 * provider.gridSize + c2] != -1) return false;
    }
    return true;
  }

  Set<int> _getHoverCells(PatchableProvider provider, int originCell) {
    final piece = provider.selectedPiece;
    if (piece == null) return {};
    final row = originCell ~/ provider.gridSize;
    final col = originCell % provider.gridSize;
    final cells = <int>{};
    for (final c in piece.cells) {
      final r2 = row + c[0];
      final c2 = col + c[1];
      if (r2 >= 0 && r2 < provider.gridSize && c2 >= 0 && c2 < provider.gridSize) {
        cells.add(r2 * provider.gridSize + c2);
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatchableProvider>(context);

    Widget statusWidget;
    if (provider.isWinner) {
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonGreen,
        borderRadius: 20,
        child: const Text(
          'BOARD FILLED! 🧩',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    } else {
      final remaining = provider.board.where((v) => v == -1).length;
      statusWidget = GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderColor: AppTheme.neonViolet.withOpacity(0.4),
        borderRadius: 20,
        child: Text(
          '${provider.availablePieces.length} pieces left  |  $remaining cells empty',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }

    // Which hover cells to highlight
    final hoverCells = (_hoverCell != null && provider.selectedPiece != null)
        ? _getHoverCells(provider, _hoverCell!)
        : <int>{};

    return GameShell(
      title: 'Patchable',
      rules:
          'Drag pieces from the palette and drop them onto the grid to fill it completely. '
          'Tap a placed piece on the grid to remove it. '
          'All cells must be covered to win.',
      statusWidget: statusWidget,
      isWinner: provider.isWinner,
      winSubtitle: 'BOARD FILLED!',
      isInProgress: provider.placed.isNotEmpty,
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
                      horizontal: 16, vertical: 8,
                    ),
                    borderRadius: 24,
                    borderColor: active
                        ? AppTheme.neonViolet.withOpacity(0.6)
                        : Colors.white.withOpacity(0.08),
                    fillColor: active
                        ? AppTheme.neonViolet.withOpacity(0.15)
                        : Colors.white.withOpacity(0.02),
                    child: Text(
                      diff,
                      style: AppTheme.labelCaps.copyWith(
                        color: active ? Colors.white : AppTheme.textSecondary,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Game area: grid + palette
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid (takes most of the width)
              Expanded(
                flex: 3,
                child: DragTarget<PatchPiece>(
                  onWillAcceptWithDetails: (details) {
                    provider.selectPiece(details.data);
                    return true;
                  },
                  onAcceptWithDetails: (details) {
                    if (_hoverCell != null) {
                      final row = _hoverCell! ~/ provider.gridSize;
                      final col = _hoverCell! % provider.gridSize;
                      final placed = provider.placePiece(row, col);
                      if (placed) AudioService.instance.gameMove();
                    }
                    setState(() => _hoverCell = null);
                  },
                  onLeave: (_) => setState(() {
                    _hoverCell = null;
                    _hoverValid = false;
                  }),
                  builder: (context, candidateData, rejectedData) {
                    return GlassContainer(
                      padding: const EdgeInsets.all(8),
                      borderColor: AppTheme.neonViolet.withOpacity(0.2),
                      borderRadius: 16,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: MouseRegion(
                          onHover: (event) {
                            if (provider.selectedPiece == null) return;
                            final cell = _offsetToCell(
                              event.position,
                              provider,
                            );
                            if (cell != _hoverCell) {
                              setState(() {
                                _hoverCell = cell;
                                if (cell != null) {
                                  final row = cell ~/ provider.gridSize;
                                  final col = cell % provider.gridSize;
                                  _hoverValid = _canPlace(provider, row, col);
                                }
                              });
                            }
                          },
                          onExit: (_) => setState(() => _hoverCell = null),
                          child: Listener(
                            onPointerMove: (event) {
                              if (provider.selectedPiece == null) return;
                              final cell = _offsetToCell(
                                event.position,
                                provider,
                              );
                              if (cell != _hoverCell) {
                                setState(() {
                                  _hoverCell = cell;
                                  if (cell != null) {
                                    final row = cell ~/ provider.gridSize;
                                    final col = cell % provider.gridSize;
                                    _hoverValid = _canPlace(provider, row, col);
                                  }
                                });
                              }
                            },
                            child: GridView.builder(
                              key: _gridKey,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: provider.gridSize,
                                mainAxisSpacing: 2,
                                crossAxisSpacing: 2,
                              ),
                              itemCount: provider.gridSize * provider.gridSize,
                              itemBuilder: (context, index) {
                                final colorIdx = provider.board[index];
                                final isHover = hoverCells.contains(index);
                                final row = index ~/ provider.gridSize;
                                final col = index % provider.gridSize;

                                Color cellColor;
                                Color borderColor;
                                if (isHover) {
                                  final piece = provider.selectedPiece;
                                  final pColor = piece != null
                                      ? _pieceColors[piece.colorIndex % _pieceColors.length]
                                      : AppTheme.neonCyan;
                                  cellColor = _hoverValid
                                      ? pColor.withOpacity(0.45)
                                      : AppTheme.neonPink.withOpacity(0.3);
                                  borderColor = _hoverValid
                                      ? pColor
                                      : AppTheme.neonPink;
                                } else if (colorIdx >= 0) {
                                  final c =
                                      _pieceColors[colorIdx % _pieceColors.length];
                                  cellColor = c.withOpacity(0.3);
                                  borderColor = c.withOpacity(0.7);
                                } else {
                                  cellColor = Colors.white.withOpacity(0.04);
                                  borderColor = Colors.white.withOpacity(0.1);
                                }

                                return GestureDetector(
                                  onTap: () {
                                    if (colorIdx >= 0) {
                                      // Remove the piece on tap
                                      provider.removePieceAt(row, col);
                                      AudioService.instance.gameMove();
                                    } else if (provider.selectedPiece != null) {
                                      final placed = provider.placePiece(row, col);
                                      if (placed) AudioService.instance.gameMove();
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Piece palette
              Expanded(
                flex: 1,
                child: GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderColor: AppTheme.neonViolet.withOpacity(0.15),
                  borderRadius: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PIECES',
                        style: AppTheme.labelCaps.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...provider.availablePieces.map((piece) {
                        final isSelected =
                            provider.selectedPiece?.id == piece.id;
                        final pieceColor = _pieceColors[
                            piece.colorIndex % _pieceColors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Draggable<PatchPiece>(
                            data: piece,
                            feedback: _buildPieceMini(piece, pieceColor, scale: 1.4),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildPieceMini(piece, pieceColor),
                            ),
                            onDragStarted: () => provider.selectPiece(piece),
                            onDragEnd: (_) {
                              setState(() => _hoverCell = null);
                            },
                            child: GestureDetector(
                              onTap: () => provider.selectPiece(piece),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? pieceColor.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? pieceColor
                                        : pieceColor.withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: _buildPieceMini(piece, pieceColor),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.selectedPiece != null)
            Text(
              'Tap a grid cell to place · Tap a placed piece to remove',
              style: AppTheme.bodyMd.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildPieceMini(PatchPiece piece, Color color, {double scale = 1.0}) {
    const cellSize = 10.0;
    final w = piece.cols * cellSize * scale;
    final h = piece.rows * cellSize * scale;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _PiecePainter(piece: piece, color: color, cellSize: cellSize * scale),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final PatchPiece piece;
  final Color color;
  final double cellSize;

  const _PiecePainter({
    required this.piece,
    required this.color,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.8);
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final c in piece.cells) {
      final rect = Rect.fromLTWH(
        c[1] * cellSize,
        c[0] * cellSize,
        cellSize - 1,
        cellSize - 1,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.piece != piece || old.color != color;
}
