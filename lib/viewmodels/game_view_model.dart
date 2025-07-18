import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_model.dart';
import '../services/word_service.dart';

enum GameMode { german, lv }

class GameViewModel extends ChangeNotifier {
  GameModel _game = GameModel(
    letters: [],
    targetWords: [],
    foundWords: [],
    currentLevel: 1,
    theme: 'Basic Articles',
  );

  bool _isLoading = true;
  GameMode _currentMode = GameMode.german; // Default to German mode

  GameModel get game => _game;
  bool get isLoading => _isLoading;
  GameMode get currentMode => _currentMode;

  GameViewModel() {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    _isLoading = true;
    notifyListeners();

    print('Initializing game...');
    // Load both German and LV words
    await WordService.loadWords();
    print('German words loaded');

    await WordService.loadLVWords();
    print('LV words loaded, total LV levels: ${WordService.totalLVLevels}');

    // Load saved mode and level
    await _loadSavedState();
    print('Saved state loaded, current mode: ${_currentMode.name}');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('game_mode') ?? 'german';
    _currentMode = savedMode == 'german' ? GameMode.german : GameMode.lv;

    final savedLevel = prefs.getInt('current_level_${_currentMode.name}') ?? 1;
    await _saveCurrentLevel(savedLevel);
    _generatePuzzleForLevel(savedLevel);
  }

  Future<void> _saveCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level_${_currentMode.name}', level);
  }

  Future<void> _saveGameMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game_mode', _currentMode.name);
  }

  void _generatePuzzleForLevel(int levelNumber) {
    print(
      '_generatePuzzleForLevel called with level $levelNumber, mode: ${_currentMode.name}',
    );
    GamePuzzle puzzle;

    if (_currentMode == GameMode.german) {
      print('Generating German puzzle...');
      puzzle = WordService.generatePuzzleForLevel(levelNumber);
    } else {
      print('Generating LV puzzle...');
      puzzle = WordService.generatePuzzleForLVLevel(levelNumber);
    }

    print(
      'Puzzle generated - letters: ${puzzle.letters}, targetWords: ${puzzle.targetWords}, theme: ${puzzle.theme}',
    );

    // Convert WordService.Position to GameModel.Position
    Map<String, List<Position>> gamePositions = {};
    puzzle.wordPositions.forEach((word, positions) {
      gamePositions[word] = positions
          .map((pos) => Position(pos.row, pos.col))
          .toList();
    });

    // Use grid size from puzzle if available, otherwise default to 5
    int gridSize = puzzle.gridSize?.first ?? 5;
    print('Grid size: $gridSize');

    _game = GameModel(
      letters: puzzle.letters,
      targetWords: puzzle.targetWords,
      foundWords: [],
      wordPositions: gamePositions,
      currentLevel: levelNumber,
      theme: puzzle.theme,
      gridSize: gridSize,
    );

    print('Game model updated with letters: ${_game.letters}');
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
    int maxLevels = _currentMode == GameMode.german
        ? WordService.totalLevels
        : WordService.totalLVLevels;

    if (nextLevel <= maxLevels) {
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
    int maxLevels = _currentMode == GameMode.german
        ? WordService.totalLevels
        : WordService.totalLVLevels;

    if (levelNumber > 0 && levelNumber <= maxLevels) {
      await _saveCurrentLevel(levelNumber);
      _generatePuzzleForLevel(levelNumber);
    }
  }

  // Switch between German and LV modes
  Future<void> switchMode(GameMode newMode) async {
    print('Switching mode from ${_currentMode.name} to ${newMode.name}');
    if (_currentMode != newMode) {
      _currentMode = newMode;
      await _saveGameMode();
      print('Mode saved: ${_currentMode.name}');

      // Load the first level of the new mode
      await _saveCurrentLevel(1);
      _generatePuzzleForLevel(1);
      print('Generated puzzle for ${_currentMode.name} mode, level 1');
    }
  }

  // Get current level info
  String get currentLevelInfo => 'Level ${_game.currentLevel}: ${_game.theme}';

  // Get mode info
  String get modeInfo => _currentMode == GameMode.german ? 'German' : 'LV';

  // Get total levels for current mode
  int get totalLevels => _currentMode == GameMode.german
      ? WordService.totalLevels
      : WordService.totalLVLevels;

  // Reset progress to level 1
  Future<void> resetProgress() async {
    await _saveCurrentLevel(1);
    _generatePuzzleForLevel(1);
  }
}
