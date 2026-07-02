import 'dart:async';
import 'package:flutter/material.dart';

enum MemoryDifficulty { easy, medium, high }

class MemoryMatchProvider extends ChangeNotifier {
  List<int> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];

  int _player1Score = 0; // Host or Local Player 1
  int _player2Score = 0; // Client or Local Player 2
  bool _isPlayer1Turn = true; // Whose turn

  List<int> _selectedIndices = [];
  bool _isWaiting = false; // Disable clicks during flip delay

  bool _isNetworkGame = false;
  String _myRole = 'host'; // 'host' or 'client'
  bool _isSolo = false;
  int _moves = 0;
  // Cached matched groups count — O(1) check instead of scanning bools each build.
  int _matchedPairCount = 0;

  MemoryDifficulty _difficulty = MemoryDifficulty.easy;

  int _gameSessionId = 0;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_isDisposed) return;
    notifyListeners();
  }

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
  MemoryDifficulty get difficulty => _difficulty;

  /// Number of columns in the grid for the current difficulty.
  int get gridColumns {
    switch (_difficulty) {
      case MemoryDifficulty.easy:
        return 4;
      case MemoryDifficulty.medium:
        return 6;
      case MemoryDifficulty.high:
        return 7;
    }
  }

  /// How many cards form a valid match group (2 = pairs, 3 = triplets).
  int get matchGroupSize => _difficulty == MemoryDifficulty.high ? 3 : 2;

  /// Total number of cards in the current grid (including the blank for Hard).
  int get totalCards => _cards.length;

  /// Number of groups that must be matched to complete the game.
  int get _numGroups {
    switch (_difficulty) {
      case MemoryDifficulty.easy:
        return 8; // 8 pairs = 16 cards
      case MemoryDifficulty.medium:
        return 18; // 18 pairs = 36 cards
      case MemoryDifficulty.high:
        return 16; // 16 triplets = 48 cards + 1 blank = 49 total
    }
  }

  bool get isMyTurn {
    if (_isSolo) return true;
    if (!_isNetworkGame) return true;
    return (_myRole == 'host' && _isPlayer1Turn) ||
        (_myRole == 'client' && !_isPlayer1Turn);
  }

  /// Infers difficulty from a card list length (used by network client).
  static MemoryDifficulty difficultyFromCardCount(int count) {
    if (count >= 49) return MemoryDifficulty.high;
    if (count >= 36) return MemoryDifficulty.medium;
    return MemoryDifficulty.easy;
  }

  /// Generate a shuffled card list for the given difficulty.
  List<int> generateCards() {
    final groupSize = matchGroupSize;
    final numGroups = _numGroups;
    final List<int> cards = [];
    for (int i = 0; i < numGroups; i++) {
      for (int j = 0; j < groupSize; j++) {
        cards.add(i);
      }
    }
    cards.shuffle();

    // High mode: pad to 49 cells with a blank card (-1) at a random position.
    if (_difficulty == MemoryDifficulty.high) {
      cards.add(-1);
      cards.shuffle();
    }

    return cards;
  }

  void setupGame({
    required bool isNetwork,
    required String role,
    bool isSolo = false,
    MemoryDifficulty difficulty = MemoryDifficulty.easy,
    List<int>? preShuffledCards,
  }) {
    _gameSessionId++;
    _isNetworkGame = isNetwork;
    _myRole = role;
    _isSolo = isSolo;
    _player1Score = 0;
    _player2Score = 0;
    _moves = 0;
    _isPlayer1Turn = true;
    _selectedIndices = [];
    _isWaiting = false;
    _matchedPairCount = 0;

    if (preShuffledCards != null) {
      _cards = List<int>.from(preShuffledCards);
      // Infer difficulty from card count when receiving from network.
      _difficulty = difficultyFromCardCount(_cards.length);
    } else {
      _difficulty = difficulty;
      _cards = generateCards();
    }

    _flipped = List.generate(_cards.length, (_) => false);
    _matched = List.generate(_cards.length, (_) => false);

    notifyListeners();
  }

  // Evaluate whether the currently selected group is a match.
  Future<void> _evaluateMatch(List<int> indices, int sessionId) async {
    final firstValue = _cards[indices[0]];
    final isMatch = indices.every((i) => _cards[i] == firstValue);

    if (isMatch) {
      // MATCH!
      await Future.delayed(const Duration(milliseconds: 600));
      if (sessionId != _gameSessionId || _isDisposed) return;

      for (final i in indices) {
        _matched[i] = true;
      }
      _matchedPairCount++;

      if (_isSolo) {
        _player1Score++;
      } else if (_isPlayer1Turn) {
        _player1Score++;
      } else {
        _player2Score++;
      }

      _selectedIndices.clear();
      _isWaiting = false;
      _safeNotify();
    } else {
      // NO MATCH!
      await Future.delayed(const Duration(milliseconds: 1000));
      if (sessionId != _gameSessionId || _isDisposed) return;

      for (final i in indices) {
        _flipped[i] = false;
      }

      if (!_isSolo) {
        _isPlayer1Turn = !_isPlayer1Turn;
      }
      _selectedIndices.clear();
      _isWaiting = false;
      _safeNotify();
    }
  }

  // Handle local tap
  Future<bool> handleCardTap(int index) async {
    if (_isWaiting || _flipped[index] || _matched[index] || !isMyTurn) {
      return false;
    }
    // Guard: blank cell in hard mode
    if (index < _cards.length && _cards[index] == -1) return false;
    if (_selectedIndices.length >= matchGroupSize) return false;

    _flipped[index] = true;
    _selectedIndices.add(index);
    notifyListeners();

    if (_selectedIndices.length == matchGroupSize) {
      _isWaiting = true;
      notifyListeners();

      final indices = List<int>.from(_selectedIndices);

      if (_isSolo) {
        _moves++;
      }

      _evaluateMatch(indices, _gameSessionId);
    }

    return true;
  }

  // Network sync — opponent's tap arrives here
  Future<void> handleNetworkTap(int index) async {
    // Guard: if evaluation is in-flight, drop incoming tap to prevent corruption.
    if (_isWaiting || _flipped[index] || _matched[index]) return;
    // Guard: blank cell in hard mode
    if (index < _cards.length && _cards[index] == -1) return;

    _flipped[index] = true;
    _selectedIndices.add(index);
    notifyListeners();

    if (_selectedIndices.length == matchGroupSize) {
      _isWaiting = true;
      notifyListeners();

      final indices = List<int>.from(_selectedIndices);
      _evaluateMatch(indices, _gameSessionId);
    }
  }

  // O(1) check — avoids scanning all bools on every build.
  // Guard against empty cards (client waiting for host sync).
  bool get isGameOver =>
      _cards.isNotEmpty && _matchedPairCount >= _numGroups;
}
