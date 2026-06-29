import 'package:flutter/foundation.dart';
import 'package:lazy_games/utils/sudoku_generator.dart';

class SudokuProvider extends ChangeNotifier {
  List<int> _puzzle = List.generate(81, (_) => 0);
  List<int> _board = List.generate(81, (_) => 0);
  List<int> _solution = List.generate(81, (_) => 0);
  List<List<int>> _notes = List.generate(81, (_) => []);

  int _selectedCell = -1;
  bool _isNoteMode = false;
  bool _isLoading = false;
  String _difficulty = 'Easy';

  // Pre-computed conflict map — updated once per board change (O(81×27))
  // and read O(1) per cell instead of recomputing 81× per rebuild.
  List<bool> _conflictMap = List.generate(81, (_) => false);

  List<int> get puzzle => _puzzle;
  List<int> get board => _board;
  List<int> get solution => _solution;
  List<List<int>> get notes => _notes;
  List<bool> get conflictMap => _conflictMap;
  int get selectedCell => _selectedCell;
  bool get isNoteMode => _isNoteMode;
  bool get isLoading => _isLoading;
  String get difficulty => _difficulty;

  // ---------- Conflict computation (called once per change, not 81× per build) ----------

  void _recomputeConflicts() {
    for (int i = 0; i < 81; i++) {
      _conflictMap[i] = _computeConflict(i);
    }
  }

  bool _computeConflict(int index) {
    final val = _board[index];
    if (val == 0) return false;

    final row = index ~/ 9;
    final col = index % 9;

    // Row conflict
    for (int c = 0; c < 9; c++) {
      final idx = row * 9 + c;
      if (idx != index && _board[idx] == val) return true;
    }

    // Col conflict
    for (int r = 0; r < 9; r++) {
      final idx = r * 9 + col;
      if (idx != index && _board[idx] == val) return true;
    }

    // Subgrid conflict
    final boxRowStart = (row ~/ 3) * 3;
    final boxColStart = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final idx = (boxRowStart + r) * 9 + (boxColStart + c);
        if (idx != index && _board[idx] == val) return true;
      }
    }

    return false;
  }

  // ---------- Game setup ----------

  Future<void> generateNewGame({String difficulty = 'Easy'}) async {
    _isLoading = true;
    _difficulty = difficulty;
    _selectedCell = -1;
    _isNoteMode = false;
    notifyListeners();

    try {
      // Use compute to run the heavy backtracking generation in a separate Isolate
      final boardData = await compute(generateSudokuIsolate, difficulty);
      _puzzle = List<int>.from(boardData.puzzle);
      _board = List<int>.from(boardData.puzzle);
      _solution = List<int>.from(boardData.solution);
      _notes = List.generate(81, (_) => []);
      _recomputeConflicts();
    } catch (e) {
      debugPrint("Error generating Sudoku: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setupNetworkGame(List<int> puzzleData, List<int> solutionData) {
    _puzzle = List<int>.from(puzzleData);
    _board = List<int>.from(puzzleData);
    _solution = List<int>.from(solutionData);
    _notes = List.generate(81, (_) => []);
    _selectedCell = -1;
    _isNoteMode = false;
    _isLoading = false;
    _recomputeConflicts();
    notifyListeners();
  }

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

  void syncNetworkInput(int index, int val, bool isNote) {
    if (index < 0 || index >= 81 || _puzzle[index] != 0) return;

    if (isNote) {
      if (_notes[index].contains(val)) {
        _notes[index].remove(val);
      } else {
        _notes[index].add(val);
      }
      _board[index] = 0;
    } else {
      _board[index] = val;
      _notes[index].clear();
    }
    _recomputeConflicts();
    notifyListeners();
  }

  void syncNetworkDelete(int index) {
    if (index < 0 || index >= 81 || _puzzle[index] != 0) return;
    _board[index] = 0;
    _notes[index].clear();
    _recomputeConflicts();
    notifyListeners();
  }

  bool get isWinner {
    if (_board.contains(0)) return false;
    for (int i = 0; i < 81; i++) {
      if (_board[i] != _solution[i]) return false;
    }
    return true;
  }

  /// Delegates to cached conflict map — O(1) read instead of O(27) scan.
  bool hasConflict(int index) => _conflictMap[index];
}
