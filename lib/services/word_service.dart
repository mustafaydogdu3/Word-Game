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
  final WordPosition position;

  Intersection({required this.words, required this.position});

  factory Intersection.fromJson(Map<String, dynamic> json) {
    return Intersection(
      words: List<String>.from(json['words']),
      position: WordPosition.fromJson(json['position']),
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
    return GermanWord(
      word: json['word'],
      frequency: json['frequency'],
      length: json['length'],
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
  static bool _isLoaded = false;

  static Future<void> loadWords() async {
    if (_isLoaded) return;

    try {
      final String response = await rootBundle.loadString(
        'assets/german_words.json',
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

  static int get totalLevels => _levels.length;

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
}

class GamePuzzle {
  final List<String> letters;
  final List<String> targetWords;
  final int level;
  final String theme;
  final Map<String, List<WordPosition>> wordPositions;
  final List<Intersection> intersections;

  GamePuzzle({
    required this.letters,
    required this.targetWords,
    required this.level,
    required this.theme,
    this.wordPositions = const {},
    this.intersections = const [],
  });
}
