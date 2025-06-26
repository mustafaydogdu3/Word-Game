import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_model.dart';
import '../services/word_service.dart';

class GameViewModel extends ChangeNotifier {
  GameModel _game = GameModel(
    letters: [],
    targetWords: [],
    foundWords: [],
    currentLevel: 1,
    theme: 'Basic Articles',
  );

  bool _isLoading = true;

  GameModel get game => _game;
  bool get isLoading => _isLoading;

  GameViewModel() {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    _isLoading = true;
    notifyListeners();

    await WordService.loadWords();

    // Load saved level from SharedPreferences
    final savedLevel = await _loadCurrentLevel();

    // Start with saved level or level 1
    _generatePuzzleForLevel(savedLevel);

    _isLoading = false;
    notifyListeners();
  }

  Future<int> _loadCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_level') ?? 1;
  }

  Future<void> _saveCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', level);
  }

  void _generatePuzzleForLevel(int levelNumber) {
    final puzzle = WordService.generatePuzzleForLevel(levelNumber);

    // Convert WordService.Position to GameModel.Position
    Map<String, List<Position>> gamePositions = {};
    puzzle.wordPositions.forEach((word, positions) {
      gamePositions[word] = positions
          .map((pos) => Position(pos.row, pos.col))
          .toList();
    });

    _game = GameModel(
      letters: puzzle.letters,
      targetWords: puzzle.targetWords,
      foundWords: [],
      wordPositions: gamePositions,
      currentLevel: levelNumber,
      theme: puzzle.theme,
    );

    notifyListeners();
  }

  void checkWord(String word) {
    final upperWord = word.toUpperCase();

    if (_game.targetWords.contains(upperWord) &&
        !_game.foundWords.contains(upperWord)) {
      _game.foundWords = [..._game.foundWords, upperWord];

      // Check if level is completed
      if (_game.isCompleted) {
        // Move to next level after a short delay
        Future.delayed(Duration(seconds: 2), () {
          _moveToNextLevel();
        });
      }

      notifyListeners();
    }
  }

  void _moveToNextLevel() async {
    int nextLevel = _game.currentLevel + 1;
    if (nextLevel <= WordService.totalLevels) {
      // Save progress before moving to next level
      await _saveCurrentLevel(nextLevel);
      _generatePuzzleForLevel(nextLevel);
    } else {
      // Game completed! Show celebration or restart
      await _saveCurrentLevel(1); // Reset to level 1
      _generatePuzzleForLevel(1); // Restart from level 1
    }
  }

  void shuffleLetters() {
    _game.letters.shuffle();
    notifyListeners();
  }

  String? getHint() {
    final remainingWords = _game.targetWords
        .where((word) => !_game.foundWords.contains(word))
        .toList();

    if (remainingWords.isEmpty) return null;

    // Return first letter of a random remaining word
    final random = Random();
    final hintWord = remainingWords[random.nextInt(remainingWords.length)];
    return '${hintWord[0]}... (${hintWord.length} harf)';
  }

  List<Position> getWordPositions(String word) {
    return _game.wordPositions[word] ?? [];
  }

  // Force move to a specific level (for testing)
  void goToLevel(int levelNumber) async {
    if (levelNumber > 0 && levelNumber <= WordService.totalLevels) {
      await _saveCurrentLevel(levelNumber);
      _generatePuzzleForLevel(levelNumber);
    }
  }

  // Get current level info
  String get currentLevelInfo => 'Level ${_game.currentLevel}: ${_game.theme}';

  // Reset progress to level 1
  Future<void> resetProgress() async {
    await _saveCurrentLevel(1);
    _generatePuzzleForLevel(1);
  }
}
