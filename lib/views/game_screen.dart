import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/game_view_model.dart';
import 'widgets/index.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<int> selectedIndexes = [];
  List<Offset> linePoints = [];
  bool _showLevelCompleteOverlay = false;
  GameViewModel? _viewModel; // Store view model reference
  final GlobalKey _circleKey = GlobalKey(); // WOW tarzı harf seçimi için key

  @override
  void initState() {
    super.initState();
    // Listen to game completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<GameViewModel>(context, listen: false);
      _viewModel?.addListener(_onGameStateChanged);
    });
  }

  @override
  void dispose() {
    // Safely remove listener using stored reference
    _viewModel?.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (_viewModel?.game.isCompleted == true && !_showLevelCompleteOverlay) {
      setState(() {
        _showLevelCompleteOverlay = true;
      });

      // Hide overlay after 2 seconds and let the view model handle level transition
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showLevelCompleteOverlay = false;
          });
        }
      });
    }
  }

  void _onWordSelected(String selectedWord) {
    final viewModel =
        _viewModel ?? Provider.of<GameViewModel>(context, listen: false);
    viewModel.checkWord(selectedWord);
  }

  void _onShuffle() {
    final viewModel =
        _viewModel ?? Provider.of<GameViewModel>(context, listen: false);
    viewModel.shuffleLetters();

    // Force UI update
    setState(() {
      // Clear any ongoing selection
      selectedIndexes.clear();
      linePoints.clear();
    });
  }

  // Add callback functions to handle selection state changes
  void _onSelectionChanged(List<int> newSelectedIndexes) {
    print('GameScreen: Selection changed to: $newSelectedIndexes');
    setState(() {
      selectedIndexes = newSelectedIndexes;
    });
  }

  void _onLinePointsChanged(List<Offset> newLinePoints) {
    setState(() {
      linePoints = newLinePoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    // Show loading screen while initializing
    if (viewModel.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: screenHeight * 0.04),
              Text(
                'Kelimeler yükleniyor...',
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? screenWidth * 0.04
                      : screenWidth * 0.035,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final letters = viewModel.game.letters;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4a4fb5), // Deep blue at top
                  Color(0xFF7b5fb0), // Purple middle
                  Color(0xFFf4a261), // Orange/yellow at bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.6, 1.0],
              ),
              image: DecorationImage(
                image: AssetImage('assets/images/istanbul.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main game layout using Stack for fixed positioning
          SafeArea(
            child: Stack(
              children: [
                // Top section with game info - Fixed at top
                Positioned(top: 0, left: 0, right: 0, child: TopBar()),

                // Grid area - Exactly 50% of screen height starting from top bar
                Positioned(
                  top: screenHeight * 0.08, // Top bar height
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.42, // 50% - top bar height
                  child: Center(child: WordGrid()),
                ),

                // Selected word display - Only show when letters are being selected
                if (selectedIndexes.isNotEmpty)
                  Positioned(
                    bottom:
                        screenHeight * 0.05 +
                        _getDynamicLetterCircleSize(context, letters.length) +
                        screenHeight * 0.025,
                    left: 0,
                    right: 0,
                    child: SelectedWordOverlay(
                      selectedWord: selectedIndexes
                          .where((i) => i >= 0 && i < letters.length)
                          .map((i) => letters[i])
                          .join(),
                      letterCount: letters.length,
                    ),
                  ),

                // Letter circle - Responsive positioning at bottom
                Positioned(
                  bottom: screenHeight * 0.05,
                  left: 0,
                  right: 0,
                  child: LetterCircle(
                    letters: letters,
                    selectedIndexes: selectedIndexes,
                    linePoints: linePoints,
                    onWordSelected: _onWordSelected,
                    onShuffle: _onShuffle,
                    circleKey: _circleKey,
                    onSelectionChanged: _onSelectionChanged,
                    onLinePointsChanged: _onLinePointsChanged,
                  ),
                ),
              ],
            ),
          ),

          // Level completion overlay
          if (_showLevelCompleteOverlay)
            LevelCompleteOverlay(viewModel: viewModel),
        ],
      ),
    );
  }

  // Calculate dynamic circle size for responsive design
  double _getDynamicLetterCircleSize(BuildContext context, int letterCount) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Base size calculation for responsive design
    double baseSize = screenWidth * 0.6; // Responsive base diameter

    // Adjust size based on number of letters for optimal spacing
    if (letterCount <= 3) {
      return baseSize * 0.85; // Compact for few letters
    } else if (letterCount <= 5) {
      return baseSize * 0.95; // Standard size
    } else if (letterCount <= 7) {
      return baseSize; // Full size for many letters
    } else {
      return baseSize * 1.05; // Slightly larger for very many letters
    }
  }
}
