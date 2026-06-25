import 'dart:math';
import 'package:flutter/material.dart';

class Game2048Provider extends ChangeNotifier {
  List<int> _board = List.generate(16, (_) => 0);
  int _score = 0;
  int _opponentScore = 0;
  bool _isGameOver = false;
  bool _isWon = false;
  
  List<int> get board => _board;
  int get score => _score;
  int get opponentScore => _opponentScore;
  bool get isGameOver => _isGameOver;
  bool get isWon => _isWon;

  void setupGame() {
    _board = List.generate(16, (_) => 0);
    _score = 0;
    _opponentScore = 0;
    _isGameOver = false;
    _isWon = false;
    _spawnTile();
    _spawnTile();
    notifyListeners();
  }

  void updateOpponentScore(int score) {
    _opponentScore = score;
    notifyListeners();
  }

  void handleSwipe(String direction) {
    if (_isGameOver) return;

    bool moved = false;
    switch (direction) {
      case 'left':
        moved = _slideLeft();
        break;
      case 'right':
        moved = _slideRight();
        break;
      case 'up':
        moved = _slideUp();
        break;
      case 'down':
        moved = _slideDown();
        break;
    }

    if (moved) {
      _spawnTile();
      _checkGameOver();
      notifyListeners();
    }
  }

  void _spawnTile() {
    final emptyIndices = <int>[];
    for (int i = 0; i < 16; i++) {
      if (_board[i] == 0) emptyIndices.add(i);
    }

    if (emptyIndices.isNotEmpty) {
      final randIdx = emptyIndices[Random().nextInt(emptyIndices.length)];
      _board[randIdx] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  bool _slideLeft() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> row = [_board[r * 4], _board[r * 4 + 1], _board[r * 4 + 2], _board[r * 4 + 3]];
      final result = _merge(row);
      if (!_listEquals(row, result.newRow)) moved = true;
      _score += result.pointsAdded;
      for (int c = 0; c < 4; c++) {
        _board[r * 4 + c] = result.newRow[c];
      }
    }
    return moved;
  }

  bool _slideRight() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> row = [_board[r * 4 + 3], _board[r * 4 + 2], _board[r * 4 + 1], _board[r * 4]];
      final result = _merge(row);
      if (!_listEquals(row, result.newRow)) moved = true;
      _score += result.pointsAdded;
      for (int c = 0; c < 4; c++) {
        _board[r * 4 + 3 - c] = result.newRow[c];
      }
    }
    return moved;
  }

  bool _slideUp() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [_board[c], _board[4 + c], _board[8 + c], _board[12 + c]];
      final result = _merge(col);
      if (!_listEquals(col, result.newRow)) moved = true;
      _score += result.pointsAdded;
      for (int r = 0; r < 4; r++) {
        _board[r * 4 + c] = result.newRow[r];
      }
    }
    return moved;
  }

  bool _slideDown() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [_board[12 + c], _board[8 + c], _board[4 + c], _board[c]];
      final result = _merge(col);
      if (!_listEquals(col, result.newRow)) moved = true;
      _score += result.pointsAdded;
      for (int r = 0; r < 4; r++) {
        _board[(3 - r) * 4 + c] = result.newRow[r];
      }
    }
    return moved;
  }

  _MergeResult _merge(List<int> line) {
    // 1. Shift non-zero tiles
    final nonZeros = line.where((val) => val != 0).toList();
    final newRow = List<int>.generate(4, (_) => 0);
    int pointsAdded = 0;

    int writeIdx = 0;
    int readIdx = 0;
    while (readIdx < nonZeros.length) {
      if (readIdx + 1 < nonZeros.length && nonZeros[readIdx] == nonZeros[readIdx + 1]) {
        // Merge
        final mergedVal = nonZeros[readIdx] * 2;
        newRow[writeIdx] = mergedVal;
        pointsAdded += mergedVal;
        if (mergedVal == 2048) _isWon = true;
        readIdx += 2;
      } else {
        newRow[writeIdx] = nonZeros[readIdx];
        readIdx++;
      }
      writeIdx++;
    }

    return _MergeResult(newRow: newRow, pointsAdded: pointsAdded);
  }

  bool _listEquals(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _checkGameOver() {
    if (_board.contains(0)) return;

    // Check adjacent matches
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final val = _board[r * 4 + c];
        // Right
        if (c + 1 < 4 && _board[r * 4 + c + 1] == val) return;
        // Down
        if (r + 1 < 4 && _board[(r + 1) * 4 + c] == val) return;
      }
    }

    _isGameOver = true;
  }
}

class _MergeResult {
  final List<int> newRow;
  final int pointsAdded;
  _MergeResult({required this.newRow, required this.pointsAdded});
}
