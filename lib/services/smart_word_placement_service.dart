import 'dart:math';

class SmartWordPlacement {
  final String word;
  final List<Position> positions;
  final bool isHorizontal;

  SmartWordPlacement({
    required this.word,
    required this.positions,
    required this.isHorizontal,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'positions': positions.map((p) => p.toJson()).toList(),
    };
  }
}

class Position {
  final int row;
  final int col;

  Position({required this.row, required this.col});

  Map<String, dynamic> toJson() {
    return {'row': row, 'col': col};
  }

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

class SmartWordPlacementService {
  static const int maxGridSize = 50; // Increased for dynamic sizing
  static const int padding = 2; // Padding around the grid

  /// Generates smart word placements with dynamic grid sizing and intersection-based placement
  static Map<String, dynamic> generateSmartPlacements({
    required List<String> words,
    required List<String> letters,
  }) {
    if (words.isEmpty) {
      return {
        'placements': {},
        'grid': [],
        'gridSize': {'rows': 0, 'cols': 0},
        'intersections': [],
      };
    }

    // Calculate optimal grid size based on word lengths and count
    List<int> gridSize = _calculateOptimalGridSize(words, letters);
    print('Calculated optimal grid size: ${gridSize[0]}x${gridSize[1]}');

    // Initialize grid
    List<List<String?>> grid = List.generate(
      gridSize[0],
      (index) => List.generate(gridSize[1], (index) => null),
    );

    Map<String, SmartWordPlacement> placements = {};
    Map<String, List<Position>> wordPositions = {};
    List<Map<String, dynamic>> intersections = [];

    // Find the best anchor word (word with most intersection potential)
    String anchorWord = _findBestAnchorWord(words);
    print('Selected anchor word: $anchorWord');

    // Place anchor word at optimal position
    _placeAnchorWord(anchorWord, grid, placements, wordPositions, gridSize);
    print('Anchor word placed');

    // Place remaining words using intersection-based placement
    List<String> remainingWords = words.where((w) => w != anchorWord).toList();
    for (String word in remainingWords) {
      bool placed = _placeWordWithIntersections(
        word,
        grid,
        placements,
        wordPositions,
        intersections,
        gridSize,
      );

      if (!placed) {
        // Fallback: place in empty space
        placed = _placeWordInEmptySpace(
          word,
          grid,
          placements,
          wordPositions,
          gridSize,
        );
        print('Word "$word" placed in empty space (fallback)');
      } else {
        print('Word "$word" placed with intersection');
      }

      if (!placed) {
        print('Warning: Could not place word "$word"');
      }
    }

    // Find actual grid bounds and compact
    Map<String, dynamic> compacted = _compactGrid(
      grid,
      placements,
      intersections,
    );

    print(
      'Smart placement completed. Final grid size: ${compacted['gridSize']['rows']}x${compacted['gridSize']['cols']}',
    );
    print('Total intersections found: ${compacted['intersections'].length}');

    return compacted;
  }

  /// Calculate grid size based on letter count: gridSize = letter count + 1
  static List<int> _calculateOptimalGridSize(
    List<String> words,
    List<String> letters,
  ) {
    int letterCount = letters.length;
    int gridSize = letterCount + 1;
    return [gridSize, gridSize]; // Square grid
  }

  /// Finds the best anchor word based on intersection potential
  static String _findBestAnchorWord(List<String> words) {
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0];

    // Calculate intersection potential for each word
    Map<String, int> intersectionScores = {};

    for (String word in words) {
      int score = 0;

      // Score based on word length (longer words have more intersection points)
      score += word.length * 2;

      // Score based on common letters with other words
      for (String otherWord in words) {
        if (word != otherWord) {
          Set<String> wordLetters = word.split('').toSet();
          Set<String> otherLetters = otherWord.split('').toSet();
          int commonLetters = wordLetters.intersection(otherLetters).length;
          score += commonLetters * 3;
        }
      }

      intersectionScores[word] = score;
    }

    // Return word with highest intersection potential
    String bestWord = intersectionScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    print('Intersection scores: $intersectionScores');
    print(
      'Best anchor word: $bestWord (score: ${intersectionScores[bestWord]})',
    );

    return bestWord;
  }

