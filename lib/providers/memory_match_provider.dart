import 'dart:async';
import 'package:flutter/material.dart';

class MemoryMatchProvider extends ChangeNotifier {
  List<int> _cards = []; // Identifiers for cards 0-7 (each twice)
  List<bool> _flipped = List.generate(16, (_) => false);
  List<bool> _matched = List.generate(16, (_) => false);
  
  int _player1Score = 0; // Host or Local Player 1
  int _player2Score = 0; // Client or Local Player 2
  bool _isPlayer1Turn = true; // Whose turn
  
  List<int> _selectedIndices = [];
  bool _isWaiting = false; // Disable clicks during flip delay

  bool _isNetworkGame = false;
  String _myRole = 'host'; // 'host' or 'client'
  bool _isSolo = false;
  int _moves = 0;

  List<int> get cards => _cards;
  List<bool> get flipped => _flipped;
  List<bool> get matched => _matched;
  int get player1Score => _player1Score;
  int get player2Score => _player2Score;
  bool get isPlayer1Turn => _isPlayer1Turn;
  bool get isWaiting => _isWaiting;
  bool get isNetworkGame => _isNetworkGame;
  String get myRole => _myRole;
  bool get isSolo => _isSolo;
  int get moves => _moves;

  bool get isMyTurn {
    if (_isSolo) return true;
    if (!_isNetworkGame) return true;
    return (_myRole == 'host' && _isPlayer1Turn) || (_myRole == 'client' && !_isPlayer1Turn);
  }

  void setupGame({required bool isNetwork, required String role, bool isSolo = false, List<int>? preShuffledCards}) {
    _isNetworkGame = isNetwork;
    _myRole = role;
    _isSolo = isSolo;
    _player1Score = 0;
    _player2Score = 0;
    _moves = 0;
    _isPlayer1Turn = true;
    _selectedIndices = [];
    _isWaiting = false;
    _flipped = List.generate(16, (_) => false);
    _matched = List.generate(16, (_) => false);

    if (preShuffledCards != null) {
      _cards = List<int>.from(preShuffledCards);
    } else {
      // Local setup: Generate and shuffle 8 pairs
      _cards = List.generate(8, (i) => i) + List.generate(8, (i) => i);
      _cards.shuffle();
    }
    notifyListeners();
  }

  // Handle tap
  Future<bool> handleCardTap(int index) async {
    if (_isWaiting || _flipped[index] || _matched[index] || !isMyTurn) return false;
    if (_selectedIndices.length >= 2) return false;

    _flipped[index] = true;
    _selectedIndices.add(index);
    notifyListeners();

    if (_selectedIndices.length == 2) {
      _isWaiting = true;
      notifyListeners();
      
      final first = _selectedIndices[0];
      final second = _selectedIndices[1];
      
      if (_isSolo) {
        _moves++;
      }
      
      if (_cards[first] == _cards[second]) {
        // MATCH!
        await Future.delayed(const Duration(milliseconds: 600));
        _matched[first] = true;
        _matched[second] = true;
        
        if (_isSolo) {
          _player1Score++;
        } else if (_isPlayer1Turn) {
          _player1Score++;
        } else {
          _player2Score++;
        }
        
        _selectedIndices.clear();
        _isWaiting = false;
        notifyListeners();
      } else {
        // NO MATCH!
        await Future.delayed(const Duration(milliseconds: 1000));
        _flipped[first] = false;
        _flipped[second] = false;
        
        if (!_isSolo) {
          _isPlayer1Turn = !_isPlayer1Turn;
        }
        _selectedIndices.clear();
        _isWaiting = false;
        notifyListeners();
      }
    }
    
    return true;
  }

  // Network sync
  Future<void> handleNetworkTap(int index) async {
    if (_flipped[index] || _matched[index]) return;
    
    _flipped[index] = true;
    _selectedIndices.add(index);
    notifyListeners();

    if (_selectedIndices.length == 2) {
      _isWaiting = true;
      notifyListeners();
      
      final first = _selectedIndices[0];
      final second = _selectedIndices[1];
      
      if (_cards[first] == _cards[second]) {
        await Future.delayed(const Duration(milliseconds: 600));
        _matched[first] = true;
        _matched[second] = true;
        
        if (_isPlayer1Turn) {
          _player1Score++;
        } else {
          _player2Score++;
        }
        
        _selectedIndices.clear();
        _isWaiting = false;
        notifyListeners();
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));
        _flipped[first] = false;
        _flipped[second] = false;
        
        _isPlayer1Turn = !_isPlayer1Turn;
        _selectedIndices.clear();
        _isWaiting = false;
        notifyListeners();
      }
    }
  }

  bool get isGameOver {
    return !_matched.contains(false);
  }
}
