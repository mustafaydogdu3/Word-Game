import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_model.dart';
import '../services/sound_service.dart';
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

  void _handlePanStart(Offset position, BuildContext context) {
    final letters = Provider.of<GameViewModel>(
      context,
      listen: false,
    ).game.letters;

    setState(() {
      selectedIndexes.clear();
      linePoints.clear();
      isPanning = true;

      // WOW tarzı harf seçimi - global koordinat uyumlu
      final circleSize = _getDynamicLetterCircleSize(context, letters.length);
      final touchRadius = circleSize * 0.13; // Harf çapına göre ayarlanmış
      final center = circleSize / 2;
      final radius = circleSize * 0.35;

      // Global koordinat dönüşümü için RenderBox al
      final RenderBox? box =
          _circleKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset circleTopLeft = box.localToGlobal(Offset.zero);

        for (int i = 0; i < letters.length; i++) {
          final double angle = (2 * pi * i) / letters.length - pi / 2;
          final Offset localLetterCenter = Offset(
            center + radius * cos(angle),
            center + radius * sin(angle),
          );
          // Local koordinatı global koordinata çevir
          final Offset letterCenter = localLetterCenter + circleTopLeft;

          if ((position - letterCenter).distance < touchRadius) {
            if (!selectedIndexes.contains(i)) {
              // İlk harfi ekle - sadece harf pozisyonu
              selectedIndexes.add(i);
              linePoints.add(localLetterCenter); // Sadece harf pozisyonu
              SoundService.playWordFound();
            }
            break;
          }
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
      // WOW tarzı harf seçimi - global koordinat uyumlu
      final circleSize = _getDynamicLetterCircleSize(context, letters.length);
      final touchRadius = circleSize * 0.13; // Harf çapına göre ayarlanmış
      final center = circleSize / 2;
      final radius = circleSize * 0.35;

      // Global koordinat dönüşümü için RenderBox al
      final RenderBox? box =
          _circleKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset circleTopLeft = box.localToGlobal(Offset.zero);

        for (int i = 0; i < letters.length; i++) {
          final double angle = (2 * pi * i) / letters.length - pi / 2;
          final Offset localLetterCenter = Offset(
            center + radius * cos(angle),
            center + radius * sin(angle),
          );
          // Local koordinatı global koordinata çevir
          final Offset letterCenter = localLetterCenter + circleTopLeft;

          if ((position - letterCenter).distance < touchRadius) {
            if (!selectedIndexes.contains(i)) {
              // Yeni harf ekleme - ileri sürükleme
              selectedIndexes.add(i);
              linePoints.add(localLetterCenter); // Sadece harf pozisyonu
              SoundService.playWordFound();
            } else {
              // Geriye doğru hareket - önceki harfleri kaldır
              final existingIndex = selectedIndexes.indexOf(i);
              if (existingIndex < selectedIndexes.length - 1) {
                // Bu harften sonraki tüm harfleri kaldır
                final removeCount = selectedIndexes.length - existingIndex - 1;
                for (int j = 0; j < removeCount; j++) {
                  selectedIndexes.removeLast();
                  linePoints.removeLast(); // Harf pozisyonu
                }
                SoundService.playError();
              }
            }
            break; // Sadece bir harf işle
          }
        }
      }
    });
  }

  void _handlePanEnd(BuildContext context) {
    setState(() {
      isPanning = false;
    });

    // Working logic: Form word from selected letters
    final viewModel =
        _viewModel ?? Provider.of<GameViewModel>(context, listen: false);
    final letters = viewModel.game.letters;

    // Convert selected letter indexes to word in selection order
    final selectedWord = selectedIndexes
        .where((i) => i >= 0 && i < letters.length)
        .map((i) => letters[i])
        .join();

    if (selectedWord.isNotEmpty) {
      print('Player selected word from circle: "$selectedWord"');
      viewModel.checkWord(selectedWord);
    }

    // Clear selection for next interaction
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
            width: MediaQuery.of(context).size.width * 0.6,
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
                  padding: EdgeInsets.all(16.0),
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
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4a4fb5), Color(0xFF7b5fb0)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28.0,
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          'Ayarlar',
                          style: TextStyle(
                            fontSize: 20.0,
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
                          padding: EdgeInsets.all(12.0 * 0.5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 20.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  padding: EdgeInsets.all(24.0),
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

                      SizedBox(height: 12.0),

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

                      SizedBox(height: 12.0),

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth > 768;
    final isLandscape = screenWidth > screenHeight;
    final shouldUseCompactLayout = isSmallScreen || isLandscape;

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

                // Grid area - Moved higher up with responsive positioning
                Positioned(
                  top: screenHeight * 0.08,
                  left: 0,
                  right: 0,
                  bottom: screenHeight * 0.45,
                  child: _buildFixedGridArea(
                    context,
                    viewModel,
                    grid,
                    gridRows,
                    gridCols,
                    selectedWord,
                  ),
                ),

                // Selected word display - Positioned above letter circle
                if (selectedWord.isNotEmpty)
                  Positioned(
                    bottom: screenHeight * 0.32,
                    left: 0,
                    right: 0,
                    child: _buildSelectedWordOverlay(context, selectedWord),
                  ),

                // Letter circle - Responsive positioning at bottom
                Positioned(
                  bottom: screenHeight * 0.05,
                  left: 0,
                  right: 0,
                  child: _buildFixedBottomSection(context, viewModel, letters),
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
          padding: EdgeInsets.all(24.0),
          margin: EdgeInsets.all(16.0),
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
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),

              SizedBox(height: 24.0),

              // Level completed text
              Text(
                'SEVİYE TAMAMLANDI!',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.0),

              // Level info
              Text(
                'Seviye ${viewModel.game.currentLevel}',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 12.0),

              // Next level info
              Text(
                'Sonraki seviyeye geçiliyor...',
                style: TextStyle(
                  fontSize: 12.0,
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
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
              SizedBox(width: 12.0),
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
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  'Seviye ${viewModel.game.currentLevel}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              GestureDetector(
                onTap: () async {
                  await SoundService.playButtonClick();
                  SettingsDialog.show(context);
                },
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.settings, color: Colors.white, size: 20.0),
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
    // Use the actual grid size from JSON instead of calculating from word positions
    int gridRows = viewModel.game.gridRows;
    int gridCols = viewModel.game.gridCols;

    print('Building grid with size: ${gridCols}x$gridRows from JSON');

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

    // Use the actual grid dimensions from JSON
    int gridWidth = gridCols;
    int gridHeight = gridRows;

    // Dynamic grid sizing with better proportions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenWidth > screenHeight;

    // Use more available space for grid with responsive sizing
    double availableGridWidth =
        screenWidth * 0.98; // Use almost all screen width
    double availableGridHeight = screenHeight * 0.5; // Use more vertical space

    // Calculate optimal cell size based on grid dimensions and available space
    double cellSizeFromWidth = availableGridWidth / gridWidth;
    double cellSizeFromHeight = availableGridHeight / gridHeight;

    // Use the smaller of the two to ensure grid fits
    double cellSize = min(cellSizeFromWidth, cellSizeFromHeight);

    // Ensure reasonable cell sizes with responsive limits
    cellSize = cellSize.clamp(
      screenWidth * 0.08, // Larger minimum cell size
      screenWidth * 0.15, // Larger maximum cell size
    );

    // Add responsive spacing between cells
    double cellSpacing =
        screenWidth * 0.01; // Fixed spacing based on screen width
    double totalCellSize = cellSize + cellSpacing;

    // Calculate total grid dimensions
    double totalGridWidth = gridWidth * totalCellSize - cellSpacing;
    double totalGridHeight = gridHeight * totalCellSize - cellSpacing;

    // Check for overflow and apply scale factor if needed - less aggressive scaling
    double scaleFactor = 1.0;
    if (totalGridWidth > availableGridWidth ||
        totalGridHeight > availableGridHeight) {
      double widthScale = availableGridWidth / totalGridWidth;
      double heightScale = availableGridHeight / totalGridHeight;
      scaleFactor =
          min(widthScale, heightScale) * 0.98; // Only 2% safety margin
    }

    // Apply scale factor to prevent overflow
    double finalCellSize = cellSize * scaleFactor;
    double finalCellSpacing = cellSpacing * scaleFactor;
    double finalTotalCellSize = finalCellSize + finalCellSpacing;

    double finalTotalGridWidth =
        gridWidth * finalTotalCellSize - finalCellSpacing;
    double finalTotalGridHeight =
        gridHeight * finalTotalCellSize - finalCellSpacing;

    // Create grid with only cells that have letters
    return SizedBox(
      width: availableGridWidth,
      height: availableGridHeight,
      child: Center(
        child: Container(
          width: finalTotalGridWidth,
          height: finalTotalGridHeight,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Stack(
            children: allPositions.map((positionKey) {
              List<String> coords = positionKey.split(',');
              int row = int.parse(coords[0]);
              int col = int.parse(coords[1]);

              String letter = positionToLetter[positionKey] ?? '';
              bool isPartOfFoundWord = _isPositionInFoundWord(
                viewModel,
                row,
                col,
              );

              // Calculate pixel positions
              double left = col * finalTotalCellSize;
              double top = row * finalTotalCellSize;

              return Positioned(
                left: left,
                top: top,
                child: Container(
                  width: finalCellSize,
                  height: finalCellSize,
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
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(
                      color: isPartOfFoundWord
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      width: screenWidth * 0.002,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                        spreadRadius: 0.5,
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
                        fontSize: (screenWidth * 0.04).clamp(
                          screenWidth * 0.03,
                          screenWidth * 0.06,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        shadows: isPartOfFoundWord
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(1, 1),
                                  blurRadius: 1,
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
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20.0),
          SizedBox(width: 12.0 * 0.75),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
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
        margin: EdgeInsets.only(bottom: 12.0),
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
              padding: EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 65.0,
                    height: 65.0,
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
                    child: Icon(icon, color: iconColor, size: 26.0),
                  ),

                  SizedBox(width: 12.0),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12.0 * 0.5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Container(
                    padding: EdgeInsets.all(12.0 * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16.0,
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
        padding: EdgeInsets.all(24.0),
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
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
              ),
              child: Icon(icon, color: iconColor, size: 24.0),
            ),

            SizedBox(width: 12.0),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.0 * 0.5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.0,
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
              size: 16.0,
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
            width: MediaQuery.of(context).size.width * 0.4,
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
                  padding: EdgeInsets.all(24.0),
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
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20.0,
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
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Actions
                Container(
                  padding: EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await SoundService.playButtonClick();
                            Navigator.of(context).pop(false);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await SoundService.playButtonClick();
                            Navigator.of(context).pop(true);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
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
                                fontSize: 12.0,
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
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 12.0, color: Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await SoundService.playButtonClick();
                Navigator.of(context).pop(false);
              },
              child: Text(
                'İptal',
                style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
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
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
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
            width: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.width * 0.15,
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
              size: MediaQuery.of(context).size.width * 0.07,
            ),
          ),
          SizedBox(height: 12.0),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.0,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.015,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: screenWidth * 0.02,
              offset: Offset(0, screenHeight * 0.005),
            ),
          ],
        ),
        child: Text(
          selectedWord,
          style: TextStyle(
            fontSize: (screenWidth * 0.05).clamp(
              screenWidth * 0.04,
              screenWidth * 0.08,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.0,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenWidth > screenHeight;
    final shouldUseCompactLayout = isSmallScreen || isLandscape;
    final shouldUseHorizontalLayout = isLandscape && screenWidth > 900;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: screenWidth * 0.01,
                        offset: Offset(0, screenHeight * 0.002),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: screenWidth * 0.05,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        'İpucu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SizedBox(height: screenHeight * 0.015),

          // Responsive letter circle positioned at bottom with gesture handling
          Center(
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final double circleSize = _getDynamicLetterCircleSize(
                  context,
                  letters.length,
                );
                return SizedBox(
                  width: circleSize,
                  height: circleSize,
                  key: _circleKey,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _handlePanStart(details.globalPosition, context);
                    },
                    onPanUpdate: (details) {
                      _handlePanUpdate(details.globalPosition, context);
                    },
                    onPanEnd: (details) {
                      _handlePanEnd(context);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main circle background with transparency
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          child: Stack(
                            children: [
                              // Letters arranged around the circle
                              ..._buildDynamicCircleLetters(
                                letters,
                                selectedIndexes,
                              ),
                              // WOW tarzı shuffle button in center - saydam arka plan
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () async {
                                      await SoundService.playShuffle();
                                      // Shuffle işlemini çalıştır
                                      final viewModel =
                                          Provider.of<GameViewModel>(
                                            context,
                                            listen: false,
                                          );
                                      viewModel.shuffleLetters();

                                      // Force UI update
                                      setState(() {
                                        // Clear any ongoing selection
                                        selectedIndexes.clear();
                                        linePoints.clear();
                                        isPanning = false;
                                      });
                                    },
                                    child: SizedBox(
                                      width: screenWidth * 0.12, // Daha büyük
                                      height: screenWidth * 0.12, // Daha büyük

                                      child: Icon(
                                        Icons.shuffle,
                                        color: Colors
                                            .grey
                                            .shade800, // Daha koyu renk
                                        size:
                                            screenWidth *
                                            0.06, // Daha büyük ikon
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Custom painter for drawing connecting lines
                        if (linePoints.isNotEmpty)
                          CustomPaint(
                            size: Size(circleSize, circleSize),
                            painter: LinePainter(
                              linePoints,
                              screenWidth * 0.06,
                            ), // Harf yarıçapını geç
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Calculate dynamic circle size for responsive design
  double _getDynamicLetterCircleSize(BuildContext context, int letterCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

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

  // Build letters arranged in circle using trigonometric positioning
  List<Widget> _buildDynamicCircleLetters(
    List<String> letters,
    List<int> selectedIndexes,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double circleSize = _getDynamicLetterCircleSize(
      context,
      letters.length,
    );
    final double center = circleSize / 2;
    final double radius = circleSize * 0.35; // Letter placement radius
    final double letterRadius = screenWidth * 0.06; // Responsive letter size
    final int total = letters.length;
    List<Widget> widgets = [];

    for (int i = 0; i < total; i++) {
      // Calculate position using trigonometric angle: (2π * i / n)
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
                    color: Colors.orange.shade600.withOpacity(0.9),
                    border: Border.all(color: Colors.orange.shade700, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  )
                : BoxDecoration(
                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
            child: Center(
              child: Text(
                letters[i],
                style: TextStyle(
                  fontSize: letterRadius * 1.2,
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
                      : [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0.5, 0.5),
                            blurRadius: 1,
                          ),
                        ],
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

// WOW tarzı CustomPainter - center-to-center drawing with dots
class LinePainter extends CustomPainter {
  final List<Offset> points;
  final double letterRadius;

  LinePainter(this.points, this.letterRadius);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // WOW tarzı çizgi çizimi - center to center
    final paint = Paint()
      ..color = Colors.orange.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Glow efekti
    final glowPaint = Paint()
      ..color = Colors.orange.shade400.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Nokta çizimi için
    final dotPaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.fill;

    // Tüm noktalar harf merkezleri
    final List<Offset> letterCenters = points;

    if (letterCenters.length < 2) return;

    // Her segment için ayrı çizgi çiz - edge to edge
    for (int i = 0; i < letterCenters.length - 1; i++) {
      final currentCenter = letterCenters[i];
      final nextCenter = letterCenters[i + 1];

      // Mevcut harfin kenar noktasını hesapla
      final startEdge = _getCircleEdgePoint(currentCenter, nextCenter);

      // Sonraki harfin kenar noktasını hesapla
      final endEdge = _getCircleEdgePoint(nextCenter, currentCenter);

      // Her segment için ayrı path oluştur - edge to edge
      final segmentPath = Path();
      segmentPath.moveTo(startEdge.dx, startEdge.dy);
      segmentPath.lineTo(endEdge.dx, endEdge.dy);

      // Segment'i çiz (glow ve ana çizgi)
      canvas.drawPath(segmentPath, glowPaint);
      canvas.drawPath(segmentPath, paint);
    }

    // Her harf için kenar noktasında dot çiz
    for (int i = 0; i < letterCenters.length; i++) {
      final currentCenter = letterCenters[i];
      final nextCenter = i + 1 < letterCenters.length
          ? letterCenters[i + 1]
          : null;
      final prevCenter = i > 0 ? letterCenters[i - 1] : null;

      // Nokta pozisyonunu hesapla - kenarda
      Offset dotPosition;
      if (i == 0 && nextCenter != null) {
        // İlk harf - sonraki harfe doğru kenar
        dotPosition = _getCircleEdgePoint(currentCenter, nextCenter);
      } else if (i == letterCenters.length - 1 && prevCenter != null) {
        // Son harf - önceki harfe doğru kenar
        dotPosition = _getCircleEdgePoint(currentCenter, prevCenter);
      } else if (prevCenter != null && nextCenter != null) {
        // Orta harfler - iki yöne de kenar hesapla ve ortalaması
        final edge1 = _getCircleEdgePoint(currentCenter, prevCenter);
        final edge2 = _getCircleEdgePoint(currentCenter, nextCenter);
        dotPosition = Offset(
          (edge1.dx + edge2.dx) / 2,
          (edge1.dy + edge2.dy) / 2,
        );
      } else {
        // Fallback - merkez nokta
        dotPosition = currentCenter;
      }

      canvas.drawCircle(dotPosition, 5.0, dotPaint);
    }
  }

  // Çember kenarındaki noktayı hesapla - normalized direction ile
  Offset _getCircleEdgePoint(Offset center, Offset target) {
    final direction = target - center;
    final distance = direction.distance;
    if (distance == 0) return center;

    final normalizedDirection = direction / distance;
    return center + normalizedDirection * letterRadius;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
