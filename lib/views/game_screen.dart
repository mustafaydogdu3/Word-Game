import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sound_service.dart';
import '../viewmodels/game_view_model.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<int> selectedIndexes = [];
  List<Offset> linePoints = [];
  bool isPanning = false;

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
      final touchRadius = 50.0;
      for (int i = 0; i < letters.length; i++) {
        final double angle = (2 * pi * i) / letters.length - pi / 2;
        final double centerX = 200;
        final double centerY = 200;
        final double r = 140;
        final letterCenter = Offset(
          centerX + r * cos(angle),
          centerY + r * sin(angle),
        );
        if ((position - letterCenter).distance < touchRadius) {
          selectedIndexes.add(i);
          linePoints.add(letterCenter);
          // Play word_found sound when starting letter selection
          SoundService.playWordFound();
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
      final touchRadius = 50.0;
      for (int i = 0; i < letters.length; i++) {
        final double angle = (2 * pi * i) / letters.length - pi / 2;
        final double centerX = 200;
        final double centerY = 200;
        final double r = 140;
        final letterCenter = Offset(
          centerX + r * cos(angle),
          centerY + r * sin(angle),
        );

        if ((position - letterCenter).distance < touchRadius) {
          // Check if this letter is already selected
          if (selectedIndexes.contains(i)) {
            // If it's not the last selected letter, remove letters after it (going back)
            final currentIndex = selectedIndexes.indexOf(i);
            if (currentIndex < selectedIndexes.length - 1) {
              // Remove letters after this one
              final lettersToRemove = selectedIndexes.length - currentIndex - 1;
              for (int j = 0; j < lettersToRemove; j++) {
                selectedIndexes.removeLast();
                if (linePoints.length >= 2) {
                  linePoints.removeLast();
                  linePoints.removeLast();
                }
              }
              // Update the current line endpoint to this letter
              if (linePoints.isNotEmpty) {
                linePoints.last = letterCenter;
              }
            }
          } else {
            // Add new letter to selection
            selectedIndexes.add(i);
            linePoints.last = letterCenter;
            linePoints.add(letterCenter);
          }
          break;
        }
      }
    });
  }

  void _handlePanEnd(BuildContext context) async {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    final letters = viewModel.game.letters;
    final selectedWord = selectedIndexes
        .where((i) => i >= 0 && i < letters.length)
        .map((i) => letters[i])
        .join();

    if (selectedWord.isNotEmpty) {
      final wasWordFound =
          viewModel.game.targetWords.contains(selectedWord.toUpperCase()) &&
          !viewModel.game.foundWords.contains(selectedWord.toUpperCase());

      viewModel.checkWord(selectedWord);

      // Play sound only for valid words found
      if (wasWordFound) {
        await SoundService.playWordFound();

        // Check if level completed after this word
        if (viewModel.game.isCompleted) {
          Future.delayed(Duration(milliseconds: 500), () async {
            await SoundService.playLevelComplete();
          });
        }
      }
      // No sound for invalid words - just remove the error sound
    }

    setState(() {
      isPanning = false;
      selectedIndexes.clear();
      linePoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);

    // Show loading screen while initializing
    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Kelimeler yükleniyor...', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    final letters = viewModel.game.letters;
    final selectedWord = selectedIndexes
        .where((i) => i >= 0 && i < letters.length)
        .map((i) => letters[i])
        .join();
    final grid = viewModel.game.grid;

    return Scaffold(
      body: Stack(
        children: [
          // Egyptian desert background
          Container(
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
            ),
          ),
          // Egyptian landscape silhouette
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 400,
              child: CustomPaint(
                painter: EgyptianLandscapePainter(),
                size: Size(double.infinity, 400),
              ),
            ),
          ),
          // Top score and settings
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _scoreBox(
                        icon: Icons.diamond,
                        value: '900',
                        iconColor: Colors.green,
                        backgroundColor: Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      _scoreBox(
                        icon: Icons.water_drop,
                        value: '10',
                        iconColor: Colors.blue,
                        backgroundColor: Colors.black87,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Level indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level ${viewModel.game.currentLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await SoundService.playButtonClick();
                            _showSettingsDialog(context);
                          },
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Puzzle grid
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 140),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: grid.asMap().entries.map((rowEntry) {
                  final rowIndex = rowEntry.key;
                  final row = rowEntry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: row.asMap().entries.map((cellEntry) {
                      final colIndex = cellEntry.key;
                      final cell = cellEntry.value;

                      if (cell == null)
                        return const SizedBox(width: 62, height: 62);

                      // Find which letter should be displayed at this position
                      String? displayLetter;
                      bool isPartOfFoundWord = false;

                      // Check each found word to see if this position contains a letter
                      for (String foundWord in viewModel.game.foundWords) {
                        final positions = viewModel.getWordPositions(foundWord);
                        for (
                          int i = 0;
                          i < positions.length && i < foundWord.length;
                          i++
                        ) {
                          final pos = positions[i];
                          if (pos.row == rowIndex && pos.col == colIndex) {
                            displayLetter = foundWord[i];
                            isPartOfFoundWord = true;
                            break;
                          }
                        }
                        if (isPartOfFoundWord) break;
                      }

                      return Container(
                        margin: const EdgeInsets.all(4),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isPartOfFoundWord
                              ? Colors.green.withOpacity(0.8)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayLetter ?? '',
                            style: TextStyle(
                              color: isPartOfFoundWord
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
          // Letter circle - positioned lower and larger
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: SizedBox(
                width: 400,
                height: 400,
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
                      // Main circle background
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Custom painter for drawing lines
                      if (isPanning && linePoints.isNotEmpty)
                        CustomPaint(
                          size: const Size(400, 400),
                          painter: LinePainter(linePoints),
                        ),
                      // Letters around the circle
                      ..._buildCircleLetters(letters, selectedIndexes),
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
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.shuffle,
                                color: Colors.black54,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Lightbulb hint button - positioned at right center of screen
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.5 - 32,
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      '${viewModel.game.targetWords.length - viewModel.game.foundWords.length}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Selected word display
          if (selectedWord.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    selectedWord,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scoreBox({
    required IconData icon,
    required String value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCircleLetters(
    List<String> letters,
    List<int> selectedIndexes,
  ) {
    final double center = 200;
    final double radius = 140;
    final double letterRadius = 40;
    final int total = letters.length;
    List<Widget> widgets = [];

    for (int i = 0; i < total; i++) {
      final double angle = (2 * pi * i) / letters.length - pi / 2;
      final double x = center + radius * cos(angle) - letterRadius;
      final double y = center + radius * sin(angle) - letterRadius;

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: Container(
            width: letterRadius * 2,
            height: letterRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedIndexes.contains(i) ? Colors.orange : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                letters[i],
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: selectedIndexes.contains(i)
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            height: 400,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5a67d8), // Purple blue at top
                  Color(0xFF667eea), // Lighter purple blue
                  Color(0xFF764ba2), // Deep purple at bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4c51bf), // Dark purple border
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Close button
                Positioned(
                  top: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Title
                      const Text(
                        'AYARLAR',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'BÖLÜM 6',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 40),
                      // Settings buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSettingsButton(
                            icon: Icons.home,
                            label: 'MENÜ',
                            iconColor: const Color(0xFF4c51bf),
                            backgroundColor: Colors.white,
                            onTap: () async {
                              await SoundService.playButtonClick();
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.of(
                                context,
                              ).pop(); // Go back to main menu
                            },
                          ),
                          _buildSettingsButton(
                            icon: SoundService.isSoundEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            label: 'SES',
                            iconColor: Colors.white,
                            backgroundColor: Colors.white24,
                            onTap: () async {
                              await SoundService.toggleSound();
                              Navigator.of(context).pop(); // Close dialog
                              _showSettingsDialog(context); // Reopen to refresh
                            },
                          ),
                          _buildSettingsButton(
                            icon: Icons.music_note,
                            label: 'MÜZİK',
                            iconColor: Colors.white,
                            backgroundColor: Colors.white24,
                            onTap: () async {
                              await SoundService.playButtonClick();
                              // Toggle music
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      // Help section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.mail_outline,
                              color: Color(0xFF4c51bf),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'YARDIM VE DESTEK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
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
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
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
}

// Custom painter for Egyptian landscape
class EgyptianLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw sphinx silhouette
    path.moveTo(size.width * 0.3, size.height);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.6,
      size.width * 0.4,
      size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.7,
      size.width * 0.6,
      size.height * 0.75,
    );
    path.lineTo(size.width * 0.65, size.height);
    path.close();

    // Draw pyramids
    final pyramidPath = Path();
    // Left pyramid
    pyramidPath.moveTo(size.width * 0.1, size.height);
    pyramidPath.lineTo(size.width * 0.15, size.height * 0.6);
    pyramidPath.lineTo(size.width * 0.25, size.height);
    pyramidPath.close();

    // Right pyramid
    pyramidPath.moveTo(size.width * 0.75, size.height);
    pyramidPath.lineTo(size.width * 0.8, size.height * 0.5);
    pyramidPath.lineTo(size.width * 0.9, size.height);
    pyramidPath.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(pyramidPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