  /// Places the anchor word horizontally in the center
  static void _placeAnchorWord(
    String word,
    List<List<String?>> grid,
    Map<String, SmartWordPlacement> placements,
    Map<String, List<Position>> wordPositions,
    List<int> gridSize,
  ) {
    int centerRow = gridSize[0] ~/ 2;
    int centerCol = gridSize[1] ~/ 2;

    // Calculate starting position to center the word horizontally
    int startRow = centerRow;
    int startCol = centerCol - (word.length ~/ 2);

    // Ensure word fits within grid bounds
    if (startCol < 0) startCol = 0;
    if (startCol + word.length > gridSize[1]) {
      startCol = gridSize[1] - word.length;
    }

    List<Position> positions = [];
    for (int i = 0; i < word.length; i++) {
      Position pos = Position(row: startRow, col: startCol + i);
      positions.add(pos);
      grid[startRow][startCol + i] = word[i];
    }

    placements[word] = SmartWordPlacement(
      word: word,
      positions: positions,
      isHorizontal: true,
    );
    wordPositions[word] = positions;

    print('Anchor word "$word" placed at row $startRow, col $startCol');
  }

  /// Attempts to place a word by intersecting with already placed words
  static bool _placeWordWithIntersections(
    String word,
    List<List<String?>> grid,
    Map<String, SmartWordPlacement> placements,
    Map<String, List<Position>> wordPositions,
    List<Map<String, dynamic>> intersections,
    List<int> gridSize,
  ) {
    // Try to intersect with each already placed word
    for (String placedWord in placements.keys) {
      SmartWordPlacement placedPlacement = placements[placedWord]!;

      // Find potential intersections
      List<Map<String, dynamic>> potentialIntersections =
          _findPotentialIntersections(word, placedWord, placedPlacement);

      // Try each potential intersection
      for (Map<String, dynamic> intersection in potentialIntersections) {
        SmartWordPlacement? newPlacement = _tryPlacementWithIntersection(
          word,
          placedWord,
          intersection,
          grid,
          gridSize,
          placements,
        );

        if (newPlacement != null) {
          // Placement successful
          placements[word] = newPlacement;
          wordPositions[word] = newPlacement.positions;

          // Update grid
          for (int i = 0; i < word.length; i++) {
            Position pos = newPlacement.positions[i];
            grid[pos.row][pos.col] = word[i];
          }

          // Record intersection
          intersections.add({
            'words': [word, placedWord],
            'commonLetter': intersection['commonLetter'],
            'positionInFirst': intersection['positionInFirst'],
            'positionInSecond': intersection['positionInSecond'],
          });

          return true;
        }
      }
    }

    return false;
  }

  /// Finds potential intersections between two words
  static List<Map<String, dynamic>> _findPotentialIntersections(
    String word1,
    String word2,
    SmartWordPlacement placement2,
  ) {
    List<Map<String, dynamic>> intersections = [];

    for (int i = 0; i < word1.length; i++) {
      for (int j = 0; j < word2.length; j++) {
        if (word1[i] == word2[j]) {
          intersections.add({
            'commonLetter': word1[i],
            'positionInFirst': i,
            'positionInSecond': j,
          });
        }
      }
    }

    return intersections;
  }

  /// Tries to place a word at a specific intersection
  static SmartWordPlacement? _tryPlacementWithIntersection(
    String word,
    String placedWord,
    Map<String, dynamic> intersection,
    List<List<String?>> grid,
    List<int> gridSize,
    Map<String, SmartWordPlacement> placements,
  ) {
    int wordPos = intersection['positionInFirst'];
    int placedPos = intersection['positionInSecond'];
    String commonLetter = intersection['commonLetter'];

    // Get the position of the intersection point
    SmartWordPlacement? placedPlacement = placements[placedWord];
    if (placedPlacement == null) return null;

    Position intersectionPoint = placedPlacement.positions[placedPos];

    // Calculate new word positions
    List<Position> newPositions = [];
    bool newWordIsHorizontal = !placedPlacement.isHorizontal;

    if (newWordIsHorizontal) {
      // Place horizontally
      int startCol = intersectionPoint.col - wordPos;
      for (int i = 0; i < word.length; i++) {
        Position pos = Position(row: intersectionPoint.row, col: startCol + i);
        newPositions.add(pos);
      }
    } else {
      // Place vertically
      int startRow = intersectionPoint.row - wordPos;
      for (int i = 0; i < word.length; i++) {
        Position pos = Position(row: startRow + i, col: intersectionPoint.col);
        newPositions.add(pos);
      }
    }

    // Validate placement
    if (_isValidPlacement(newPositions, word, grid, gridSize)) {
      return SmartWordPlacement(
        word: word,
        positions: newPositions,
        isHorizontal: newWordIsHorizontal,
      );
    }

    return null;
  }

