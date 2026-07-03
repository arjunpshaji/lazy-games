import 'package:flutter/foundation.dart';

/// A piece is a list of [row, col] offsets relative to its top-left.
class PatchPiece {
  final String id;
  final List<List<int>> cells; // each: [row, col]
  final int colorIndex; // maps to a color in the UI

  const PatchPiece({
    required this.id,
    required this.cells,
    required this.colorIndex,
  });

  int get rows => cells.map((c) => c[0]).reduce((a, b) => a > b ? a : b) + 1;
  int get cols => cells.map((c) => c[1]).reduce((a, b) => a > b ? a : b) + 1;
}

// ---------- Piece definitions ----------

const _allPieces = [
  PatchPiece(id: 'I4',   cells: [[0,0],[0,1],[0,2],[0,3]], colorIndex: 0),
  PatchPiece(id: 'L4',   cells: [[0,0],[1,0],[2,0],[2,1]], colorIndex: 1),
  PatchPiece(id: 'J4',   cells: [[0,1],[1,1],[2,0],[2,1]], colorIndex: 2),
  PatchPiece(id: 'T4',   cells: [[0,0],[0,1],[0,2],[1,1]], colorIndex: 3),
  PatchPiece(id: 'S4',   cells: [[0,1],[0,2],[1,0],[1,1]], colorIndex: 4),
  PatchPiece(id: 'Z4',   cells: [[0,0],[0,1],[1,1],[1,2]], colorIndex: 5),
  PatchPiece(id: 'O4',   cells: [[0,0],[0,1],[1,0],[1,1]], colorIndex: 6),
  PatchPiece(id: 'L3',   cells: [[0,0],[1,0],[1,1]], colorIndex: 7),
  PatchPiece(id: 'I3',   cells: [[0,0],[0,1],[0,2]], colorIndex: 0),
  PatchPiece(id: 'T5',   cells: [[0,0],[0,1],[0,2],[1,1],[2,1]], colorIndex: 3),
  PatchPiece(id: 'Plus', cells: [[0,1],[1,0],[1,1],[1,2],[2,1]], colorIndex: 5),
  PatchPiece(id: 'U5',   cells: [[0,0],[0,2],[1,0],[1,1],[1,2]], colorIndex: 6),
];

// ---------- Puzzle definitions ----------

class PatchPuzzle {
  final int size;
  final List<String> pieceIds; // which pieces to use for this puzzle

  const PatchPuzzle({required this.size, required this.pieceIds});
}

final _easyPuzzles = [
  // 5×5 = 25 cells; use pieces summing to 25
  const PatchPuzzle(size: 5, pieceIds: ['I4','L4','J4','T4','S4','Z4','O4']),
];

final _mediumPuzzles = [
  // 6×6 = 36 cells
  const PatchPuzzle(size: 6, pieceIds: ['I4','L4','J4','T4','S4','Z4','O4','L3','I3']),
];

final _hardPuzzles = [
  // 7×7 = 49 cells
  const PatchPuzzle(size: 7, pieceIds: ['I4','L4','J4','T4','S4','Z4','O4','L3','I3','T5','Plus','U5']),
];

// ---------- Placed piece ----------

class PlacedPiece {
  final PatchPiece piece;
  final int originRow;
  final int originCol;

  const PlacedPiece({
    required this.piece,
    required this.originRow,
    required this.originCol,
  });

  /// The absolute grid cells this piece occupies.
  List<List<int>> get cells => piece.cells
      .map((c) => [originRow + c[0], originCol + c[1]])
      .toList();
}

class PatchableProvider extends ChangeNotifier {
  late PatchPuzzle _puzzle;
  String _difficulty = 'Easy';

  late List<PatchPiece> _availablePieces;
  final List<PlacedPiece> _placed = [];

  /// The "board" — each cell holds the colorIndex of the placed piece, or -1.
  late List<int> _board;

  /// The currently selected piece (from palette), or null.
  PatchPiece? _selectedPiece;

  PatchableProvider() {
    newGame(difficulty: 'Easy');
  }

  String get difficulty => _difficulty;
  PatchPuzzle get puzzle => _puzzle;
  List<PatchPiece> get availablePieces => _availablePieces;
  List<PlacedPiece> get placed => _placed;
  List<int> get board => _board;
  PatchPiece? get selectedPiece => _selectedPiece;

  int get gridSize => _puzzle.size;

  bool get isWinner => !_board.contains(-1);

  void newGame({String? difficulty}) {
    _difficulty = difficulty ?? _difficulty;
    final bank = switch (_difficulty) {
      'Hard' => _hardPuzzles,
      'Medium' => _mediumPuzzles,
      _ => _easyPuzzles,
    };
    _puzzle = bank[0];
    _board = List.generate(_puzzle.size * _puzzle.size, (_) => -1);
    _placed.clear();
    _selectedPiece = null;

    // Pick the pieces for this puzzle
    _availablePieces = _puzzle.pieceIds
        .map((id) => _allPieces.firstWhere((p) => p.id == id))
        .toList();
    notifyListeners();
  }

  void selectPiece(PatchPiece piece) {
    _selectedPiece = _selectedPiece?.id == piece.id ? null : piece;
    notifyListeners();
  }

  void deselectPiece() {
    _selectedPiece = null;
    notifyListeners();
  }

  /// Try to place the selected piece with its top-left at [row, col].
  bool placePiece(int row, int col) {
    final piece = _selectedPiece;
    if (piece == null) return false;

    // Check bounds and no overlap
    for (final c in piece.cells) {
      final r2 = row + c[0];
      final c2 = col + c[1];
      if (r2 < 0 || r2 >= _puzzle.size) return false;
      if (c2 < 0 || c2 >= _puzzle.size) return false;
      if (_board[r2 * _puzzle.size + c2] != -1) return false;
    }

    // Place it
    final pp = PlacedPiece(piece: piece, originRow: row, originCol: col);
    _placed.add(pp);
    for (final c in piece.cells) {
      _board[(row + c[0]) * _puzzle.size + (col + c[1])] = piece.colorIndex;
    }
    _availablePieces.remove(piece);
    _selectedPiece = null;
    notifyListeners();
    return true;
  }

  /// Remove a placed piece by tapping any of its cells.
  void removePieceAt(int row, int col) {
    final idx = _placed.indexWhere((pp) {
      return pp.cells.any((c) => c[0] == row && c[1] == col);
    });
    if (idx == -1) return;
    final pp = _placed[idx];
    _placed.removeAt(idx);
    for (final c in pp.cells) {
      _board[(pp.originRow + c[0]) * _puzzle.size + (pp.originCol + c[1])] = -1;
    }
    _availablePieces.add(pp.piece);
    notifyListeners();
  }
}
