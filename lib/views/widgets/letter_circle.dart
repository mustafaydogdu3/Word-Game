import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/sound_service.dart';
import '../../viewmodels/game_view_model.dart';
import 'line_painter.dart';

class LetterCircle extends StatelessWidget {
  final List<String> letters;
  final List<int> selectedIndexes;
  final List<Offset> linePoints;
  final Function(String) onWordSelected;
  final VoidCallback onShuffle;
  final GlobalKey circleKey;
  // Callbacks for selection state changes
  final Function(List<int>) onSelectionChanged;
  final Function(List<Offset>) onLinePointsChanged;

  const LetterCircle({
    super.key,
    required this.letters,
    required this.selectedIndexes,
    required this.linePoints,
    required this.onWordSelected,
    required this.onShuffle,
    required this.circleKey,
    required this.onSelectionChanged,
    required this.onLinePointsChanged,
  });

  void _handlePanStart(Offset position, BuildContext context) {
    // Clear selection and start new selection
    final newSelectedIndexes = <int>[];
    final newLinePoints = <Offset>[];

    // WOW tarzı harf seçimi - global koordinat uyumlu
    final circleSize = _getDynamicLetterCircleSize(context, letters.length);
    final touchRadius = circleSize * 0.13; // Harf çapına göre ayarlanmış
    final center = circleSize / 2;
    final radius = circleSize * 0.35;

    // Global koordinat dönüşümü için RenderBox al
    final RenderBox? box =
        circleKey.currentContext?.findRenderObject() as RenderBox?;
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
          // İlk harfi ekle - sadece harf pozisyonu
          newSelectedIndexes.add(i);
          newLinePoints.add(localLetterCenter); // Sadece harf pozisyonu
          SoundService.playWordFound();

          print(
            'LetterCircle: Added first letter ${letters[i]}, selection: ${newSelectedIndexes.map((idx) => letters[idx]).join()}',
          );

          // Notify parent of selection change
          onSelectionChanged(newSelectedIndexes);
          onLinePointsChanged(newLinePoints);
          break;
        }
      }
    }
  }

  void _handlePanUpdate(Offset position, BuildContext context) {
    // WOW tarzı harf seçimi - global koordinat uyumlu
    final circleSize = _getDynamicLetterCircleSize(context, letters.length);
    final touchRadius = circleSize * 0.13; // Harf çapına göre ayarlanmış
    final center = circleSize / 2;
    final radius = circleSize * 0.35;

    // Global koordinat dönüşümü için RenderBox al
    final RenderBox? box =
        circleKey.currentContext?.findRenderObject() as RenderBox?;
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
            final newSelectedIndexes = List<int>.from(selectedIndexes)..add(i);
            final newLinePoints = List<Offset>.from(linePoints)
              ..add(localLetterCenter);
            SoundService.playWordFound();

            print(
              'LetterCircle: Added letter ${letters[i]}, selection: ${newSelectedIndexes.map((idx) => letters[idx]).join()}',
            );

            // Notify parent of selection change
            onSelectionChanged(newSelectedIndexes);
            onLinePointsChanged(newLinePoints);
          } else {
            // Geriye doğru hareket - önceki harfleri kaldır
            final existingIndex = selectedIndexes.indexOf(i);
            if (existingIndex < selectedIndexes.length - 1) {
              // Bu harften sonraki tüm harfleri kaldır
              final newSelectedIndexes = selectedIndexes.sublist(
                0,
                existingIndex + 1,
              );
              final newLinePoints = linePoints.sublist(0, existingIndex + 1);
              SoundService.playError();

              print(
                'LetterCircle: Removed letters, selection: ${newSelectedIndexes.map((idx) => letters[idx]).join()}',
              );

              // Notify parent of selection change
              onSelectionChanged(newSelectedIndexes);
              onLinePointsChanged(newLinePoints);
            }
          }
          // Remove break to allow continuous dragging
        }
      }
    }
  }

  void _handlePanEnd(BuildContext context) {
    // Working logic: Form word from selected letters
    final selectedWord = selectedIndexes
        .where((i) => i >= 0 && i < letters.length)
        .map((i) => letters[i])
        .join();

    if (selectedWord.isNotEmpty) {
      print('Player selected word from circle: "$selectedWord"');
      onWordSelected(selectedWord);
    }

    // Clear selection for next interaction
    print('LetterCircle: Clearing selection');
    onSelectionChanged([]);
    onLinePointsChanged([]);
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
    BuildContext context,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenWidth > screenHeight;
    final shouldUseCompactLayout = isSmallScreen || isLandscape;

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
                  final viewModel = Provider.of<GameViewModel>(
                    context,
                    listen: false,
                  );
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
                  key: circleKey,
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
                                context,
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
                                      onShuffle();
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
}