  /// Places a word in empty space as fallback
  static bool _placeWordInEmptySpace(
    String word,
    List<List<String?>> grid,
    Map<String, SmartWordPlacement> placements,
    Map<String, List<Position>> wordPositions,
    List<int> gridSize,
  ) {
    // Try horizontal placement first
    for (int row = 0; row < gridSize[0]; row++) {
      for (int col = 0; col <= gridSize[1] - word.length; col++) {
        List<Position> positions = [];
        for (int i = 0; i < word.length; i++) {
          positions.add(Position(row: row, col: col + i));
        }

        if (_isValidPlacement(positions, word, grid, gridSize)) {
          _applyPlacement(
            word,
            positions,
            true,
            grid,
            placements,
            wordPositions,
          );
          return true;
        }
      }
    }

    // Try vertical placement
    for (int row = 0; row <= gridSize[0] - word.length; row++) {
      for (int col = 0; col < gridSize[1]; col++) {
        List<Position> positions = [];
        for (int i = 0; i < word.length; i++) {
          positions.add(Position(row: row + i, col: col));
        }

        if (_isValidPlacement(positions, word, grid, gridSize)) {
          _applyPlacement(
            word,
            positions,
            false,
            grid,
            placements,
            wordPositions,
          );
          return true;
        }
      }
    }

    return false;
  }

  /// Validates if a placement is valid
  static bool _isValidPlacement(
    List<Position> positions,
    String word,
    List<List<String?>> grid,
    List<int> gridSize,
  ) {
    for (int i = 0; i < positions.length; i++) {
      Position pos = positions[i];

      // Check bounds
      if (pos.row < 0 ||
          pos.row >= gridSize[0] ||
          pos.col < 0 ||
          pos.col >= gridSize[1]) {
        return false;
      }

      // Check for conflicts
      String? existingLetter = grid[pos.row][pos.col];
      if (existingLetter != null && existingLetter != word[i]) {
        return false;
      }
    }

    return true;
  }

  /// Applies a placement to the grid and tracking structures
  static void _applyPlacement(
    String word,
    List<Position> positions,
    bool isHorizontal,
    List<List<String?>> grid,
    Map<String, SmartWordPlacement> placements,
    Map<String, List<Position>> wordPositions,
  ) {
    placements[word] = SmartWordPlacement(
      word: word,
      positions: positions,
      isHorizontal: isHorizontal,
    );
    wordPositions[word] = positions;

    // Update grid
    for (int i = 0; i < word.length; i++) {
      Position pos = positions[i];
      grid[pos.row][pos.col] = word[i];
    }
  }

  /// Compacts the grid to remove empty space and adjusts positions
  static Map<String, dynamic> _compactGrid(
    List<List<String?>> grid,
    Map<String, SmartWordPlacement> placements,
    List<Map<String, dynamic>> intersections,
  ) {
    // Find bounds
    int minRow = maxGridSize, maxRow = 0, minCol = maxGridSize, maxCol = 0;
    bool hasContent = false;

    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        if (grid[row][col] != null) {
          minRow = min(minRow, row);
          maxRow = max(maxRow, row);
          minCol = min(minCol, col);
          maxCol = max(maxCol, col);
          hasContent = true;
        }
      }
    }

    if (!hasContent) {
      return {
        'placements': {},
        'grid': [],
        'gridSize': {'rows': 0, 'cols': 0},
        'intersections': [],
      };
    }

    // Create compact grid
    List<List<String?>> compactGrid = [];
    for (int row = minRow; row <= maxRow; row++) {
      List<String?> rowData = [];
      for (int col = minCol; col <= maxCol; col++) {
        rowData.add(grid[row][col]);
      }
      compactGrid.add(rowData);
    }

    // Adjust positions
    Map<String, List<Map<String, int>>> adjustedPlacements = {};
    for (String word in placements.keys) {
      List<Map<String, int>> adjustedPositions = [];
      for (Position pos in placements[word]!.positions) {
        adjustedPositions.add({
          'row': pos.row - minRow,
          'col': pos.col - minCol,
        });
      }
      adjustedPlacements[word] = adjustedPositions;
    }

    return {
      'placements': adjustedPlacements,
      'grid': compactGrid,
      'gridSize': {'rows': maxRow - minRow + 1, 'cols': maxCol - minCol + 1},
      'intersections': intersections,
    };
  }
}
