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
  List<List<String?>>
  grid; // Visual display only - not used for word validation
  int currentLevel;
  String theme;
  int gridRows; // Number of rows
  int gridCols; // Number of columns

  GameModel({
    required this.letters,
    required this.targetWords,
    this.foundWords = const [],
    Map<String, List<Position>>? wordPositions,
    List<List<String?>>? grid,
    this.currentLevel = 1,
    this.theme = 'Basic Articles',
    int? gridRows,
    int? gridCols,
  }) : wordPositions = wordPositions ?? {},
       gridRows = gridRows ?? 5,
       gridCols = gridCols ?? 5,
       grid =
           grid ??
           _generateGridFromPositions(
             targetWords,
             wordPositions ?? {},
             gridRows ?? 5,
             gridCols ?? 5,
           );

  static List<List<String?>> _generateGridFromPositions(
    List<String> targetWords,
    Map<String, List<Position>> wordPositions,
    int gridRows,
    int gridCols,
  ) {
    // Use exact grid size from JSON for manual placement
    final actualRows = gridRows;
    final actualCols = gridCols;

    // Create grid filled with nulls based on actual grid size
    List<List<String?>> grid = List.generate(
      actualRows,
      (_) => List.filled(actualCols, null),
    );

    // Place words on grid using positions from JSON
    for (String word in targetWords) {
      List<Position> positions = wordPositions[word] ?? [];
      for (int i = 0; i < positions.length && i < word.length; i++) {
        Position pos = positions[i];
        if (pos.row >= 0 &&
            pos.row < actualRows &&
            pos.col >= 0 &&
            pos.col < actualCols) {
          grid[pos.row][pos.col] = word[i]; // Place the actual letter
        }
      }
    }

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
    int? gridRows,
    int? gridCols,
  }) {
    return GameModel(
      letters: letters ?? this.letters,
      targetWords: targetWords ?? this.targetWords,
      foundWords: foundWords ?? this.foundWords,
      wordPositions: wordPositions ?? this.wordPositions,
      grid: grid ?? this.grid,
      currentLevel: currentLevel ?? this.currentLevel,
      theme: theme ?? this.theme,
      gridRows: gridRows ?? this.gridRows,
      gridCols: gridCols ?? this.gridCols,
    );
  }

  bool get isCompleted => foundWords.length == targetWords.length;

  double get completionPercentage =>
      targetWords.isEmpty ? 0.0 : foundWords.length / targetWords.length;

  // Helper method to find positions for a specific word
  List<Position> getWordPositions(String word) {
    return wordPositions[word] ?? [];
  }

  // Helper to check if a position is valid
  bool isValidPosition(int row, int col) {
    return row >= 0 && row < gridRows && col >= 0 && col < gridCols;
  }
}
