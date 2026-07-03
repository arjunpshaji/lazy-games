import 'dart:math';
import 'package:flutter/foundation.dart';

class MiniSudokuProvider extends ChangeNotifier {
  // 4×4 grid — 16 cells total
  List<int> _puzzle = List.generate(16, (_) => 0);
  List<int> _board = List.generate(16, (_) => 0);
  List<int> _solution = List.generate(16, (_) => 0);
  List<List<int>> _notes = List.generate(16, (_) => []);
  List<bool> _conflictMap = List.generate(16, (_) => false);

  int _selectedCell = -1;
  bool _isNoteMode = false;
  bool _isLoading = false;
  String _difficulty = 'Easy';

  List<int> get puzzle => _puzzle;
  List<int> get board => _board;
  List<int> get solution => _solution;
  List<List<int>> get notes => _notes;
  List<bool> get conflictMap => _conflictMap;
  int get selectedCell => _selectedCell;
  bool get isNoteMode => _isNoteMode;
  bool get isLoading => _isLoading;
  String get difficulty => _difficulty;

  // ---------- Conflict detection ----------

  void _recomputeConflicts() {
    for (int i = 0; i < 16; i++) {
      _conflictMap[i] = _hasConflict(i);
    }
  }

  bool _hasConflict(int index) {
    final val = _board[index];
    if (val == 0) return false;
    final row = index ~/ 4;
    final col = index % 4;

    // Row
    for (int c = 0; c < 4; c++) {
      final idx = row * 4 + c;
      if (idx != index && _board[idx] == val) return true;
    }
    // Col
    for (int r = 0; r < 4; r++) {
      final idx = r * 4 + col;
      if (idx != index && _board[idx] == val) return true;
    }
    // 2x2 box
    final boxRow = (row ~/ 2) * 2;
    final boxCol = (col ~/ 2) * 2;
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        final idx = (boxRow + r) * 4 + (boxCol + c);
        if (idx != index && _board[idx] == val) return true;
      }
    }
    return false;
  }

  bool hasConflict(int index) => _conflictMap[index];

  // ---------- Puzzle generation ----------

  Future<void> generateNewGame({String difficulty = 'Easy'}) async {
    _isLoading = true;
    _difficulty = difficulty;
    _selectedCell = -1;
    _isNoteMode = false;
    notifyListeners();

    try {
      final result = await compute(_generateMiniSudoku, difficulty);
      _solution = result[0];
      _puzzle = result[1];
      _board = List<int>.from(_puzzle);
      _notes = List.generate(16, (_) => []);
      _recomputeConflicts();
    } catch (e) {
      debugPrint('Error generating mini sudoku: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- User interactions ----------

  void selectCell(int index) {
    _selectedCell = index;
    notifyListeners();
  }

  void toggleNoteMode() {
    _isNoteMode = !_isNoteMode;
    notifyListeners();
  }

  bool inputNumber(int val) {
    if (_selectedCell == -1 || _puzzle[_selectedCell] != 0) return false;
    if (_isNoteMode) {
      if (_notes[_selectedCell].contains(val)) {
        _notes[_selectedCell].remove(val);
      } else {
        _notes[_selectedCell].add(val);
      }
      _board[_selectedCell] = 0;
    } else {
      _board[_selectedCell] = _board[_selectedCell] == val ? 0 : val;
      _notes[_selectedCell].clear();
    }
    _recomputeConflicts();
    notifyListeners();
    return true;
  }

  bool deleteNumber() {
    if (_selectedCell == -1 || _puzzle[_selectedCell] != 0) return false;
    _board[_selectedCell] = 0;
    _notes[_selectedCell].clear();
    _recomputeConflicts();
    notifyListeners();
    return true;
  }

  // ---------- Win detection ----------

  bool get isWinner {
    if (_board.contains(0)) return false;
    for (int i = 0; i < 16; i++) {
      if (_board[i] != _solution[i]) return false;
    }
    return true;
  }
}

// ---------- Isolate work ----------

/// Returns [solution, puzzle] (both length-16 lists).
List<List<int>> _generateMiniSudoku(String difficulty) {
  final rng = Random();

  // Generate a fully solved 4x4 Sudoku
  List<int> grid = List.generate(16, (_) => 0);
  _solveMiniSudoku(grid, rng);

  final solution = List<int>.from(grid);

  // Number of cells to remove based on difficulty
  final toRemove = switch (difficulty) {
    'Hard' => 10,
    'Medium' => 7,
    _ => 4, // Easy
  };

  final puzzle = List<int>.from(solution);
  final indices = List.generate(16, (i) => i)..shuffle(rng);
  int removed = 0;
  for (final idx in indices) {
    if (removed >= toRemove) break;
    final backup = puzzle[idx];
    puzzle[idx] = 0;
    // Verify unique solution still exists
    if (_countMiniSolutions(List<int>.from(puzzle)) == 1) {
      removed++;
    } else {
      puzzle[idx] = backup;
    }
  }

  return [solution, puzzle];
}

bool _solveMiniSudoku(List<int> grid, Random rng) {
  final empty = grid.indexOf(0);
  if (empty == -1) return true;

  final nums = [1, 2, 3, 4]..shuffle(rng);
  for (final n in nums) {
    if (_isValidMini(grid, empty, n)) {
      grid[empty] = n;
      if (_solveMiniSudoku(grid, rng)) return true;
      grid[empty] = 0;
    }
  }
  return false;
}

bool _isValidMini(List<int> grid, int index, int val) {
  final row = index ~/ 4;
  final col = index % 4;
  for (int c = 0; c < 4; c++) {
    if (grid[row * 4 + c] == val) return false;
  }
  for (int r = 0; r < 4; r++) {
    if (grid[r * 4 + col] == val) return false;
  }
  final boxRow = (row ~/ 2) * 2;
  final boxCol = (col ~/ 2) * 2;
  for (int r = 0; r < 2; r++) {
    for (int c = 0; c < 2; c++) {
      if (grid[(boxRow + r) * 4 + (boxCol + c)] == val) return false;
    }
  }
  return true;
}

int _countMiniSolutions(List<int> grid, {int max = 2}) {
  final empty = grid.indexOf(0);
  if (empty == -1) return 1;
  int count = 0;
  for (int n = 1; n <= 4; n++) {
    if (_isValidMini(grid, empty, n)) {
      grid[empty] = n;
      count += _countMiniSolutions(grid, max: max);
      grid[empty] = 0;
      if (count >= max) return count;
    }
  }
  return count;
}
