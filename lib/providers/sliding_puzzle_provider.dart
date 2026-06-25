import 'package:flutter/foundation.dart';

// Top-level function for background isolate computation via compute()
// Generates a 100% solvable 15-puzzle layout.
List<int> generateSolvablePuzzleIsolate(int size) {
  final List<int> tiles = List.generate(size * size, (i) => i); // 0 represents the empty space
  tiles.shuffle();

  // Check solvability of 15-puzzle (size 4)
  bool solvable = isPuzzleSolvable(tiles, size);
  if (!solvable) {
    // To make an unsolvable layout solvable, we can swap any two adjacent non-blank tiles
    int first = -1;
    int second = -1;
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != 0) {
        if (first == -1) {
          first = i;
        } else {
          second = i;
          break;
        }
      }
    }
    // Swap them
    final tmp = tiles[first];
    tiles[first] = tiles[second];
    tiles[second] = tmp;
  }
  return tiles;
}

bool isPuzzleSolvable(List<int> tiles, int size) {
  int inversions = 0;
  for (int i = 0; i < tiles.length - 1; i++) {
    for (int j = i + 1; j < tiles.length; j++) {
      if (tiles[i] != 0 && tiles[j] != 0 && tiles[i] > tiles[j]) {
        inversions++;
      }
    }
  }

  // Find row index of blank (0) from bottom (1-indexed)
  int blankIndex = tiles.indexOf(0);
  int blankRowFromBottom = size - (blankIndex ~/ size);

  if (size % 2 != 0) {
    return inversions % 2 == 0;
  } else {
    if (blankRowFromBottom % 2 == 0) {
      return inversions % 2 != 0;
    } else {
      return inversions % 2 == 0;
    }
  }
}

class SlidingPuzzleProvider extends ChangeNotifier {
  final int size = 4;
  List<int> _board = [];
  int _moves = 0;
  bool _isWon = false;
  bool _isLoading = false;
  bool _isOpponentWon = false;

  List<int> get board => _board;
  int get moves => _moves;
  bool get isWon => _isWon;
  bool get isLoading => _isLoading;
  bool get isOpponentWon => _isOpponentWon;

  void setupGame() {
    _board = List.generate(16, (i) => i);
    _moves = 0;
    _isWon = false;
    _isOpponentWon = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startPuzzle() async {
    _isLoading = true;
    _moves = 0;
    _isWon = false;
    _isOpponentWon = false;
    notifyListeners();

    try {
      final solvableLayout = await compute(generateSolvablePuzzleIsolate, size);
      _board = List<int>.from(solvableLayout);
    } catch (e) {
      debugPrint("Error generating puzzle: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setupNetworkPuzzle(List<int> layout) {
    _board = List<int>.from(layout);
    _moves = 0;
    _isWon = false;
    _isOpponentWon = false;
    _isLoading = false;
    notifyListeners();
  }

  void markOpponentWon() {
    _isOpponentWon = true;
    notifyListeners();
  }

  bool moveTile(int index) {
    if (_isWon || _isOpponentWon) return false;

    // Check if empty tile (0) is adjacent (left, right, up, down)
    final emptyIndex = _board.indexOf(0);
    
    final r1 = index ~/ size;
    final c1 = index % size;
    final r2 = emptyIndex ~/ size;
    final c2 = emptyIndex % size;

    final isAdjacent = (r1 == r2 && (c1 - c2).abs() == 1) || (c1 == c2 && (r1 - r2).abs() == 1);
    
    if (isAdjacent) {
      // Swap
      _board[emptyIndex] = _board[index];
      _board[index] = 0;
      _moves++;
      _checkWin();
      notifyListeners();
      return true;
    }
    return false;
  }

  void _checkWin() {
    // Puzzle is won if values are 1, 2, ..., 15, 0
    for (int i = 0; i < 15; i++) {
      if (_board[i] != i + 1) return;
    }
    _isWon = true;
  }
}
