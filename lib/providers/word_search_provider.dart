import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/word_search_generator.dart';

class WordSearchProvider extends ChangeNotifier {
  final List<String> _dictionary = [
    'FLUTTER', 'DART', 'PUZZLE', 'BOARD', 'CHESS',
    'SUDOKU', 'ARCADE', 'MINDFUL', 'GAMING', 'LOGIC',
    'SLIDE', 'MEMORY', 'SEARCH', 'MATRIX', 'MATCH'
  ];

  List<String> _grid = List.generate(100, (_) => '');
  List<String> _words = [];
  Map<String, List<int>> _wordLocations = {};
  
  final List<String> _foundWords = [];
  final Map<int, Color> _highlightedCells = {};
  bool _isLoading = false;

  List<String> get grid => _grid;
  List<String> get words => _words;
  Map<String, List<int>> get wordLocations => _wordLocations;
  List<String> get foundWords => _foundWords;
  Map<int, Color> get highlightedCells => _highlightedCells;
  bool get isLoading => _isLoading;

  Future<void> initBoard() async {
    _isLoading = true;
    _foundWords.clear();
    _highlightedCells.clear();
    notifyListeners();

    try {
      final data = await compute(generateWordSearchIsolate, _dictionary);
      _grid = data.grid;
      _words = data.words;
      _wordLocations = data.wordLocations;
    } catch (e) {
      debugPrint("Error generating Word Search: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setupNetworkBoard(List<String> gridData, List<String> wordsData, Map<String, List<int>> locations) {
    _grid = List<String>.from(gridData);
    _words = List<String>.from(wordsData);
    _wordLocations = Map<String, List<int>>.from(locations);
    _foundWords.clear();
    _highlightedCells.clear();
    _isLoading = false;
    notifyListeners();
  }

  // Check if a list of selected indices matches any remaining hidden word
  String? checkSelection(List<int> selected) {
    for (var word in _words) {
      if (_foundWords.contains(word)) continue;
      
      final locations = _wordLocations[word];
      if (locations == null) continue;

      // Check if indices match (either forward or backward)
      if (_matchIndices(selected, locations)) {
        return word;
      }
    }
    return null;
  }

  bool _matchIndices(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    
    // Check forward match
    bool forward = true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        forward = false;
        break;
      }
    }
    if (forward) return true;

    // Check backward match
    bool backward = true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[b.length - 1 - i]) {
        backward = false;
        break;
      }
    }
    return backward;
  }

  void markWordFound(String word, Color highlightColor) {
    if (_foundWords.contains(word)) return;
    
    _foundWords.add(word);
    final locations = _wordLocations[word];
    if (locations != null) {
      for (var idx in locations) {
        _highlightedCells[idx] = highlightColor;
      }
    }
    notifyListeners();
  }

  bool get isGameOver {
    if (_words.isEmpty) return false;
    return _foundWords.length == _words.length;
  }
}
