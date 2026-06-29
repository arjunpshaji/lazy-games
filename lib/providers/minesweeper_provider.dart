import 'dart:math';
import 'package:flutter/foundation.dart';

// Helper class for Minesweeper cells
class MinesweeperCell {
  bool isMine;
  int neighborMines;
  bool isRevealed;
  bool isFlagged;

  MinesweeperCell({
    this.isMine = false,
    this.neighborMines = 0,
    this.isRevealed = false,
    this.isFlagged = false,
  });
}

// Flat list representation transfer helper for Isolate compute
// Input: Map with 'rows', 'cols', 'mines', and optional 'firstTapIndex'
List<int> generateMinesweeperBoardIsolate(Map<String, dynamic> args) {
  final int rows = args['rows'];
  final int cols = args['cols'];
  final int numMines = args['mines'];
  final int? firstTap = args['firstTap'];

  final grid = List.generate(rows * cols, (_) => MinesweeperCell());

  // Place mines randomly, ensuring firstTap index is safe
  final random = Random();
  int placed = 0;
  while (placed < numMines) {
    int idx = random.nextInt(rows * cols);
    if (grid[idx].isMine) continue;
    
    // Safety buffer around first tap (preventing instant loss on first move)
    if (firstTap != null) {
      int r = idx ~/ cols;
      int c = idx % cols;
      int tr = firstTap ~/ cols;
      int tc = firstTap % cols;
      if ((r - tr).abs() <= 1 && (c - tc).abs() <= 1) {
        continue; // Keep surrounding 3x3 of first tap clear of mines
      }
    }

    grid[idx].isMine = true;
    placed++;
  }

  // Calculate neighbors
  for (int idx = 0; idx < rows * cols; idx++) {
    if (grid[idx].isMine) continue;
    int r = idx ~/ cols;
    int c = idx % cols;
    int count = 0;
    
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          if (grid[nr * cols + nc].isMine) {
            count++;
          }
        }
      }
    }
    grid[idx].neighborMines = count;
  }

  // Convert to flat list: [isMine (1/0), neighborCount, isRevealed (1/0), isFlagged (1/0)]
  final List<int> result = [];
  for (var cell in grid) {
    result.add(cell.isMine ? 1 : 0);
    result.add(cell.neighborMines);
    result.add(cell.isRevealed ? 1 : 0);
    result.add(cell.isFlagged ? 1 : 0);
  }
  return result;
}

class MinesweeperProvider extends ChangeNotifier {
  final int rows = 10;
  final int cols = 10;
  final int numMines = 12;
  
  List<MinesweeperCell> _grid = List.generate(100, (_) => MinesweeperCell());
  bool _isGameOver = false;
  bool _isWon = false;
  bool _isLoading = false;
  bool _firstTapDone = false;

  List<MinesweeperCell> get grid => _grid;
  bool get isGameOver => _isGameOver;
  bool get isWon => _isWon;
  bool get isLoading => _isLoading;
  bool get firstTapDone => _firstTapDone;

  // Cached counter — O(1) read instead of scanning 100 cells per build.
  int _flaggedCount = 0;
  int get flaggedCount => _flaggedCount;

  void setupGame() {
    _grid = List.generate(rows * cols, (_) => MinesweeperCell());
    _isGameOver = false;
    _isWon = false;
    _firstTapDone = false;
    _isLoading = false;
    _flaggedCount = 0;
    notifyListeners();
  }

  // Initialize board via background compute
  Future<void> initBoard(int firstTapIndex) async {
    _isLoading = true;
    notifyListeners();

    try {
      final flatGrid = await compute(generateMinesweeperBoardIsolate, {
        'rows': rows,
        'cols': cols,
        'mines': numMines,
        'firstTap': firstTapIndex,
      });

      _grid.clear();
      for (int i = 0; i < flatGrid.length; i += 4) {
        _grid.add(MinesweeperCell(
          isMine: flatGrid[i] == 1,
          neighborMines: flatGrid[i + 1],
          isRevealed: flatGrid[i + 2] == 1,
          isFlagged: flatGrid[i + 3] == 1,
        ));
      }
      
      _firstTapDone = true;
      _revealCellLogic(firstTapIndex);
      _checkWin();
    } catch (e) {
      debugPrint("Error creating Minesweeper board: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set grid manually (sync from Host to Client)
  void setupNetworkBoard(List<int> flatGrid) {
    _grid.clear();
    int flagCount = 0;
    for (int i = 0; i < flatGrid.length; i += 4) {
      final isFlagged = flatGrid[i + 3] == 1;
      if (isFlagged) flagCount++;
      _grid.add(MinesweeperCell(
        isMine: flatGrid[i] == 1,
        neighborMines: flatGrid[i + 1],
        isRevealed: flatGrid[i + 2] == 1,
        isFlagged: isFlagged,
      ));
    }
    _flaggedCount = flagCount;
    _firstTapDone = true;
    _isGameOver = false;
    _isWon = false;
    _isLoading = false;
    notifyListeners();
  }

  // Reveal Cell
  void revealCell(int index) {
    if (_isGameOver || _isWon || _grid[index].isRevealed || _grid[index].isFlagged) return;

    if (!_firstTapDone) {
      // First tap must generate the board safely
      initBoard(index);
    } else {
      _revealCellLogic(index);
      _checkWin();
      notifyListeners();
    }
  }

  void _revealCellLogic(int index) {
    final cell = _grid[index];
    cell.isRevealed = true;

    if (cell.isMine) {
      _isGameOver = true;
      _revealAllMines();
      return;
    }

    if (cell.neighborMines == 0) {
      // Cascade
      int r = index ~/ cols;
      int c = index % cols;
      
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          int nr = r + dr;
          int nc = c + dc;
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
            int nIdx = nr * cols + nc;
            if (!_grid[nIdx].isRevealed && !_grid[nIdx].isMine && !_grid[nIdx].isFlagged) {
              _revealCellLogic(nIdx);
            }
          }
        }
      }
    }
  }

  // Toggle Flag
  void toggleFlag(int index) {
    if (_isGameOver || _isWon || _grid[index].isRevealed) return;
    _grid[index].isFlagged = !_grid[index].isFlagged;
    _flaggedCount += _grid[index].isFlagged ? 1 : -1;
    _checkWin();
    notifyListeners();
  }

  void _revealAllMines() {
    for (var cell in _grid) {
      if (cell.isMine) cell.isRevealed = true;
    }
  }

  void _checkWin() {
    bool win = true;
    for (var cell in _grid) {
      if (!cell.isMine && !cell.isRevealed) {
        win = false;
        break;
      }
    }
    if (win) {
      _isWon = true;
    }
  }

  // Flat data list for network sync
  List<int> getFlatGrid() {
    final List<int> result = [];
    for (var cell in _grid) {
      result.add(cell.isMine ? 1 : 0);
      result.add(cell.neighborMines);
      result.add(cell.isRevealed ? 1 : 0);
      result.add(cell.isFlagged ? 1 : 0);
    }
    return result;
  }
}
