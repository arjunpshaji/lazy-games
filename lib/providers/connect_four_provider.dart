import 'package:flutter/material.dart';

class ConnectFourProvider extends ChangeNotifier {
  // 7 columns x 6 rows board represented as a flat list of size 42
  // 0: empty, 1: player1 (Cyan), 2: player2 (Violet)
  List<int> _board = List.generate(42, (_) => 0);
  bool _isPlayer1Turn = true;
  int _winner = 0; // 0: none, 1: P1, 2: P2, 3: Draw
  List<int> _winningCells = [];

  bool _isNetworkGame = false;
  String _myRole = 'host';

  List<int> get board => _board;
  bool get isPlayer1Turn => _isPlayer1Turn;
  int get winner => _winner;
  List<int> get winningCells => _winningCells;
  bool get isNetworkGame => _isNetworkGame;
  String get myRole => _myRole;

  bool get isMyTurn {
    if (!_isNetworkGame) return true;
    return (_myRole == 'host' && _isPlayer1Turn) || (_myRole == 'client' && !_isPlayer1Turn);
  }

  void setupGame({required bool isNetwork, required String role}) {
    _isNetworkGame = isNetwork;
    _myRole = role;
    _board = List.generate(42, (_) => 0);
    _isPlayer1Turn = true;
    _winner = 0;
    _winningCells = [];
    notifyListeners();
  }

  // Drop disc into column (0-6)
  bool dropDisc(int col) {
    if (col < 0 || col >= 7 || _winner != 0 || !isMyTurn) return false;

    // Find the lowest empty row (starting from bottom row 5 up to row 0)
    int targetRow = -1;
    for (int r = 5; r >= 0; r--) {
      if (_board[r * 7 + col] == 0) {
        targetRow = r;
        break;
      }
    }

    if (targetRow == -1) return false; // Column is full

    final player = _isPlayer1Turn ? 1 : 2;
    final index = targetRow * 7 + col;
    _board[index] = player;

    _checkWin(targetRow, col, player);
    
    if (_winner == 0) {
      _isPlayer1Turn = !_isPlayer1Turn;
    }
    notifyListeners();
    return true;
  }

  // Handle disc drop from opponent over network
  void handleNetworkDrop(int col) {
    if (col < 0 || col >= 7 || _winner != 0) return;

    int targetRow = -1;
    for (int r = 5; r >= 0; r--) {
      if (_board[r * 7 + col] == 0) {
        targetRow = r;
        break;
      }
    }

    if (targetRow == -1) return;

    final player = _isPlayer1Turn ? 1 : 2;
    final index = targetRow * 7 + col;
    _board[index] = player;

    _checkWin(targetRow, col, player);
    
    if (_winner == 0) {
      _isPlayer1Turn = !_isPlayer1Turn;
    }
    notifyListeners();
  }

  /// Apply full board state from Supabase Realtime.
  void applyOnlineState({required List<int> board, required bool isPlayer1Turn}) {
    _board = List<int>.from(board);
    _isPlayer1Turn = isPlayer1Turn;
    _checkWinFull();
    notifyListeners();
  }

  void _checkWinFull() {
    _winner = 0;
    _winningCells = [];

    int getVal(int r, int c) {
      if (r < 0 || r >= 6 || c < 0 || c >= 7) return -1;
      return _board[r * 7 + c];
    }

    final directions = [
      [0, 1],  // Horizontal
      [1, 0],  // Vertical
      [1, 1],  // Diagonal down-right
      [1, -1], // Diagonal down-left
    ];

    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 7; col++) {
        final player = getVal(row, col);
        if (player == 0 || player == -1) continue;

        for (var dir in directions) {
          int dRow = dir[0];
          int dCol = dir[1];

          final currentWinCells = [row * 7 + col];
          int r = row + dRow;
          int c = col + dCol;
          while (getVal(r, c) == player) {
            currentWinCells.add(r * 7 + c);
            r += dRow;
            c += dCol;
          }

          if (currentWinCells.length >= 4) {
            _winner = player;
            _winningCells = currentWinCells;
            return;
          }
        }
      }
    }

    // Check draw
    if (!_board.contains(0)) {
      _winner = 3; // Draw
    }
  }

  void _checkWin(int row, int col, int player) {
    // Helper to get value
    int getVal(int r, int c) {
      if (r < 0 || r >= 6 || c < 0 || c >= 7) return -1;
      return _board[r * 7 + c];
    }

    // Directions: [dRow, dCol]
    final directions = [
      [0, 1],  // Horizontal
      [1, 0],  // Vertical
      [1, 1],  // Diagonal down-right
      [1, -1], // Diagonal down-left
    ];

    for (var dir in directions) {
      int dRow = dir[0];
      int dCol = dir[1];
      
      final currentWinCells = [row * 7 + col];
      
      // Look forward
      int r = row + dRow;
      int c = col + dCol;
      while (getVal(r, c) == player) {
        currentWinCells.add(r * 7 + c);
        r += dRow;
        c += dCol;
      }
      
      // Look backward
      r = row - dRow;
      c = col - dCol;
      while (getVal(r, c) == player) {
        currentWinCells.add(r * 7 + c);
        r -= dRow;
        c -= dCol;
      }

      if (currentWinCells.length >= 4) {
        _winner = player;
        _winningCells = currentWinCells;
        return;
      }
    }

    // Check draw
    if (!_board.contains(0)) {
      _winner = 3; // Draw
    }
  }
}
