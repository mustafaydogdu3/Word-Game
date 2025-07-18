import 'dart:math';

class WordPlacement {
  final String word;
  final List<Position> positions;
  final bool isHorizontal;

  WordPlacement({
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
}

class Intersection {
  final List<String> words;
  final String commonLetter;
  final int positionInFirst;
  final int positionInSecond;

  Intersection({
    required this.words,
    required this.commonLetter,
    required this.positionInFirst,
    required this.positionInSecond,
  });

  factory Intersection.fromJson(Map<String, dynamic> json) {
    return Intersection(
      words: List<String>.from(json['words']),
      commonLetter: json['commonLetter'],
      positionInFirst: json['positionInFirst'],
      positionInSecond: json['positionInSecond'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'words': words,
      'commonLetter': commonLetter,
      'positionInFirst': positionInFirst,
      'positionInSecond': positionInSecond,
    };
  }
}

class WordPlacementService {
  static const int maxGridSize = 20;

  static Map<String, dynamic> generateWordPlacements({
    required List<String> words,
    required List<Intersection> intersections,
  }) {
    // Initialize grid
    List<List<String?>> grid = List.generate(
      maxGridSize,
      (index) => List.generate(maxGridSize, (index) => null),
    );

    Map<String, WordPlacement> placements = {};
    Map<String, List<Position>> wordPositions = {};

    // Place first word horizontally at (0,0)
    if (words.isNotEmpty) {
      String firstWord = words[0];
      List<Position> positions = [];

      for (int i = 0; i < firstWord.length; i++) {
        Position pos = Position(row: 0, col: i);
        positions.add(pos);
        grid[0][i] = firstWord[i];
      }

      placements[firstWord] = WordPlacement(
        word: firstWord,
        positions: positions,
        isHorizontal: true,
      );
      wordPositions[firstWord] = positions;
    }

    // Place remaining words based on intersections
    for (int wordIndex = 1; wordIndex < words.length; wordIndex++) {
      String currentWord = words[wordIndex];
      bool placed = false;

      // Try to place word using intersections
      for (Intersection intersection in intersections) {
        if (intersection.words.contains(currentWord)) {
          String otherWord = intersection.words.firstWhere(
            (w) => w != currentWord,
          );

          // Check if the other word is already placed
          if (wordPositions.containsKey(otherWord)) {
            WordPlacement? placement = _placeWordWithIntersection(
              currentWord,
              otherWord,
              intersection,
              wordPositions[otherWord]!,
              placements[otherWord]!.isHorizontal,
              grid,
            );

            if (placement != null) {
              placements[currentWord] = placement;
              wordPositions[currentWord] = placement.positions;

              // Update grid
              for (int i = 0; i < currentWord.length; i++) {
                Position pos = placement.positions[i];
                grid[pos.row][pos.col] = currentWord[i];
              }

              placed = true;
              break;
            }
          }
        }
      }

      // If couldn't place with intersection, place in empty space
      if (!placed) {
        WordPlacement? placement = _placeWordInEmptySpace(currentWord, grid);

        if (placement != null) {
          placements[currentWord] = placement;
          wordPositions[currentWord] = placement.positions;

          // Update grid
          for (int i = 0; i < currentWord.length; i++) {
            Position pos = placement.positions[i];
            grid[pos.row][pos.col] = currentWord[i];
          }
        }
      }
    }

    // Find actual grid bounds
    int minRow = 0, maxRow = 0, minCol = 0, maxCol = 0;
    bool firstCell = true;

    for (int row = 0; row < maxGridSize; row++) {
      for (int col = 0; col < maxGridSize; col++) {
        if (grid[row][col] != null) {
          if (firstCell) {
            minRow = maxRow = row;
            minCol = maxCol = col;
            firstCell = false;
          } else {
            minRow = min(minRow, row);
            maxRow = max(maxRow, row);
            minCol = min(minCol, col);
            maxCol = max(maxCol, col);
          }
        }
      }
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

    // Adjust positions to start from (0,0)
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
    };
  }

  static WordPlacement? _placeWordWithIntersection(
    String word,
    String placedWord,
    Intersection intersection,
    List<Position> placedWordPositions,
    bool placedWordIsHorizontal,
    List<List<String?>> grid,
  ) {
    // Determine which word is first and second in intersection
    bool wordIsFirst = intersection.words[0] == word;
    int wordIntersectionPos = wordIsFirst
        ? intersection.positionInFirst
        : intersection.positionInSecond;
    int placedWordIntersectionPos = wordIsFirst
        ? intersection.positionInSecond
        : intersection.positionInFirst;

    // Get intersection position from placed word
    Position intersectionPos = placedWordPositions[placedWordIntersectionPos];

    // Calculate positions for new word
    List<Position> newPositions = [];
    bool newWordIsHorizontal = !placedWordIsHorizontal;

    if (newWordIsHorizontal) {
      // Place horizontally
      int startCol = intersectionPos.col - wordIntersectionPos;
      for (int i = 0; i < word.length; i++) {
        Position pos = Position(row: intersectionPos.row, col: startCol + i);
        newPositions.add(pos);
      }
    } else {
      // Place vertically
      int startRow = intersectionPos.row - wordIntersectionPos;
      for (int i = 0; i < word.length; i++) {
        Position pos = Position(row: startRow + i, col: intersectionPos.col);
        newPositions.add(pos);
      }
    }

    // Check if placement is valid (no conflicts)
    for (int i = 0; i < newPositions.length; i++) {
      Position pos = newPositions[i];
      if (pos.row < 0 ||
          pos.row >= maxGridSize ||
          pos.col < 0 ||
          pos.col >= maxGridSize) {
        return null; // Out of bounds
      }

      String? existingLetter = grid[pos.row][pos.col];
      if (existingLetter != null && existingLetter != word[i]) {
        return null; // Conflict
      }
    }

    return WordPlacement(
      word: word,
      positions: newPositions,
      isHorizontal: newWordIsHorizontal,
    );
  }

  static WordPlacement? _placeWordInEmptySpace(
    String word,
    List<List<String?>> grid,
  ) {
    // Try to place horizontally first
    for (int row = 0; row < maxGridSize; row++) {
      for (int col = 0; col <= maxGridSize - word.length; col++) {
        bool canPlace = true;
        for (int i = 0; i < word.length; i++) {
          if (grid[row][col + i] != null) {
            canPlace = false;
            break;
          }
        }

        if (canPlace) {
          List<Position> positions = [];
          for (int i = 0; i < word.length; i++) {
            positions.add(Position(row: row, col: col + i));
          }

          return WordPlacement(
            word: word,
            positions: positions,
            isHorizontal: true,
          );
        }
      }
    }

    // Try to place vertically
    for (int row = 0; row <= maxGridSize - word.length; row++) {
      for (int col = 0; col < maxGridSize; col++) {
        bool canPlace = true;
        for (int i = 0; i < word.length; i++) {
          if (grid[row + i][col] != null) {
            canPlace = false;
            break;
          }
        }

        if (canPlace) {
          List<Position> positions = [];
          for (int i = 0; i < word.length; i++) {
            positions.add(Position(row: row + i, col: col));
          }

          return WordPlacement(
            word: word,
            positions: positions,
            isHorizontal: false,
          );
        }
      }
    }

    return null;
  }
}
