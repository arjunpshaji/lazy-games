import 'package:flutter/material.dart';

class TicTacToeProvider extends ChangeNotifier {
  List<String> _board = List.generate(9, (_) => '');
  bool _isXTurn = true;
  String? _winner; // 'X', 'O', 'Draw', or null
  List<int> _winningLine = [];
  bool _isNetworkGame = false;
  String _mySymbol = 'X'; // 'X' for host/player1, 'O' for client/player2

  List<String> get board => _board;
  bool get isXTurn => _isXTurn;
  String? get winner => _winner;
  List<int> get winningLine => _winningLine;
  bool get isNetworkGame => _isNetworkGame;
  String get mySymbol => _mySymbol;
  
  bool get isMyTurn {
    if (!_isNetworkGame) return true;
    final currentSymbol = _isXTurn ? 'X' : 'O';
    return currentSymbol == _mySymbol;
  }

  void setupGame({required bool isNetwork, required String role}) {
    _isNetworkGame = isNetwork;
    _mySymbol = (role == 'host') ? 'X' : 'O';
    resetBoard(notify: false);
  }

  bool makeMove(int index) {
    if (_board[index] != '' || _winner != null || !isMyTurn) return false;

    final symbol = _isXTurn ? 'X' : 'O';
    _board[index] = symbol;
    _checkGameState();
    
    _isXTurn = !_isXTurn;
    notifyListeners();
    return true;
  }

  // Handle move received from network
  void handleNetworkMove(int index) {
    if (_board[index] != '' || _winner != null) return;
    
    final symbol = _isXTurn ? 'X' : 'O';
    _board[index] = symbol;
    _checkGameState();
    
    _isXTurn = !_isXTurn;
    notifyListeners();
  }

  void resetBoard({bool notify = true}) {
    _board = List.generate(9, (_) => '');
    _isXTurn = true;
    _winner = null;
    _winningLine = [];
    if (notify) notifyListeners();
  }

  void _checkGameState() {
    // Win combinations
    final wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6]            // Diagonals
    ];

    for (var line in wins) {
      final a = _board[line[0]];
      final b = _board[line[1]];
      final c = _board[line[2]];
      
      if (a != '' && a == b && a == c) {
        _winner = a;
        _winningLine = line;
        return;
      }
    }

    if (!_board.contains('')) {
      _winner = 'Draw';
    }
  }
}
