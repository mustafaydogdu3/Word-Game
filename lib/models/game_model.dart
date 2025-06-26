class WordPosition {
  final String word;
  final List<Position> positions;

  WordPosition({required this.word, required this.positions});
}

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}

class GameModel {
  List<String> letters;
  List<String> targetWords;
  List<String> foundWords;
  Map<String, List<Position>> wordPositions;
  List<List<String?>> grid;
  int currentLevel;
  String theme;

  GameModel({
    required this.letters,
    required this.targetWords,
    this.foundWords = const [],
    Map<String, List<Position>>? wordPositions,
    List<List<String?>>? grid,
    this.currentLevel = 1,
    this.theme = 'Basic Articles',
  }) : wordPositions = wordPositions ?? {},
       grid = grid ?? _generateGrid(targetWords);

  static List<List<String?>> _generateGrid(List<String> targetWords) {
    // Create 5x5 grid filled with nulls
    List<List<String?>> grid = List.generate(5, (_) => List.filled(5, null));

    // Fixed crossword pattern:
    //     ■     (row 0, col 2)
    //     ■     (row 1, col 2)
    // ■ ■ ■ ■   (row 2, cols 0-3)
    //       ■   (row 3, col 3)
    //       ■   (row 4, col 3)

    // Mark positions that should have squares
    // Vertical line at column 2 (rows 0-2)
    grid[0][2] = '';
    grid[1][2] = '';
    grid[2][2] = '';

    // Horizontal line at row 2 (cols 0-3)
    grid[2][0] = '';
    grid[2][1] = '';
    // grid[2][2] already set above
    grid[2][3] = '';

    // Vertical line at column 3 (rows 2-4)
    // grid[2][3] already set above
    grid[3][3] = '';
    grid[4][3] = '';

    // Vertical line at column 0 (rows 1-3) for 4th word
    grid[1][0] = '';
    grid[2][0] = ''; // already set above
    grid[3][0] = '';

    return grid;
  }

  GameModel copyWith({
    List<String>? letters,
    List<String>? targetWords,
    List<String>? foundWords,
    Map<String, List<Position>>? wordPositions,
    List<List<String?>>? grid,
    int? currentLevel,
    String? theme,
  }) {
    return GameModel(
      letters: letters ?? this.letters,
      targetWords: targetWords ?? this.targetWords,
      foundWords: foundWords ?? this.foundWords,
      wordPositions: wordPositions ?? this.wordPositions,
      grid: grid ?? this.grid,
      currentLevel: currentLevel ?? this.currentLevel,
      theme: theme ?? this.theme,
    );
  }

  bool get isCompleted => foundWords.length == targetWords.length;

  double get completionPercentage =>
      targetWords.isEmpty ? 0.0 : foundWords.length / targetWords.length;

  int get gridSize => 5; // Fixed 5x5 grid

  // Helper method to find positions for a specific word
  List<Position> getWordPositions(String word) {
    return wordPositions[word] ?? [];
  }

  // Helper to check if a position is valid
  bool isValidPosition(int row, int col) {
    return row >= 0 && row < gridSize && col >= 0 && col < gridSize;
  }
}
