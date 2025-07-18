import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class WordPosition {
  final int row;
  final int col;

  WordPosition({required this.row, required this.col});

  factory WordPosition.fromJson(Map<String, dynamic> json) {
    return WordPosition(row: json['row'], col: json['col']);
  }
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
}

// New data structures for word_game_lv.json format
class LVWord {
  final String word;
  final List<List<int>> positions; // [row, col] format

  LVWord({required this.word, required this.positions});

  factory LVWord.fromJson(Map<String, dynamic> json) {
    return LVWord(
      word: json['word'],
      positions: (json['positions'] as List)
          .map((pos) => List<int>.from(pos))
          .toList(),
    );
  }
}

class LVIntersection {
  final String word1;
  final int index1;
  final String word2;
  final int index2;

  LVIntersection({
    required this.word1,
    required this.index1,
    required this.word2,
    required this.index2,
  });

  factory LVIntersection.fromJson(Map<String, dynamic> json) {
    return LVIntersection(
      word1: json['word1'],
      index1: json['index1'],
      word2: json['word2'],
      index2: json['index2'],
    );
  }
}

class LVLevel {
  final int level;
  final String theme;
  final int wordCount;
  final List<int> gridSize;
  final List<String> letters;
  final List<LVWord> words;
  final List<LVIntersection> intersections;

  LVLevel({
    required this.level,
    required this.theme,
    required this.wordCount,
    required this.gridSize,
    required this.letters,
    required this.words,
    required this.intersections,
  });

  factory LVLevel.fromJson(Map<String, dynamic> json) {
    return LVLevel(
      level: json['level'],
      theme: json['theme'],
      wordCount: json['word_count'],
      gridSize: List<int>.from(json['gridSize']),
      letters: List<String>.from(json['letters']),
      words: (json['words'] as List).map((w) => LVWord.fromJson(w)).toList(),
      intersections: (json['intersections'] as List)
          .map((i) => LVIntersection.fromJson(i))
          .toList(),
    );
  }
}

class GermanWord {
  final String word;
  final int frequency;
  final int length;
  final List<WordPosition>? positions;

  GermanWord({
    required this.word,
    required this.frequency,
    required this.length,
    this.positions,
  });

  factory GermanWord.fromJson(Map<String, dynamic> json) {
    String word = json['word'];
    return GermanWord(
      word: word,
      frequency: json['frequency'] ?? 100, // Default frequency
      length: json['length'] ?? word.length, // Use actual word length
      positions: json['positions'] != null
          ? (json['positions'] as List)
                .map((p) => WordPosition.fromJson(p))
                .toList()
          : null,
    );
  }
}

class Level {
  final int levelNumber;
  final String theme;
  final List<GermanWord> words;
  final List<String> letters;
  final List<Intersection> intersections;

  Level({
    required this.levelNumber,
    required this.theme,
    required this.words,
    required this.letters,
    required this.intersections,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelNumber: json['level'],
      theme: json['theme'],
      words: (json['words'] as List)
          .map((w) => GermanWord.fromJson(w))
          .toList(),
      letters: List<String>.from(json['letters']),
      intersections: json['intersections'] != null
          ? (json['intersections'] as List)
                .map((i) => Intersection.fromJson(i))
                .toList()
          : [],
    );
  }
}

class WordService {
  static List<GermanWord> _words = [];
  static List<Level> _levels = [];
  static List<LVLevel> _lvLevels = [];
  static bool _isLoaded = false;
  static bool _isLVLoaded = false;

