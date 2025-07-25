import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_model.dart';
import '../../viewmodels/game_view_model.dart';

class WordGrid extends StatelessWidget {
  const WordGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);
    final grid = viewModel.game.grid;

    return _buildOptimizedGrid(context, viewModel, grid);
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
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Grid boş',
          style: TextStyle(fontSize: 16.0, color: Colors.white70),
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

    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final shouldUseHorizontalLayout = isLandscape && screenWidth > 900;

    // Calculate available space for grid - more conservative approach
    double availableWidth = screenWidth;
    double availableHeight = screenHeight;

    // Use more conservative max grid size to prevent overflow
    double maxGridWidth = shouldUseHorizontalLayout
        ? availableWidth *
              0.78 // Slightly increased from 0.75
        : availableWidth * 0.88; // Slightly increased from 0.85
    double maxGridHeight = shouldUseHorizontalLayout
        ? availableHeight *
              0.52 // Slightly increased from 0.5
        : availableHeight * 0.48; // Slightly increased from 0.45

    // Calculate initial cell size based on available space
    double cellSizeFromWidth = maxGridWidth / gridWidth;
    double cellSizeFromHeight = maxGridHeight / gridHeight;

    // Use the smaller of the two to ensure grid fits
    double cellSize = min(cellSizeFromWidth, cellSizeFromHeight);

    // Apply balanced cell size limits
    cellSize = cellSize.clamp(
      screenWidth * 0.065, // Slightly larger minimum
      screenWidth * 0.13, // Slightly larger maximum
    );

    // Add balanced spacing between cells
    double cellSpacing = screenWidth * 0.009; // Slightly more spacing
    double totalCellSize = cellSize + cellSpacing;

    // Calculate total grid dimensions
    double totalGridWidth = gridWidth * totalCellSize - cellSpacing;
    double totalGridHeight = gridHeight * totalCellSize - cellSpacing;

    // Apply scale factor to ensure grid fits within bounds
    double scaleFactor = 1.0;
    if (totalGridWidth > maxGridWidth || totalGridHeight > maxGridHeight) {
      double widthScale = maxGridWidth / totalGridWidth;
      double heightScale = maxGridHeight / totalGridHeight;
      scaleFactor = min(widthScale, heightScale);
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
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxGridWidth,
        maxHeight: maxGridHeight,
      ),
      child: Center(
        child: Container(
          width: finalTotalGridWidth,
          height: finalTotalGridHeight,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Stack(
            children: allPositions.map((positionKey) {
              List<String> coords = positionKey.split(',');
              int originalRow = int.parse(coords[0]);
              int originalCol = int.parse(coords[1]);

              // Calculate offset positions (normalize to 0,0)
              int offsetRow = originalRow - minRow;
              int offsetCol = originalCol - minCol;

              // Calculate pixel positions
              double left = offsetCol * finalTotalCellSize;
              double top = offsetRow * finalTotalCellSize;

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
                    borderRadius: BorderRadius.circular(screenWidth * 0.015),
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
                        fontSize: (screenWidth * 0.038).clamp(
                          screenWidth * 0.028,
                          screenWidth * 0.055,
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
}
