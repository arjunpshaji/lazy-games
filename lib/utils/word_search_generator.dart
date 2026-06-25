import 'dart:math';

class WordSearchData {
  final List<String> grid;
  final List<String> words;
  final Map<String, List<int>> wordLocations;

  WordSearchData({
    required this.grid,
    required this.words,
    required this.wordLocations,
  });
}

// Global top-level function that runs inside an Isolate via compute()
WordSearchData generateWordSearchIsolate(List<String> dictionary) {
  final random = Random();
  final int size = 10;
  final List<String> grid = List.generate(size * size, (_) => '');
  final Map<String, List<int>> wordLocations = {};
  
  // Shuffle dictionary and select 6 words
  final candidateWords = List<String>.from(dictionary)..shuffle();
  final List<String> selectedWords = [];
  
  final directions = [
    [0, 1],   // Horizontal Right
    [1, 0],   // Vertical Down
    [1, 1],   // Diagonal Down Right
    [-1, 1],  // Diagonal Up Right
    [0, -1],  // Horizontal Left
    [-1, 0],  // Vertical Up
  ];

  for (var word in candidateWords) {
    if (selectedWords.length >= 6) break;
    
    // Attempt to place word
    // Try random placements up to 100 times
    for (int attempt = 0; attempt < 100; attempt++) {
      final dir = directions[random.nextInt(directions.length)];
      final dRow = dir[0];
      final dCol = dir[1];
      
      final r = random.nextInt(size);
      final c = random.nextInt(size);
      
      // Check boundaries
      if (r + dRow * (word.length - 1) < 0 || r + dRow * (word.length - 1) >= size ||
          c + dCol * (word.length - 1) < 0 || c + dCol * (word.length - 1) >= size) {
        continue;
      }
      
      // Check overlaps
      bool ok = true;
      final currentWordIndices = <int>[];
      for (int i = 0; i < word.length; i++) {
        int nr = r + dRow * i;
        int nc = c + dCol * i;
        int idx = nr * size + nc;
        if (grid[idx] != '' && grid[idx] != word[i]) {
          ok = false;
          break;
        }
        currentWordIndices.add(idx);
      }
      
      if (ok) {
        // Place letters
        for (int i = 0; i < word.length; i++) {
          grid[currentWordIndices[i]] = word[i];
        }
        wordLocations[word] = currentWordIndices;
        selectedWords.add(word);
        break;
      }
    }
  }

  // Fill empty spots with random letters
  final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (int i = 0; i < size * size; i++) {
    if (grid[i] == '') {
      grid[i] = letters[random.nextInt(26)];
    }
  }

  return WordSearchData(
    grid: grid,
    words: selectedWords,
    wordLocations: wordLocations,
  );
}
