import 'package:flutter/foundation.dart';

/// Cell values
const int tangoEmpty = 0;
const int tangoSun = 1;
const int tangoMoon = 2;

/// A Tango puzzle
class TangoPuzzle {
  final int size; // grid is size×size
  /// Fixed cells: index → value (tangoSun or tangoMoon). Others are 0.
  final Map<int, int> givens;
  /// The full solution (size*size values)
  final List<int> solution;

  const TangoPuzzle({
    required this.size,
    required this.givens,
    required this.solution,
  });
}

// ---------- Puzzle banks ----------
// Easy: 4×4, each row/col has 2 suns + 2 moons, no 3 consecutive same.

final _easyPuzzles = [
  TangoPuzzle(
    size: 4,
    givens: {0: tangoSun, 3: tangoMoon, 5: tangoMoon, 10: tangoSun},
    solution: [
      tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoMoon, tangoSun, tangoSun,
      tangoSun, tangoSun, tangoMoon, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun,
    ],
  ),
  TangoPuzzle(
    size: 4,
    givens: {1: tangoSun, 6: tangoMoon, 9: tangoSun, 14: tangoMoon},
    solution: [
      tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoMoon, tangoSun,  // fixed: 6→moon
      tangoMoon, tangoSun, tangoSun, tangoMoon,  // fixed: 9→sun
      tangoSun, tangoMoon, tangoMoon, tangoSun,
    ],
  ),
];

// Medium: 6×6 — each row/col has 3 suns + 3 moons
final _mediumPuzzles = [
  TangoPuzzle(
    size: 6,
    givens: {0: tangoSun, 5: tangoMoon, 14: tangoSun, 21: tangoMoon, 30: tangoSun, 35: tangoMoon},
    solution: [
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
    ],
  ),
  TangoPuzzle(
    size: 6,
    givens: {1: tangoMoon, 4: tangoSun, 13: tangoSun, 22: tangoMoon, 31: tangoMoon, 34: tangoSun},
    solution: [
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
    ],
  ),
];

// Hard: 6×6 with fewer givens
final _hardPuzzles = [
  TangoPuzzle(
    size: 6,
    givens: {0: tangoSun, 11: tangoMoon, 24: tangoSun, 35: tangoMoon},
    solution: [
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
      tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon,
      tangoMoon, tangoSun, tangoMoon, tangoSun, tangoMoon, tangoSun,
    ],
  ),
];

class TangoProvider extends ChangeNotifier {
  late TangoPuzzle _puzzle;
  late List<int> _board;
  String _difficulty = 'Easy';

  TangoProvider() {
    newGame(difficulty: 'Easy');
  }

  String get difficulty => _difficulty;
  TangoPuzzle get puzzle => _puzzle;
  List<int> get board => _board;
  int get gridSize => _puzzle.size;

  // ---------- Validation helpers ----------

  /// Returns true if a cell has a constraint violation.
  bool hasCellError(int index) {
    final val = _board[index];
    if (val == tangoEmpty) return false;
    final size = _puzzle.size;
    final row = index ~/ size;
    final col = index % size;

    // Check row: no 3 consecutive
    for (int c = 0; c <= size - 3; c++) {
      final a = _board[row * size + c];
      final b = _board[row * size + c + 1];
      final cc = _board[row * size + c + 2];
      if (a != tangoEmpty && a == b && b == cc) {
        if (c == col || c + 1 == col || c + 2 == col) return true;
      }
    }
    // Check col: no 3 consecutive
    for (int r = 0; r <= size - 3; r++) {
      final a = _board[r * size + col];
      final b = _board[(r + 1) * size + col];
      final cc = _board[(r + 2) * size + col];
      if (a != tangoEmpty && a == b && b == cc) {
        if (r == row || r + 1 == row || r + 2 == row) return true;
      }
    }
    return false;
  }

  bool get isWinner {
    final size = _puzzle.size;
    final total = size * size;
    // No empty cells
    if (_board.contains(tangoEmpty)) return false;
    // Must match solution
    for (int i = 0; i < total; i++) {
      if (_board[i] != _puzzle.solution[i]) return false;
    }
    return true;
  }

  // ---------- Game setup ----------

  void newGame({String? difficulty}) {
    _difficulty = difficulty ?? _difficulty;
    final bank = switch (_difficulty) {
      'Hard' => _hardPuzzles,
      'Medium' => _mediumPuzzles,
      _ => _easyPuzzles,
    };
    _puzzle = bank[DateTime.now().millisecondsSinceEpoch % bank.length];
    _board = List.generate(_puzzle.size * _puzzle.size, (_) => tangoEmpty);
    // Place givens
    _puzzle.givens.forEach((idx, val) => _board[idx] = val);
    notifyListeners();
  }

  // ---------- User interaction ----------

  void tapCell(int index) {
    // Given cells cannot be changed
    if (_puzzle.givens.containsKey(index)) return;
    final current = _board[index];
    _board[index] = switch (current) {
      tangoEmpty => tangoSun,
      tangoSun => tangoMoon,
      _ => tangoEmpty,
    };
    notifyListeners();
  }
}
