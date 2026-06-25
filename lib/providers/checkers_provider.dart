import 'package:flutter/material.dart';

class CheckersProvider extends ChangeNotifier {
  // 8x8 Board (64 cells)
  // 0: empty
  // 1: Player 1 (Pink) normal
  // 2: Player 1 (Pink) King
  // 3: Player 2 (Cyan) normal
  // 4: Player 2 (Cyan) King
  List<int> _board = List.generate(64, (_) => 0);
  bool _isPlayer1Turn = true;
  int _selectedPiece = -1;
  List<int> _validMoves = [];
  int _winner = 0; // 0: none, 1: P1, 2: P2

  bool _isNetworkGame = false;
  String _myRole = 'host'; // 'host' (P1, Pink, bottom) or 'client' (P2, Cyan, top)

  List<int> get board => _board;
  bool get isPlayer1Turn => _isPlayer1Turn;
  int get selectedPiece => _selectedPiece;
  List<int> get validMoves => _validMoves;
  int get winner => _winner;
  bool get isNetworkGame => _isNetworkGame;
  String get myRole => _myRole;

  bool get isMyTurn {
    if (!_isNetworkGame) return true;
    return (_myRole == 'host' && _isPlayer1Turn) || (_myRole == 'client' && !_isPlayer1Turn);
  }

  void setupGame({required bool isNetwork, required String role}) {
    _isNetworkGame = isNetwork;
    _myRole = role;
    _board = List.generate(64, (_) => 0);
    _selectedPiece = -1;
    _validMoves = [];
    _winner = 0;
    _isPlayer1Turn = true;

    // Initial Board Setup:
    // P2 pieces (Cyan) in top 3 rows (dark squares only)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 != 0) {
          _board[row * 8 + col] = 3;
        }
      }
    }

    // P1 pieces (Pink) in bottom 3 rows (dark squares only)
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 != 0) {
          _board[row * 8 + col] = 1;
        }
      }
    }

    notifyListeners();
  }

  void selectPiece(int index) {
    if (_winner != 0 || !isMyTurn) return;

    final cell = _board[index];
    final isP1Piece = cell == 1 || cell == 2;
    final isP2Piece = cell == 3 || cell == 4;

    if ((_isPlayer1Turn && !isP1Piece) || (!_isPlayer1Turn && !isP2Piece)) {
      _selectedPiece = -1;
      _validMoves = [];
      notifyListeners();
      return;
    }

    _selectedPiece = index;
    _validMoves = _calculateValidMoves(index);
    notifyListeners();
  }

  bool makeMove(int toIndex) {
    if (_selectedPiece == -1 || !_validMoves.contains(toIndex)) return false;

    final fromIndex = _selectedPiece;
    final piece = _board[fromIndex];
    
    // Execute move
    _board[toIndex] = piece;
    _board[fromIndex] = 0;

    // Handle captures
    final isJump = (fromIndex - toIndex).abs() > 9;
    if (isJump) {
      final midIndex = (fromIndex + toIndex) ~/ 2;
      _board[midIndex] = 0; // Remove captured piece
    }

    // Handle king promotions
    final toRow = toIndex ~/ 8;
    if (piece == 1 && toRow == 0) {
      _board[toIndex] = 2; // P1 King
    } else if (piece == 3 && toRow == 7) {
      _board[toIndex] = 4; // P2 King
    }

    _selectedPiece = -1;
    _validMoves = [];
    _isPlayer1Turn = !_isPlayer1Turn;
    _checkWinState();

    notifyListeners();
    return true;
  }

  void handleNetworkMove(int fromIndex, int toIndex) {
    _selectedPiece = fromIndex;
    _validMoves = _calculateValidMoves(fromIndex);
    makeMove(toIndex);
  }

  List<int> _calculateValidMoves(int index) {
    final cell = _board[index];
    if (cell == 0) return [];

    final isKing = cell == 2 || cell == 4;
    final isP1 = cell == 1 || cell == 2;

    final List<int> destinations = [];
    
    // Directions configuration
    // Rows: P1 moves up (decreasing row), P2 moves down (increasing row)
    // Kings move both directions
    final List<int> rowDirs = [];
    if (isKing) {
      rowDirs.addAll([-1, 1]);
    } else {
      rowDirs.add(isP1 ? -1 : 1);
    }

    final int startRow = index ~/ 8;
    final int startCol = index % 8;

    for (int dr in rowDirs) {
      for (int dc in [-1, 1]) {
        // 1-step slide
        int targetRow = startRow + dr;
        int targetCol = startCol + dc;
        if (targetRow >= 0 && targetRow < 8 && targetCol >= 0 && targetCol < 8) {
          int targetIdx = targetRow * 8 + targetCol;
          if (_board[targetIdx] == 0) {
            destinations.add(targetIdx);
          } else {
            // 2-step jump
            final targetPiece = _board[targetIdx];
            final isTargetEnemy = isP1 ? (targetPiece == 3 || targetPiece == 4) : (targetPiece == 1 || targetPiece == 2);
            
            if (isTargetEnemy) {
              int jumpRow = startRow + (dr * 2);
              int jumpCol = startCol + (dc * 2);
              if (jumpRow >= 0 && jumpRow < 8 && jumpCol >= 0 && jumpCol < 8) {
                int jumpIdx = jumpRow * 8 + jumpCol;
                if (_board[jumpIdx] == 0) {
                  destinations.add(jumpIdx);
                }
              }
            }
          }
        }
      }
    }

    return destinations;
  }

  void _checkWinState() {
    bool hasP1 = false;
    bool hasP2 = false;

    for (var piece in _board) {
      if (piece == 1 || piece == 2) hasP1 = true;
      if (piece == 3 || piece == 4) hasP2 = true;
    }

    if (!hasP1) {
      _winner = 2; // P2 wins
    } else if (!hasP2) {
      _winner = 1; // P1 wins
    }
  }
}