  static Future<void> loadWords() async {
    if (_isLoaded) return;

    try {
      // Load all levels (1-10) from the new German levels file
      final String response = await rootBundle.loadString(
        'assets/json/levels_final_de_1_to_10.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> levelsJson = data['levels'];

      _levels = levelsJson.map((json) => Level.fromJson(json)).toList();

      // Flatten all words from all levels for backward compatibility
      _words = _levels.expand((level) => level.words).toList();

      _isLoaded = true;
    } catch (e) {
      print('Error loading words: $e');
    }
  }

  static Future<void> loadLVWords() async {
    if (_isLVLoaded) return;

    try {
      print('Loading LV words...');
      // Load word_game_lv.json file
      final String response = await rootBundle.loadString(
        'assets/json/word_game_lv.json',
      );
      print('LV JSON loaded, length: ${response.length}');

      final List<dynamic> levelsJson = json.decode(response);
      print('LV JSON decoded, levels count: ${levelsJson.length}');

      _lvLevels = levelsJson.map((json) => LVLevel.fromJson(json)).toList();
      print('LV levels parsed: ${_lvLevels.length}');

      _isLVLoaded = true;
      print('LV words loaded successfully');
    } catch (e) {
      print('Error loading LV words: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  static List<GermanWord> getWordsByLength(int length) {
    return _words.where((word) => word.length == length).toList();
  }

  static List<GermanWord> getWordsByFrequency(int minFrequency) {
    return _words.where((word) => word.frequency >= minFrequency).toList();
  }

  static Level? getLevelData(int levelNumber) {
    if (levelNumber <= 0 || levelNumber > _levels.length) return null;
    return _levels[levelNumber - 1];
  }

  static LVLevel? getLVLevelData(int levelNumber) {
    print(
      'getLVLevelData called for level $levelNumber, total LV levels: ${_lvLevels.length}',
    );
    if (levelNumber <= 0 || levelNumber > _lvLevels.length) {
      print('Level $levelNumber out of range (1-${_lvLevels.length})');
      return null;
    }
    final level = _lvLevels[levelNumber - 1];
    print(
      'Found LV level: ${level.theme}, letters: ${level.letters}, words: ${level.words.map((w) => w.word).toList()}',
    );
    return level;
  }

  static int get totalLevels => _levels.length;
  static int get totalLVLevels => _lvLevels.length;

  static List<String> findWordsFromLetters(List<String> availableLetters) {
    List<String> foundWords = [];

    for (GermanWord germanWord in _words) {
      if (canFormWord(germanWord.word, availableLetters)) {
        foundWords.add(germanWord.word);
      }
    }

    // Sort by frequency (higher frequency first)
    foundWords.sort((a, b) {
      final aWord = _words.firstWhere((w) => w.word == a);
      final bWord = _words.firstWhere((w) => w.word == b);
      return bWord.frequency.compareTo(aWord.frequency);
    });

    return foundWords;
  }

  static bool canFormWord(String word, List<String> availableLetters) {
    List<String> tempLetters = List.from(availableLetters);

    for (String char in word.split('')) {
      int index = tempLetters.indexOf(char.toUpperCase());
      if (index == -1) {
        return false;
      }
      tempLetters.removeAt(index);
    }

    return true;
  }

  static GamePuzzle generatePuzzleForLevel(int levelNumber) {
    Level? level = getLevelData(levelNumber);
    if (level == null) {
      // Fallback to random puzzle
      return generatePuzzle(difficulty: 1);
    }

    // Extract word strings from GermanWord objects
    List<String> targetWords = level.words.map((w) => w.word).toList();

    // Create word positions map from JSON positions
    Map<String, List<WordPosition>> wordPositions = {};
    for (GermanWord word in level.words) {
      if (word.positions != null) {
        wordPositions[word.word] = word.positions!;
      }
    }

    return GamePuzzle(
      letters: List.from(level.letters)..shuffle(),
      targetWords: targetWords,
      level: levelNumber,
      theme: level.theme,
      wordPositions: wordPositions,
      intersections: level.intersections,
    );
  }

  static GamePuzzle generatePuzzleForLVLevel(int levelNumber) {
    print('Generating LV puzzle for level $levelNumber');
    LVLevel? level = getLVLevelData(levelNumber);
    if (level == null) {
      print('LV level $levelNumber not found, falling back to random puzzle');
      // Fallback to random puzzle
      return generatePuzzle(difficulty: 1);
    }

    print('LV level found: ${level.theme}, words: ${level.words.length}');
    // Extract word strings from LVWord objects
    List<String> targetWords = level.words.map((w) => w.word).toList();
    print('Target words: $targetWords');

    // Convert LV positions to WordPosition format
    Map<String, List<WordPosition>> wordPositions = {};
    for (LVWord word in level.words) {
      wordPositions[word.word] = word.positions
          .map((pos) => WordPosition(row: pos[0], col: pos[1]))
          .toList();
    }
    print('Word positions converted for ${wordPositions.length} words');

    // Convert LV intersections to Intersection format
    List<Intersection> intersections = level.intersections.map((lvInt) {
      return Intersection(
        words: [lvInt.word1, lvInt.word2],
        commonLetter: level.letters.first, // This might need adjustment
        positionInFirst: lvInt.index1,
        positionInSecond: lvInt.index2,
      );
    }).toList();
    print('Intersections converted: ${intersections.length}');

    final puzzle = GamePuzzle(
      letters: List.from(level.letters)..shuffle(),
      targetWords: targetWords,
      level: levelNumber,
      theme: level.theme,
      wordPositions: wordPositions,
      intersections: intersections,
      gridSize: level.gridSize,
    );

    print('LV puzzle generated successfully with grid size: ${level.gridSize}');
    return puzzle;
  }

  static GamePuzzle generatePuzzle({int difficulty = 1}) {
    List<GermanWord> candidateWords;

    // Select words based on difficulty
    switch (difficulty) {
      case 1: // Easy - high frequency, shorter words
        candidateWords = _words
            .where((w) => w.frequency >= 90 && w.length >= 3 && w.length <= 5)
            .toList();
        break;
      case 2: // Medium
        candidateWords = _words
            .where((w) => w.frequency >= 80 && w.length >= 3 && w.length <= 6)
            .toList();
        break;
      case 3: // Hard
        candidateWords = _words
            .where((w) => w.frequency >= 70 && w.length >= 4 && w.length <= 6)
            .toList();
        break;
      default:
        candidateWords = _words.where((w) => w.frequency >= 85).toList();
    }

    candidateWords.shuffle();

    // Select exactly 4 target words to match reference design
    List<String> targetWords = candidateWords
        .take(4) // Exactly 4 words
        .map((w) => w.word)
        .toList();

    // Generate letters that can form these words
    List<String> letters = generateLettersForWords(targetWords);

    return GamePuzzle(
      letters: letters,
      targetWords: targetWords,
      level: 0,
      theme: 'Random',
    );
  }

  static List<String> generateLettersForWords(
    List<String> targetWords, {
    int totalLetters = 6,
  }) {
    Set<String> requiredLetters = {};

    // Collect all unique letters from target words
    for (String word in targetWords) {
      for (String char in word.split('')) {
        requiredLetters.add(char.toUpperCase());
      }
    }

    List<String> letters = requiredLetters.toList();

    // Fill remaining slots with random high-frequency letters
    List<String> commonLetters = [
      'E',
      'N',
      'I',
      'R',
      'S',
      'A',
      'T',
      'D',
      'H',
      'U',
    ];
    Random random = Random();

    while (letters.length < totalLetters) {
      String randomLetter = commonLetters[random.nextInt(commonLetters.length)];
      if (!letters.contains(randomLetter)) {
        letters.add(randomLetter);
      }
    }

    // Shuffle the letters
    letters.shuffle();

    return letters.take(totalLetters).toList();
  }

  static List<GermanWord> get allWords => _words;
  static List<Level> get allLevels => _levels;
  static List<LVLevel> get allLVLevels => _lvLevels;
}

class GamePuzzle {
  final List<String> letters;
  final List<String> targetWords;
  final int level;
  final String theme;
  final Map<String, List<WordPosition>> wordPositions;
  final List<Intersection> intersections;
  final List<int>? gridSize; // New field for LV levels

  GamePuzzle({
    required this.letters,
    required this.targetWords,
    required this.level,
    required this.theme,
    this.wordPositions = const {},
    this.intersections = const [],
    this.gridSize,
  });
}
