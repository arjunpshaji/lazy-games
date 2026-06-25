import 'dart:math';

class SudokuBoardData {
  final List<int> puzzle;
  final List<int> solution;

  SudokuBoardData({required this.puzzle, required this.solution});
}

// Global top-level function that runs inside an Isolate via compute()
SudokuBoardData generateSudokuIsolate(String difficulty) {
  final solver = SudokuGenerator();
  solver.fillValues();
  final solution = List<int>.from(solver.mat);
  
  int removeCount = 40;
  if (difficulty == 'Medium') {
    removeCount = 48;
  } else if (difficulty == 'Hard') {
    removeCount = 54;
  }
  
  solver.removeKDigits(removeCount);
  final puzzle = List<int>.from(solver.mat);
  
  return SudokuBoardData(puzzle: puzzle, solution: solution);
}

class SudokuGenerator {
  late List<int> mat;
  final int N = 9;
  final int SRN = 3;

  SudokuGenerator() {
    mat = List.generate(81, (_) => 0);
  }

  void fillValues() {
    fillDiagonal();
    fillRemaining(0, SRN);
  }

  void fillDiagonal() {
    for (int i = 0; i < N; i += SRN) {
      fillBox(i, i);
    }
  }

  bool unUsedInBox(int rowStart, int colStart, int num) {
    for (int i = 0; i < SRN; i++) {
      for (int j = 0; j < SRN; j++) {
        if (mat[(rowStart + i) * 9 + (colStart + j)] == num) {
          return false;
        }
      }
    }
    return true;
  }

  void fillBox(int row, int col) {
    int num;
    final random = Random();
    for (int i = 0; i < SRN; i++) {
      for (int j = 0; j < SRN; j++) {
        do {
          num = random.nextInt(9) + 1;
        } while (!unUsedInBox(row, col, num));
        mat[(row + i) * 9 + (col + j)] = num;
      }
    }
  }

  bool checkIfSafe(int i, int j, int num) {
    return (unUsedInRow(i, num) &&
        unUsedInCol(j, num) &&
        unUsedInBox(i - i % SRN, j - j % SRN, num));
  }

  bool unUsedInRow(int i, int num) {
    for (int j = 0; j < N; j++) {
      if (mat[i * 9 + j] == num) {
        return false;
      }
    }
    return true;
  }

  bool unUsedInCol(int j, int num) {
    for (int i = 0; i < N; i++) {
      if (mat[i * 9 + j] == num) {
        return false;
      }
    }
    return true;
  }

  bool fillRemaining(int i, int j) {
    if (j >= N && i < N - 1) {
      i = i + 1;
      j = 0;
    }
    if (i >= N && j >= N) {
      return true;
    }

    if (i < SRN) {
      if (j < SRN) {
        j = SRN;
      }
    } else if (i < N - SRN) {
      if (j == (i ~/ SRN) * SRN) {
        j = j + SRN;
      }
    } else {
      if (j == N - SRN) {
        i = i + 1;
        j = 0;
        if (i >= N) {
          return true;
        }
      }
    }

    for (int num = 1; num <= N; num++) {
      if (checkIfSafe(i, j, num)) {
        mat[i * 9 + j] = num;
        if (fillRemaining(i, j + 1)) {
          return true;
        }
        mat[i * 9 + j] = 0;
      }
    }
    return false;
  }

  void removeKDigits(int count) {
    int k = count;
    final random = Random();
    while (k != 0) {
      int cellId = random.nextInt(81);
      if (mat[cellId] != 0) {
        k--;
        mat[cellId] = 0;
      }
    }
  }
}
