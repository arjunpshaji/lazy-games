import 'package:flutter/material.dart';
import 'package:lazy_games/theme/app_theme.dart';

class GameVisual extends StatelessWidget {
  final String gameId;
  final Color color;
  final double size;

  const GameVisual({
    super.key,
    required this.gameId,
    required this.color,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (gameId) {
      case 'tic_tac_toe':
        return _buildTicTacToe();
      case 'sudoku':
        return _buildSudoku();
      case '2048':
        return _build2048();
      case 'memory_match':
        return _buildMemoryMatch();
      case 'connect_four':
        return _buildConnectFour();
      case 'minesweeper':
        return _buildMinesweeper();
      case 'word_search':
        return _buildWordSearch();
      case 'sliding_puzzle':
        return _buildSlidingPuzzle();
      case 'checkers':
        return _buildCheckers();
      case 'mini_sudoku':
        return _buildMiniSudoku();
      case 'zip':
        return _buildZip();
      case 'tango':
        return _buildTango();
      case 'patchable':
        return _buildPatchable();
      default:
        return Icon(Icons.videogame_asset, color: color, size: size * 0.6);
    }
  }

  Widget _buildTicTacToe() {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Hashtag Grid lines
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(height: 2, color: color.withOpacity(0.3)),
                Container(height: 2, color: color.withOpacity(0.3)),
              ],
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(width: 2, color: color.withOpacity(0.3)),
                Container(width: 2, color: color.withOpacity(0.3)),
              ],
            ),
          ),
          // X and O symbols
          Positioned(
            left: size * 0.1,
            top: size * 0.1,
            child: Icon(
              Icons.close,
              color: AppTheme.neonPink,
              size: size * 0.35,
            ),
          ),
          Positioned(
            right: size * 0.1,
            bottom: size * 0.1,
            child: Icon(
              Icons.radio_button_unchecked,
              color: AppTheme.neonCyan,
              size: size * 0.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudoku() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sudokuCell('5', bold: true),
                _sudokuCell('3', bold: false),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sudokuCell('9', bold: false),
                _sudokuCell('7', bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sudokuCell(String val, {required bool bold}) {
    return Text(
      val,
      style: TextStyle(
        color: bold ? Colors.white : Colors.white70,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 12 : 10,
      ),
    );
  }

  Widget _build2048() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        '2048',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMemoryMatch() {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Back Card
          Positioned(
            left: 2,
            top: 2,
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                width: size * 0.6,
                height: size * 0.8,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
              ),
            ),
          ),
          // Front Card
          Positioned(
            right: 2,
            bottom: 2,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: size * 0.6,
                height: size * 0.8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: color,
                  size: size * 0.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectFour() {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (col) {
              final isFilled =
                  (row == 2 && col == 1) ||
                  (row == 1 && col == 1) ||
                  (row == 2 && col == 2);
              final isCyan = (row + col) % 2 == 0;
              return Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (isCyan ? AppTheme.neonCyan : AppTheme.neonPink)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isFilled
                        ? Colors.transparent
                        : color.withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildMinesweeper() {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mine spikes
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: size * 0.7,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: size * 0.15,
              height: size * 0.7,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Container(
            width: size * 0.8,
            height: size * 0.15,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: size * 0.15,
            height: size * 0.8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Mine body
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: color, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordSearch() {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        children: [
          // Word Highlight path
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: size * 0.85,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.4), width: 0.8),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _letter('W'),
                  _letter('O'),
                  _letter('R'),
                  _letter('D'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _letter('A'),
                  _letter('Z'),
                  _letter('X'),
                  _letter('Y'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _letter('K'),
                  _letter('M'),
                  _letter('P'),
                  _letter('Q'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _letter(String char) {
    return Text(
      char,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
  }

  Widget _buildSlidingPuzzle() {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_tile('1'), _tile('2')],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tile('3'),
              Container(
                width: (size - 8) / 2 - 2,
                height: (size - 8) / 2 - 2,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: color.withOpacity(0.1), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(String num) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        num,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildCheckers() {
    // 3x3 checkerboard using Column+Row — no GridView overhead.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: List.generate(3, (row) {
            return Expanded(
              child: Row(
                children: List.generate(3, (col) {
                  final idx = row * 3 + col;
                  final isDark = idx % 2 == 0;
                  final hasChip = idx == 1 || idx == 6;
                  final isVioletChip = idx == 1;
                  return Expanded(
                    child: Container(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.transparent,
                      padding: const EdgeInsets.all(3),
                      child: hasChip
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isVioletChip
                                    ? AppTheme.neonViolet
                                    : AppTheme.neonPink,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isVioletChip
                                                ? AppTheme.neonViolet
                                                : AppTheme.neonPink)
                                            .withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Mini Sudoku: 4x4 grid
  Widget _buildMiniSudoku() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: 16,
        itemBuilder: (_, i) {
          // Pre-filled sample values for visual
          const sample = [1, 0, 3, 0, 0, 2, 0, 4, 3, 0, 1, 0, 0, 4, 0, 2];
          final val = sample[i];
          return Container(
            margin: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              border: Border(
                right: i % 2 == 1
                    ? BorderSide(color: color.withOpacity(0.5), width: 1)
                    : BorderSide.none,
                bottom: i ~/ 4 == 1
                    ? BorderSide(color: color.withOpacity(0.5), width: 1)
                    : BorderSide.none,
              ),
            ),
            child: val != 0
                ? Center(
                    child: Text(
                      '$val',
                      style: TextStyle(
                        fontSize: size * 0.1,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  // Zip: numbered dots with a path
  Widget _buildZip() {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ZipVisualPainter(color: color, size: size),
      ),
    );
  }

  // Tango: sun and moon symbols
  Widget _buildTango() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        children: ['☀️', '🌙', '🌙', '☀️', '🌙', '☀️', '☀️', '🌙',
                   '☀️', '🌙', '🌙', '☀️', '🌙', '☀️', '☀️', '🌙']
            .map((e) => Center(
                  child: Text(e, style: TextStyle(fontSize: size * 0.11)),
                ))
            .toList(),
      ),
    );
  }

  // Patchable: colored tetromino blocks
  Widget _buildPatchable() {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PatchableVisualPainter(color: color, size: size),
      ),
    );
  }
}

class _ZipVisualPainter extends CustomPainter {
  final Color color;
  final double size;
  const _ZipVisualPainter({required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cellSize = size / 4;
    // Illustrative path: 1→2→3→4
    final points = [
      Offset(cellSize * 0.5, cellSize * 0.5),
      Offset(cellSize * 1.5, cellSize * 0.5),
      Offset(cellSize * 1.5, cellSize * 1.5),
      Offset(cellSize * 2.5, cellSize * 1.5),
      Offset(cellSize * 2.5, cellSize * 2.5),
      Offset(cellSize * 3.5, cellSize * 2.5),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    final dotPaint = Paint()..color = color;
    final endpoints = [points[0], points[2], points[4], points[5]];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < endpoints.length; i++) {
      canvas.drawCircle(endpoints[i], cellSize * 0.35, dotPaint);
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          fontSize: cellSize * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        endpoints[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ZipVisualPainter old) => false;
}

class _PatchableVisualPainter extends CustomPainter {
  final Color color;
  final double size;
  const _PatchableVisualPainter({required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final cell = size / 5;
    // Each entry: (color, list of [row, col] pairs)
    final pieces = <(Color, List<List<int>>)>[
      (Colors.cyan,        [[0, 0], [1, 0], [2, 0], [2, 1]]),
      (Colors.purpleAccent, [[0, 2], [0, 3], [1, 1], [1, 2]]),
      (Colors.orange,      [[2, 2], [2, 3], [2, 4], [3, 3]]),
      (Colors.green,       [[3, 0], [3, 1], [3, 2], [4, 2]]),
    ];

    for (final (c, coords) in pieces) {
      final paint = Paint()..color = c.withOpacity(0.55);
      for (final coord in coords) {
        final r = coord[0];
        final cc = coord[1];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cc * cell + 1, r * cell + 1, cell - 2, cell - 2),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatchableVisualPainter old) => false;
}

