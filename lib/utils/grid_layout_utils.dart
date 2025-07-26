import 'dart:math';

/// Utility class for calculating optimal grid layouts
class GridLayoutUtils {
  /// Calculates optimal cell size based on available space and grid dimensions
  static double calculateOptimalCellSize({
    required double availableWidth,
    required double availableHeight,
    required int gridRows,
    required int gridCols,
  }) {
    // Calculate base cell size from available space (responsive)
    double cellSizeFromWidth =
        availableWidth / (gridCols + 0.5); // Small margin for spacing
    double cellSizeFromHeight =
        availableHeight / (gridRows + 0.5); // Small margin for spacing

    // Use the smaller dimension to ensure grid fits
    double baseCellSize = min(cellSizeFromWidth, cellSizeFromHeight);

    // Apply grid size constraints
    return _applyGridSizeConstraints(baseCellSize, gridRows, gridCols);
  }

  /// Applies size constraints based on grid complexity
  static double _applyGridSizeConstraints(
    double baseCellSize,
    int gridRows,
    int gridCols,
  ) {
    int totalCells = gridRows * gridCols;

    // Apply size constraints based on grid complexity
    if (totalCells <= 9) {
      // Small grids (3x3): larger cells
      return baseCellSize * 1.1;
    } else if (totalCells <= 25) {
      // Medium grids (4x4, 5x5): normal cells
      return baseCellSize;
    } else if (totalCells <= 49) {
      // Large grids (6x6, 7x7): smaller cells
      return baseCellSize * 0.85;
    } else {
      // Very large grids (8x8+): much smaller cells
      return baseCellSize * 0.7;
    }
  }

  /// Calculates optimal font size based on cell size and grid dimensions
  static double calculateOptimalFontSize(double cellSize, int gridRows) {
    // Base font size calculation
    double baseFontSize = cellSize * 0.6; // 60% of cell size

    // Adjust based on grid size
    if (gridRows <= 4) {
      baseFontSize = cellSize * 0.7; // Larger for small grids
    } else if (gridRows <= 6) {
      baseFontSize = cellSize * 0.65; // Medium for medium grids
    } else if (gridRows <= 8) {
      baseFontSize = cellSize * 0.55; // Smaller for large grids
    } else {
      baseFontSize = cellSize * 0.45; // Smallest for very large grids
    }

    // Ensure font size is within reasonable bounds
    return baseFontSize.clamp(12.0, 48.0);
  }

  /// Calculates spacing between cells
  static double calculateCellSpacing(double cellSize) {
    return cellSize * 0.03; // Responsive spacing
  }

  /// Calculates total grid dimensions
  static Map<String, double> calculateGridDimensions({
    required double cellSize,
    required int gridRows,
    required int gridCols,
  }) {
    double cellSpacing = calculateCellSpacing(cellSize);
    double totalCellSize = cellSize + cellSpacing;

    double totalGridWidth = gridCols * totalCellSize - cellSpacing;
    double totalGridHeight = gridRows * totalCellSize - cellSpacing;

    return {
      'width': totalGridWidth,
      'height': totalGridHeight,
      'cellSpacing': cellSpacing,
      'totalCellSize': totalCellSize,
    };
  }

  /// Checks if grid needs scrolling
  static bool needsScrolling({
    required double gridHeight,
    required double availableHeight,
  }) {
    return gridHeight > availableHeight;
  }

  /// Calculates responsive constraints for different screen sizes
  static Map<String, double> calculateResponsiveConstraints({
    required double screenWidth,
    required double screenHeight,
  }) {
    return {
      'maxGridWidth': screenWidth * 0.95,
      'maxGridHeight': screenHeight * 0.38, // 38% to leave 50% for bottom area
      'minCellSize':
          screenWidth * 0.04, // Smaller minimum for better responsiveness
      'maxCellSize':
          screenWidth * 0.12, // Smaller maximum to prevent oversized cells
    };
  }

  /// Calculates grid area constraints based on screen size and grid dimensions
  static Map<String, double> calculateGridAreaConstraints({
    required double screenWidth,
    required double screenHeight,
    required int gridRows,
    required int gridCols,
  }) {
    // Calculate maximum available space for grid
    double maxGridHeight = screenHeight * 0.38; // 38% of screen height
    double maxGridWidth = screenWidth * 0.95; // 95% of screen width

    // Calculate optimal cell size for this grid
    double optimalCellSize = calculateOptimalCellSize(
      availableWidth: maxGridWidth,
      availableHeight: maxGridHeight,
      gridRows: gridRows,
      gridCols: gridCols,
    );

    // Get grid dimensions
    Map<String, double> gridDimensions = calculateGridDimensions(
      cellSize: optimalCellSize,
      gridRows: gridRows,
      gridCols: gridCols,
    );

    return {
      'cellSize': optimalCellSize,
      'gridWidth': gridDimensions['width']!,
      'gridHeight': gridDimensions['height']!,
      'maxAvailableHeight': maxGridHeight,
      'maxAvailableWidth': maxGridWidth,
      'needsScrolling': (gridDimensions['height']! > maxGridHeight) ? 1.0 : 0.0,
    };
  }
}
