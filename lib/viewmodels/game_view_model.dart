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
  bool _isDisposed = false; // Track if the view model is disposed
  DateTime? _lastNotifyTime; // Track last notification time for debouncing
  final bool _isInBuild = false; // Track if we're currently in build phase

  GameModel get game => _game;
  bool get isLoading => _isLoading;
  GameMode get currentMode => _currentMode;

  GameViewModel() {
    // Don't auto-initialize to avoid setState during build
    // Initialization will be called manually from splash screen
  }

  // Safe notifyListeners method with debouncing and post-frame callback
  void _safeNotifyListeners() {
    if (_isDisposed) return;

    // Debounce rapid notifications (minimum 16ms between calls = ~60fps)
    final now = DateTime.now();
    if (_lastNotifyTime != null &&
        now.difference(_lastNotifyTime!).inMilliseconds < 16) {
      return;
    }

    // Always use post-frame callback to ensure we're not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        try {
          notifyListeners();
          _lastNotifyTime = DateTime.now();
        } catch (e) {
          print('Error in notifyListeners: $e');
        }
      }
    });
  }

  // Force notifyListeners for important state changes
  void _forceNotifyListeners() {
    if (_isDisposed) return;

    // Always use post-frame callback to ensure we're not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        try {
          notifyListeners();
          _lastNotifyTime = DateTime.now();
        } catch (e) {
          print('Error in force notifyListeners: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _initializeGame() async {
    if (_isDisposed) return;

    _isLoading = true;
    _forceNotifyListeners(); // Use force for loading state

    try {
      print('Initializing game...');
      // Load both German and LV words
      await WordService.loadWords();
      print('German words loaded');

      await WordService.loadLVWords();
      print('LV words loaded, total LV levels: ${WordService.totalLVLevels}');

      // Verify LV levels are loaded
      if (WordService.totalLVLevels == 0) {
        print('WARNING: No LV levels loaded!');
      } else {
        print(
          'LV levels loaded successfully. First level: ${WordService.getLVLevelData(1)?.theme}',
        );
      }

      // Load saved mode and level
      await _loadSavedState();
      print('Saved state loaded, current mode: ${_currentMode.name}');

      _isLoading = false;
      _forceNotifyListeners(); // Force notification for loading state change
    } catch (e) {
      print('Error during game initialization: $e');
      _isLoading = false;
      _forceNotifyListeners(); // Force notification even on error
    }
  }

  Future<void> _loadSavedState() async {
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    final savedMode =
        prefs.getString('game_mode') ?? 'lv'; // Default to LV mode
    _currentMode = savedMode == 'german' ? GameMode.german : GameMode.lv;

    final savedLevel =
        prefs.getInt('current_level_${_currentMode.name}') ??
        1; // Always start at level 1
    await _saveCurrentLevel(savedLevel);

    // Use post-frame callback for puzzle generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _generatePuzzleForLevel(savedLevel);
      }
    });

    print(
      'Saved state loaded, current mode: ${_currentMode.name}, level: $savedLevel',
    );
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
    if (_isDisposed) return;

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

    // Use grid size directly from JSON without limiting
    int gridCols = puzzle.gridSize?.first ?? 5;
    int gridRows = puzzle.gridSize?.length == 2
        ? puzzle.gridSize![1]
        : gridCols;

    // For manual placement, use the exact grid size from JSON
    // No need to limit grid size since positions are manually controlled

    print('Grid size: ${gridCols}x$gridRows');

    _game = GameModel(
      letters: puzzle.letters,
      targetWords: puzzle.targetWords,
      foundWords: [],
      wordPositions: gamePositions,
      currentLevel: levelNumber,
      theme: puzzle.theme,
      gridRows: gridRows,
      gridCols: gridCols,
    );

    print('Game model updated with letters: ${_game.letters}');
    _safeNotifyListeners();
  }

  void checkWord(String word) {
    if (_isDisposed) return;

    final upperWord = word.toUpperCase();

    print('Checking word: "$word" (uppercase: "$upperWord")');
    print('Target words: ${_game.targetWords}');
    print('Already found: ${_game.foundWords}');

    // Only validate against targetWords list - no grid-based detection
    if (_game.targetWords.contains(upperWord)) {
      if (!_game.foundWords.contains(upperWord)) {
        print(
          'Word "$upperWord" is valid and not yet found - adding to found words',
        );
        _game.foundWords = [..._game.foundWords, upperWord];

        // Check if level is completed
        if (_game.isCompleted) {
          print('Level completed! Moving to next level...');
          // Move to next level after a short delay
          Future.delayed(Duration(seconds: 2), () {
            _moveToNextLevel();
          });
        }

        _safeNotifyListeners();
      } else {
        print('Word "$upperWord" is valid but already found');
      }
    } else {
      print('Word "$upperWord" is NOT in target words list - ignoring');
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
    if (_isDisposed) return;

    _game.letters.shuffle();
    _safeNotifyListeners();
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
    if (_isDisposed) return;

    await _saveCurrentLevel(1);
    _generatePuzzleForLevel(1);
  }

  // Public method to initialize game (for splash screen)
  Future<void> initializeGame() async {
    await _initializeGame();
  }

  // Debug method to check view model state
  void debugState() {
    print('GameViewModel Debug Info:');
    print('- Disposed: $_isDisposed');
    print('- Loading: $_isLoading');
    print('- In Build: $_isInBuild');
    print('- Current Mode: ${_currentMode.name}');
    print('- Current Level: ${_game.currentLevel}');
    print('- Letters Count: ${_game.letters.length}');
    print('- Target Words Count: ${_game.targetWords.length}');
    print('- Found Words Count: ${_game.foundWords.length}');
    print('- Last Notify Time: $_lastNotifyTime');
  }
}
