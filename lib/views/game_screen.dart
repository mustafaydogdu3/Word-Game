import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_model.dart';
import '../services/sound_service.dart';
import '../utils/responsive_helper.dart';
import '../viewmodels/game_view_model.dart';
import 'main_menu_screen.dart';
import 'settings_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<int> selectedIndexes = [];
  List<Offset> linePoints = [];
  bool isPanning = false;
  bool _showLevelCompleteOverlay = false;
  GameViewModel? _viewModel; // Store view model reference

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

  void _handlePanStart(Offset position, BuildContext context) {
    final letters = Provider.of<GameViewModel>(
      context,
      listen: false,
    ).game.letters;

    setState(() {
      selectedIndexes.clear();
      linePoints.clear();
      isPanning = true;

      // Check if starting on a letter
      final touchRadius =
          ResponsiveHelper.getResponsiveLetterSize(context) * 1.5;
      final circleSize = _getDynamicLetterCircleSize(context, letters.length);
      final center = circleSize / 2;
      final radius = circleSize * 0.32;

      for (int i = 0; i < letters.length; i++) {
        final double angle = (2 * pi * i) / letters.length - pi / 2;
        final letterCenter = Offset(
          center + radius * cos(angle),
          center + radius * sin(angle),
        );
        if ((position - letterCenter).distance < touchRadius) {
          if (!selectedIndexes.contains(i)) {
            selectedIndexes.add(i);
            linePoints.add(letterCenter);
            SoundService.playWordFound();
          }
          break;
        }
      }
    });
  }

  void _handlePanUpdate(Offset position, BuildContext context) {
    if (!isPanning) return;

    final letters = Provider.of<GameViewModel>(
      context,
      listen: false,
    ).game.letters;

    setState(() {
      // Update current line endpoint
      if (linePoints.isNotEmpty) {
        if (linePoints.length % 2 == 1) {
          linePoints.add(position);
        } else {
          linePoints.last = position;
        }
      }

      // Check if over a letter
      final touchRadius =
          ResponsiveHelper.getResponsiveLetterSize(context) * 1.5;
      final circleSize = _getDynamicLetterCircleSize(context, letters.length);
      final center = circleSize / 2;
      final radius = circleSize * 0.32;

      for (int i = 0; i < letters.length; i++) {
        final double angle = (2 * pi * i) / letters.length - pi / 2;
        final letterCenter = Offset(
          center + radius * cos(angle),
          center + radius * sin(angle),
        );

        if ((position - letterCenter).distance < touchRadius) {
          if (!selectedIndexes.contains(i)) {
            selectedIndexes.add(i);
            linePoints.add(letterCenter);
            SoundService.playWordFound();
          }
          break;
        }
      }
    });
  }

  void _handlePanEnd(BuildContext context) {
    setState(() {
      isPanning = false;
    });

    // Use stored view model reference if available, otherwise get from context
    final viewModel =
        _viewModel ?? Provider.of<GameViewModel>(context, listen: false);
    final letters = viewModel.game.letters;

    // Only validate words selected from the circle - NOT from grid positions
    final selectedWord = selectedIndexes
        .where((i) => i >= 0 && i < letters.length)
        .map((i) => letters[i])
        .join();

    if (selectedWord.isNotEmpty) {
      print('Player selected word from circle: "$selectedWord"');
      viewModel.checkWord(selectedWord);
    }

    setState(() {
      selectedIndexes.clear();
      linePoints.clear();
    });
  }

  // Güvenli navigation helper
  void _navigateToMainMenu(BuildContext context) {
    try {
      // Tüm route'ları temizle ve ana menüye git
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main-menu', (route) => false);
    } catch (e) {
      print('Navigation error: $e');
      // Fallback: pop ile geri git
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: ResponsiveHelper.isTablet(context)
                ? MediaQuery.of(context).size.width * 0.6
                : MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4a4fb5),
                  Color(0xFF7b5fb0),
                  Color(0xFFf4a261),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveLargeSpacing(context),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveHelper.getResponsiveSpacing(context),
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4a4fb5), Color(0xFF7b5fb0)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: ResponsiveHelper.getResponsiveIconSize(context),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveSpacing(context),
                      ),
                      Expanded(
                        child: Text(
                          'Ayarlar',
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.getResponsiveTitleFontSize(
                                  context,
                                ),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4a4fb5),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await SoundService.playButtonClick();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.all(
                            ResponsiveHelper.getResponsiveSpacing(context) *
                                0.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: ResponsiveHelper.getResponsiveIconSize(
                              context,
                              mobile: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveLargeSpacing(context),
                  ),
                  child: Column(
                    children: [
                      // Ses ayarları
                      _buildBeautifulSettingsButton(
                        icon: SoundService.isSoundEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        label: 'Ses Ayarları',
                        subtitle: SoundService.isSoundEnabled
                            ? 'Ses açık'
                            : 'Ses kapalı',
                        iconColor: SoundService.isSoundEnabled
                            ? Colors.green
                            : Colors.red,
                        gradientColors: SoundService.isSoundEnabled
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.red.shade400, Colors.red.shade600],
                        context: context,
                        onTap: () async {
                          await SoundService.playButtonClick();
                          await SoundService.toggleSound();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            // Dialog'u yeniden açarak güncel durumu göster
                            _showSettingsDialog(context);
                          }
                        },
                      ),

                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context),
                      ),

                      // Ana menüye dönme
                      _buildBeautifulSettingsButton(
                        icon: Icons.home,
                        label: 'Ana Menüye Dön',
                        subtitle: 'Oyunu kaydet ve ana menüye dön',
                        iconColor: Colors.white,
                        gradientColors: [
                          Colors.blue.shade400,
                          Colors.blue.shade700,
                        ],
                        context: context,
                        onTap: () async {
                          await SoundService.playButtonClick();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          // Onay dialog'u göster
                          if (context.mounted) {
                            final bool?
                            confirm = await _showBeautifulConfirmationDialog(
                              context,
                              'Ana Menüye Dön?',
                              'Mevcut oyun ilerlemeniz kaydedilecek. Ana menüye dönmek istediğinizden emin misiniz?',
                              'Evet, Dön',
                              Colors.blue,
                            );

                            if (confirm == true && context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const MainMenuScreen(),
                                ),
                              );
                            }
                          }
                        },
                      ),

                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context),
                      ),

                      // Seviye yeniden başlatma
                      _buildBeautifulSettingsButton(
                        icon: Icons.refresh,
                        label: 'Seviyeyi Yeniden Başlat',
                        subtitle: 'Mevcut seviyeyi sıfırla',
                        iconColor: Colors.white,
                        gradientColors: [
                          Colors.orange.shade400,
                          Colors.orange.shade700,
                        ],
                        context: context,
                        onTap: () async {
                          await SoundService.playButtonClick();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          // Onay dialog'u göster
                          if (context.mounted) {
                            final bool?
                            confirm = await _showBeautifulConfirmationDialog(
                              context,
                              'Seviyeyi Yeniden Başlat?',
                              'Mevcut seviye ilerlemeniz sıfırlanacak. Yeniden başlatmak istediğinizden emin misiniz?',
                              'Evet, Sıfırla',
                              Colors.orange,
                            );

                            if (confirm == true && context.mounted) {
                              // Use stored view model reference if available, otherwise get from context
                              final viewModel =
                                  _viewModel ??
                                  Provider.of<GameViewModel>(
                                    context,
                                    listen: false,
                                  );
                              await viewModel.resetProgress();
                              // Başarı mesajı göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Seviye başarıyla yeniden başlatıldı!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final shouldUseCompactLayout = ResponsiveHelper.shouldUseCompactLayout(
      context,
    );

    // Show loading screen while initializing
    if (viewModel.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(
                height: ResponsiveHelper.getResponsiveLargeSpacing(context),
              ),
              Text(
                'Kelimeler yükleniyor...',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final grid = viewModel.game.grid;
    final gridRows = viewModel.game.gridRows;
    final gridCols = viewModel.game.gridCols;
    final letters = viewModel.game.letters;
    final selectedWord = selectedIndexes
        .where((i) => i >= 0 && i < letters.length)
        .map((i) => letters[i])
        .join();

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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopSection(context, viewModel),
                ),

                // Grid area - Fixed higher up, never moves
                Positioned(
                  top:
                      ResponsiveHelper.getResponsiveTopOffset(context) +
                      ResponsiveHelper.getResponsiveSpacing(context),
                  left: 0,
                  right: 0,
                  bottom:
                      ResponsiveHelper.getResponsiveLetterCircleSize(context) +
                      ResponsiveHelper.getResponsiveBottomOffset(context) +
                      ResponsiveHelper.getResponsiveLargeSpacing(context) * 9,
                  child: _buildFixedGridArea(
                    context,
                    viewModel,
                    grid,
                    gridRows,
                    gridCols,
                    selectedWord,
                  ),
                ),

                // Letter circle - Fixed at bottom
                Positioned(
                  bottom: ResponsiveHelper.getResponsiveBottomOffset(context),
                  left: 0,
                  right: 0,
                  child: _buildFixedBottomSection(context, viewModel, letters),
                ),

                // Selected word display - Overlay positioned above letter circle
                if (selectedWord.isNotEmpty)
                  Positioned(
                    bottom:
                        ResponsiveHelper.getResponsiveLetterCircleSize(
                          context,
                        ) +
                        ResponsiveHelper.getResponsiveBottomOffset(context) +
                        ResponsiveHelper.getResponsiveLargeSpacing(context) *
                            0.5,
                    left: 0,
                    right: 0,
                    child: _buildSelectedWordOverlay(context, selectedWord),
                  ),
              ],
            ),
          ),

          // Level completion overlay
          if (_showLevelCompleteOverlay)
            _buildLevelCompleteOverlay(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildLevelCompleteOverlay(
    BuildContext context,
    GameViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(
            ResponsiveHelper.getResponsiveLargeSpacing(context),
          ),
          margin: EdgeInsets.all(
            ResponsiveHelper.getResponsivePadding(context),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
                Colors.green.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: ResponsiveHelper.getResponsiveIconSize(context) * 2,
                height: ResponsiveHelper.getResponsiveIconSize(context) * 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: ResponsiveHelper.getResponsiveIconSize(context) * 1.5,
                ),
              ),

              SizedBox(
                height: ResponsiveHelper.getResponsiveLargeSpacing(context),
              ),

              // Level completed text
              Text(
                'SEVİYE TAMAMLANDI!',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
                    context,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

              // Level info
              Text(
                'Seviye ${viewModel.game.currentLevel}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveSubtitleFontSize(
                    context,
                  ),
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

              // Next level info
              Text(
                'Sonraki seviyeye geçiliyor...',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, GameViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsivePadding(context),
        vertical: ResponsiveHelper.getResponsiveSpacing(context),
      ),
      child: Row(
        children: [
          // Score boxes
          Row(
            children: [
              _buildScoreBox(
                icon: Icons.diamond,
                value: '900',
                iconColor: Colors.green,
                backgroundColor: Colors.black87,
                context: context,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
              _buildScoreBox(
                icon: Icons.water_drop,
                value: '10',
                iconColor: Colors.blue,
                backgroundColor: Colors.black87,
                context: context,
              ),
            ],
          ),

          Spacer(),

          // Mode and level indicators
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context),
                  vertical: ResponsiveHelper.getResponsiveScoreBoxPadding(
                    context,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context),
                  ),
                ),
                child: Text(
                  'Seviye ${viewModel.game.currentLevel}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getResponsiveBodyFontSize(
                      context,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
              GestureDetector(
                onTap: () async {
                  await SoundService.playButtonClick();
                  SettingsDialog.show(context);
                },
                child: Container(
                  width: ResponsiveHelper.getResponsiveSettingsButtonSize(
                    context,
                  ),
                  height: ResponsiveHelper.getResponsiveSettingsButtonSize(
                    context,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: ResponsiveHelper.getResponsiveIconSize(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedGrid(
    BuildContext context,
    GameViewModel viewModel,
    List<List<String?>> grid,
  ) {
    // Build a set of all unique positions from all words
    Set<String> allPositions = {};
    Map<String, String> positionToLetter = {};

    // Collect all positions from all target words
    for (String word in viewModel.game.targetWords) {
      List<Position> positions = viewModel.getWordPositions(word);
      for (int i = 0; i < positions.length && i < word.length; i++) {
        Position pos = positions[i];
        String positionKey = '${pos.row},${pos.col}';
        allPositions.add(positionKey);

        // Map the letter at this position
        if (i < word.length) {
          positionToLetter[positionKey] = word[i];
        }
      }
    }

    if (allPositions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(
          ResponsiveHelper.getResponsiveLargeSpacing(context),
        ),
        child: Text(
          'Grid boş',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
            color: Colors.white70,
          ),
        ),
      );
    }

    // Calculate grid bounds from all positions
    int minRow = 999999;
    int maxRow = -999999;
    int minCol = 999999;
    int maxCol = -999999;

    for (String positionKey in allPositions) {
      List<String> coords = positionKey.split(',');
      int row = int.parse(coords[0]);
      int col = int.parse(coords[1]);

      minRow = min(minRow, row);
      maxRow = max(maxRow, row);
      minCol = min(minCol, col);
      maxCol = max(maxCol, col);
    }

    // Calculate grid dimensions
    int gridWidth = maxCol - minCol + 1;
    int gridHeight = maxRow - minRow + 1;

    // Use optimized grid cell size for better space utilization
    double cellSize = ResponsiveHelper.getOptimizedGridCellSize(
      context,
      gridWidth,
      gridHeight,
    );

    // Use optimal spacing based on cell size
    double cellSpacing = ResponsiveHelper.getOptimalGridSpacing(
      context,
      cellSize,
    );
    double totalCellSize = cellSize + cellSpacing;

    // Calculate total grid dimensions
    double totalGridWidth = gridWidth * totalCellSize - cellSpacing;
    double totalGridHeight = gridHeight * totalCellSize - cellSpacing;

    // Get available space for grid with more aggressive utilization
    final availableWidth = ResponsiveHelper.getAvailableWidth(context);
    final availableHeight = ResponsiveHelper.getAvailableHeight(context);
    final shouldUseHorizontalLayout =
        ResponsiveHelper.shouldUseHorizontalLayout(context);

    // More aggressive space utilization to minimize gaps
    double maxGridWidth = shouldUseHorizontalLayout
        ? availableWidth *
              0.85 // Increased from 0.8
        : availableWidth * 0.98; // Increased from 0.95
    double maxGridHeight = shouldUseHorizontalLayout
        ? availableHeight *
              0.65 // Increased from 0.6
        : availableHeight * 0.58; // Increased from 0.55

    // Scale grid if it's too large (additional safety scaling)
    double scaleFactor = 1.0;
    if (totalGridWidth > maxGridWidth || totalGridHeight > maxGridHeight) {
      double widthScale = maxGridWidth / totalGridWidth;
      double heightScale = maxGridHeight / totalGridHeight;
      scaleFactor = min(widthScale, heightScale);
    }

    // Apply scale factor
    double scaledCellSize = cellSize * scaleFactor;
    double scaledCellSpacing = cellSpacing * scaleFactor;
    double scaledTotalCellSize = scaledCellSize + scaledCellSpacing;

    double scaledTotalGridWidth =
        gridWidth * scaledTotalCellSize - scaledCellSpacing;
    double scaledTotalGridHeight =
        gridHeight * scaledTotalCellSize - scaledCellSpacing;

    // Create optimized grid with proper centering and minimal gaps
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxGridWidth,
        maxHeight: maxGridHeight,
      ),
      child: Center(
        child: Container(
          width: scaledTotalGridWidth,
          height: scaledTotalGridHeight,
          decoration: BoxDecoration(
            // Optional: Add a subtle background for debugging
            // color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: allPositions.map((positionKey) {
              List<String> coords = positionKey.split(',');
              int originalRow = int.parse(coords[0]);
              int originalCol = int.parse(coords[1]);

              // Calculate offset positions (normalize to 0,0)
              int offsetRow = originalRow - minRow;
              int offsetCol = originalCol - minCol;

              // Calculate pixel positions
              double left = offsetCol * scaledTotalCellSize;
              double top = offsetRow * scaledTotalCellSize;

              String letter = positionToLetter[positionKey] ?? '?';
              bool isPartOfFoundWord = _isPositionInFoundWord(
                viewModel,
                originalRow,
                originalCol,
              );

              return Positioned(
                left: left,
                top: top,
                child: Container(
                  width: scaledCellSize,
                  height: scaledCellSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPartOfFoundWord
                          ? [
                              Colors.green.shade400,
                              Colors.green.shade600,
                              Colors.green.shade800,
                            ]
                          : [
                              Colors.white,
                              Colors.grey.shade100,
                              Colors.grey.shade200,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context) *
                          scaleFactor,
                    ),
                    border: Border.all(
                      color: isPartOfFoundWord
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      width: 1.5 * scaleFactor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6 * scaleFactor,
                        offset: Offset(0, 3 * scaleFactor),
                        spreadRadius: 1 * scaleFactor,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 2 * scaleFactor,
                        offset: Offset(0, -1 * scaleFactor),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: isPartOfFoundWord
                            ? Colors.white
                            : Colors.black87,
                        fontSize: (scaledCellSize * 0.6).clamp(16.0, 32.0),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: isPartOfFoundWord
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  bool _isPositionInFoundWord(GameViewModel viewModel, int row, int col) {
    for (String foundWord in viewModel.game.foundWords) {
      final positions = viewModel.getWordPositions(foundWord);
      for (int i = 0; i < positions.length && i < foundWord.length; i++) {
        final pos = positions[i];
        if (pos.row == row && pos.col == col) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildScoreBox({
    required IconData icon,
    required String value,
    required Color iconColor,
    required Color backgroundColor,
    required BuildContext context,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context),
        vertical: ResponsiveHelper.getResponsiveScoreBoxPadding(context),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: ResponsiveHelper.getResponsiveIconSize(
              context,
              mobile: 18.0,
              tablet: 22.0,
              desktop: 26.0,
            ),
          ),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75,
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
            ),
          ),
        ],
      ),
    );
  }

  // Güzel ayarlar butonu
  Widget _buildBeautifulSettingsButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required List<Color> gradientColors,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveSpacing(context),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.getResponsiveLargeSpacing(context),
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: ResponsiveHelper.getResponsiveIconSize(
                      context,
                      mobile: 55.0,
                      tablet: 65.0,
                      desktop: 75.0,
                    ),
                    height: ResponsiveHelper.getResponsiveIconSize(
                      context,
                      mobile: 55.0,
                      tablet: 65.0,
                      desktop: 75.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: ResponsiveHelper.getResponsiveIconSize(
                        context,
                        mobile: 26.0,
                        tablet: 30.0,
                        desktop: 34.0,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context),
                  ),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.getResponsiveSubtitleFontSize(
                                  context,
                                ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveHelper.getResponsiveSpacing(context) *
                              0.5,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.getResponsiveCaptionFontSize(
                                  context,
                                ),
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: ResponsiveHelper.getResponsiveIconSize(
                        context,
                        mobile: 16.0,
                        tablet: 18.0,
                        desktop: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern ayarlar butonu
  Widget _buildModernSettingsButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required Color backgroundColor,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          ResponsiveHelper.getResponsiveLargeSpacing(context),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 50.0,
                tablet: 60.0,
                desktop: 70.0,
              ),
              height: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 50.0,
                tablet: 60.0,
                desktop: 70.0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0,
                ),
              ),
            ),

            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveSubtitleFontSize(
                        context,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(
                    height:
                        ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveCaptionFontSize(
                        context,
                      ),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Güzel onay dialog'u helper metodu
  Future<bool?> _showBeautifulConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmText,
    Color confirmColor,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: ResponsiveHelper.isTablet(context)
                ? MediaQuery.of(context).size.width * 0.4
                : MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveLargeSpacing(context),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [confirmColor, confirmColor.withOpacity(0.7)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveHelper.getResponsiveSpacing(context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: ResponsiveHelper.getResponsiveIconSize(context),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveSpacing(context),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.getResponsiveTitleFontSize(
                                  context,
                                ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveLargeSpacing(context),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveBodyFontSize(
                        context,
                      ),
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Actions
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsiveLargeSpacing(context),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await SoundService.playButtonClick();
                            Navigator.of(context).pop(false);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveSpacing(
                                context,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveBodyFontSize(
                                      context,
                                    ),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveSpacing(context),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await SoundService.playButtonClick();
                            Navigator.of(context).pop(true);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.getResponsiveSpacing(
                                context,
                              ),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  confirmColor,
                                  confirmColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: confirmColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveBodyFontSize(
                                      context,
                                    ),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Onay dialog'u helper metodu
  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmText,
    Color confirmColor,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveTitleFontSize(context),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await SoundService.playButtonClick();
                Navigator.of(context).pop(false);
              },
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await SoundService.playButtonClick();
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(
                confirmText,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveIconSize(
              context,
              mobile: 60.0,
              tablet: 80.0,
              desktop: 100.0,
            ),
            height: ResponsiveHelper.getResponsiveIconSize(
              context,
              mobile: 60.0,
              tablet: 80.0,
              desktop: 100.0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: backgroundColor == Colors.white
                    ? const Color(0xFF4c51bf)
                    : Colors.white38,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 28.0,
                tablet: 36.0,
                desktop: 44.0,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveCaptionFontSize(context),
              fontWeight: FontWeight.bold,
              color: backgroundColor == Colors.white
                  ? const Color(0xFF4c51bf)
                  : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedGridArea(
    BuildContext context,
    GameViewModel viewModel,
    List<List<String?>> grid,
    int gridRows,
    int gridCols,
    String selectedWord,
  ) {
    return Center(child: _buildOptimizedGrid(context, viewModel, grid));
  }

  Widget _buildSelectedWordOverlay(BuildContext context, String selectedWord) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsivePadding(context),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveLargeSpacing(context),
          vertical: ResponsiveHelper.getResponsiveSpacing(context),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          selectedWord,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
              context,
              mobile: 20.0,
              tablet: 28.0,
              desktop: 36.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildFixedBottomSection(
    BuildContext context,
    GameViewModel viewModel,
    List<String> letters,
  ) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final shouldUseCompactLayout = ResponsiveHelper.shouldUseCompactLayout(
      context,
    );
    final shouldUseHorizontalLayout =
        ResponsiveHelper.shouldUseHorizontalLayout(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsivePadding(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint button
          if (!shouldUseCompactLayout)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  await SoundService.playButtonClick();
                  final hint = viewModel.getHint();
                  if (hint != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('İpucu: $hint'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.amber,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context),
                    vertical: ResponsiveHelper.getResponsiveScoreBoxPadding(
                      context,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: ResponsiveHelper.getResponsiveIconSize(context),
                      ),
                      SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context) *
                            0.5,
                      ),
                      Text(
                        'İpucu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getResponsiveBodyFontSize(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

          // Dynamic letter circle with responsive sizing
          Center(
            child: SizedBox(
              width: _getDynamicLetterCircleSize(context, letters.length),
              height: _getDynamicLetterCircleSize(context, letters.length),
              child: GestureDetector(
                onPanStart: (details) {
                  _handlePanStart(details.localPosition, context);
                },
                onPanUpdate: (details) {
                  _handlePanUpdate(details.localPosition, context);
                },
                onPanEnd: (details) {
                  _handlePanEnd(context);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main circle background with transparency
                    Container(
                      width: _getDynamicLetterCircleSize(
                        context,
                        letters.length,
                      ),
                      height: _getDynamicLetterCircleSize(
                        context,
                        letters.length,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      child: Stack(
                        children: [
                          ..._buildDynamicCircleLetters(
                            letters,
                            selectedIndexes,
                          ),
                          // Shuffle button in center
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () async {
                                  await SoundService.playShuffle();
                                  viewModel.shuffleLetters();
                                },
                                child: Container(
                                  width:
                                      ResponsiveHelper.getResponsiveShuffleButtonSize(
                                        context,
                                      ) *
                                      0.5,
                                  height:
                                      ResponsiveHelper.getResponsiveShuffleButtonSize(
                                        context,
                                      ) *
                                      0.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade400.withOpacity(
                                      0.8,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade500,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.shuffle,
                                    color: Colors.grey.shade700,
                                    size:
                                        ResponsiveHelper.getResponsiveIconSize(
                                          context,
                                        ) *
                                        0.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom painter for drawing lines
                    if (isPanning && linePoints.isNotEmpty)
                      CustomPaint(
                        size: Size(
                          _getDynamicLetterCircleSize(context, letters.length),
                          _getDynamicLetterCircleSize(context, letters.length),
                        ),
                        painter: LinePainter(linePoints),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic letter circle size based on number of letters
  double _getDynamicLetterCircleSize(BuildContext context, int letterCount) {
    final baseSize = ResponsiveHelper.getResponsiveLetterCircleSize(context);

    // Adjust size based on number of letters
    if (letterCount <= 3) {
      return baseSize * 0.8; // Smaller for few letters
    } else if (letterCount <= 5) {
      return baseSize; // Standard size
    } else if (letterCount <= 7) {
      return baseSize * 1.1; // Larger for more letters
    } else {
      return baseSize * 1.2; // Even larger for many letters
    }
  }

  // Dynamic circle letters with responsive positioning
  List<Widget> _buildDynamicCircleLetters(
    List<String> letters,
    List<int> selectedIndexes,
  ) {
    final double circleSize = _getDynamicLetterCircleSize(
      context,
      letters.length,
    );
    final double center = circleSize / 2;
    final double radius = circleSize * 0.32;
    final double letterRadius =
        ResponsiveHelper.getResponsiveLetterSize(context) * 1.5;
    final int total = letters.length;
    List<Widget> widgets = [];

    for (int i = 0; i < total; i++) {
      final double angle = (2 * pi * i) / letters.length - pi / 2;
      final double x = center + radius * cos(angle) - letterRadius;
      final double y = center + radius * sin(angle) - letterRadius;

      final bool isSelected = selectedIndexes.contains(i);

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: Container(
            width: letterRadius * 2,
            height: letterRadius * 2,
            decoration: isSelected
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade600.withOpacity(0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  )
                : null,
            child: Center(
              child: Text(
                letters[i],
                style: TextStyle(
                  fontSize: letterRadius * 1.0,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.black87,
                  shadows: isSelected
                      ? [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

// Custom painter for drawing lines between letters
class LinePainter extends CustomPainter {
  final List<Offset> points;

  LinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i += 2) {
      if (i + 1 < points.length) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
