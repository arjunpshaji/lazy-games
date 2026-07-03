import 'package:flutter/foundation.dart';

/// A single Zip puzzle: grid size, endpoint positions (in order), and the
/// canonical solution path so we can check coverage.
class ZipPuzzle {
  final int size;

  /// Ordered list of cell indices that are the numbered endpoints (1, 2, 3…)
  final List<int> endpoints;
  ZipPuzzle({required this.size, required this.endpoints});
}

// ---------- Static puzzle banks ----------

final _easyPuzzles = [
  ZipPuzzle(size: 4, endpoints: [8, 6, 7, 4]),
  ZipPuzzle(size: 4, endpoints: [4, 7, 11, 8]),
  ZipPuzzle(size: 4, endpoints: [1, 13, 11, 5]),
];

final _mediumPuzzles = [
  ZipPuzzle(size: 5, endpoints: [14, 24, 20, 6, 4]),
  ZipPuzzle(size: 5, endpoints: [6, 2, 16, 24, 12]),
  ZipPuzzle(size: 5, endpoints: [6, 24, 16, 10, 4]),
];

final _hardPuzzles = [
  ZipPuzzle(size: 6, endpoints: [12, 32, 14, 3, 35, 8]),
  ZipPuzzle(size: 6, endpoints: [19, 3, 14, 20, 33, 5]),
  ZipPuzzle(size: 6, endpoints: [4, 15, 2, 30, 28, 5]),
];

class ZipProvider extends ChangeNotifier {
  late ZipPuzzle _puzzle;
  String _difficulty = 'Easy';

  /// The path the player has drawn — list of cell indices in draw order.
  List<int> _path = [];
  bool _isDrawing = false;

  ZipProvider() {
    newGame(difficulty: 'Easy');
  }

  // ---------- Getters ----------
  ZipPuzzle get puzzle => _puzzle;
  String get difficulty => _difficulty;
  List<int> get path => _path;
  bool get isDrawing => _isDrawing;

  int get gridSize => _puzzle.size;
  List<int> get endpoints => _puzzle.endpoints;

  /// The number label at a given cell (1-based), or null if not an endpoint.
  int? endpointNumber(int cellIndex) {
    final idx = _puzzle.endpoints.indexOf(cellIndex);
    return idx == -1 ? null : idx + 1;
  }

  /// True when the player's path covers all cells AND visits endpoints in order.
  bool get isWinner {
    final size = _puzzle.size;
    final total = size * size;
    if (_path.length != total) return false;
    // Must start at endpoint[0] and end at endpoint[last]
    if (_path.first != _puzzle.endpoints.first) return false;
    if (_path.last != _puzzle.endpoints.last) return false;
    // All endpoint numbers must appear in increasing order in the path
    int lastEndpointIdx = -1;
    for (final ep in _puzzle.endpoints) {
      final pathIdx = _path.indexOf(ep);
      if (pathIdx == -1 || pathIdx <= lastEndpointIdx) return false;
      lastEndpointIdx = pathIdx;
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
    _path = [];
    _isDrawing = false;
    notifyListeners();
  }

  // ---------- Drawing ----------

  void startDraw(int cellIndex) {
    // Must start from the first endpoint (or resume from current path end)
    if (_path.isEmpty) {
      if (cellIndex != _puzzle.endpoints.first) return;
    } else {
      // Allow restarting from the first endpoint
      if (cellIndex == _puzzle.endpoints.first) {
        _path = [cellIndex];
        _isDrawing = true;
        notifyListeners();
        return;
      }
      // Continue from last visited cell
      if (cellIndex != _path.last) return;
    }
    _isDrawing = true;
    if (_path.isEmpty) _path = [cellIndex];
    notifyListeners();
  }

  void continueDraw(int cellIndex) {
    if (!_isDrawing) return;
    if (cellIndex == _path.last) return; // Same cell

    // Check adjacency (no diagonal)
    final last = _path.last;
    final size = _puzzle.size;
    final lastRow = last ~/ size;
    final lastCol = last % size;
    final curRow = cellIndex ~/ size;
    final curCol = cellIndex % size;
    final isAdjacent =
        (lastRow == curRow && (lastCol - curCol).abs() == 1) ||
        (lastCol == curCol && (lastRow - curRow).abs() == 1);
    if (!isAdjacent) return;

    // If the cell is already in the path, we can only backtrack to the immediate predecessor
    final existingIdx = _path.indexOf(cellIndex);
    if (existingIdx != -1) {
      if (_path.length >= 2 && cellIndex == _path[_path.length - 2]) {
        _path.removeLast();
        notifyListeners();
      }
      return;
    }

    // Cannot extend the path further once the final endpoint is reached
    if (_path.isNotEmpty && _path.last == _puzzle.endpoints.last) {
      return;
    }

    // Enforce endpoint sequence order: cannot enter endpoint K unless all endpoints 0..K-1 are visited
    final epIdx = _puzzle.endpoints.indexOf(cellIndex);
    if (epIdx > 0) {
      for (int i = 0; i < epIdx; i++) {
        if (!_path.contains(_puzzle.endpoints[i])) {
          return; // Ignore/prevent drag into this square
        }
      }
    }

    _path.add(cellIndex);
    notifyListeners();
  }

  void endDraw() {
    _isDrawing = false;
    notifyListeners();
  }

  void resetPath() {
    _path = [];
    _isDrawing = false;
    notifyListeners();
  }
}
