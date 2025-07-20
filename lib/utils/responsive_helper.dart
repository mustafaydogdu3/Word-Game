import 'dart:math';

import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen size breakpoints - Updated for better device coverage
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  static const double desktopBreakpoint = 1440;

  // Device type detection
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  // Orientation detection
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;

  // Screen dimensions
  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Safe area handling
  static EdgeInsets getSafeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  static double getTopPadding(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  static double getBottomPadding(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  static double getLeftPadding(BuildContext context) =>
      MediaQuery.of(context).padding.left;

  static double getRightPadding(BuildContext context) =>
      MediaQuery.of(context).padding.right;

  // Available screen space (excluding safe areas)
  static double getAvailableWidth(BuildContext context) =>
      getScreenWidth(context) -
      getLeftPadding(context) -
      getRightPadding(context);

  static double getAvailableHeight(BuildContext context) =>
      getScreenHeight(context) -
      getTopPadding(context) -
      getBottomPadding(context);

  // Responsive sizing methods with better scaling
  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? largeDesktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeDesktop(context) && largeDesktop != null) return largeDesktop;
    return desktop;
  }

  // Font sizes - Updated with better scaling
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 20.0,
    double desktop = 24.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveTitleFontSize(
    BuildContext context, {
    double mobile = 28.0,
    double tablet = 36.0,
    double desktop = 44.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveSubtitleFontSize(
    BuildContext context, {
    double mobile = 18.0,
    double tablet = 22.0,
    double desktop = 26.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveBodyFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveCaptionFontSize(
    BuildContext context, {
    double mobile = 12.0,
    double tablet = 14.0,
    double desktop = 16.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  // Spacing - Updated with better proportions
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveLargeSpacing(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveExtraLargeSpacing(
    BuildContext context, {
    double mobile = 24.0,
    double tablet = 36.0,
    double desktop = 48.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  // Padding and margins - Updated with better scaling
  static double getResponsivePadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static EdgeInsets getResponsiveMargin(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    mobile ??= EdgeInsets.all(
      getResponsivePadding(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
    );
    tablet ??= EdgeInsets.all(
      getResponsivePadding(context, mobile: 24.0, tablet: 32.0, desktop: 40.0),
    );
    desktop ??= EdgeInsets.all(
      getResponsivePadding(context, mobile: 32.0, tablet: 40.0, desktop: 48.0),
    );
    largeDesktop ??= EdgeInsets.all(
      getResponsivePadding(context, mobile: 40.0, tablet: 48.0, desktop: 56.0),
    );

    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  // Icon sizes - Updated with better scaling
  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  // Button sizes - Updated with better proportions
  static double getResponsiveButtonHeight(
    BuildContext context, {
    double mobile = 48.0,
    double tablet = 56.0,
    double desktop = 64.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveButtonWidth(
    BuildContext context, {
    double mobile = 200.0,
    double tablet = 250.0,
    double desktop = 300.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  // Game-specific responsive sizes - Updated with better calculations
  static double getResponsiveGridCellSize(BuildContext context) {
    final availableWidth = getAvailableWidth(context);
    final availableHeight = getAvailableHeight(context);
    final spacing = getResponsiveSpacing(context);

    if (isMobile(context)) {
      // For mobile, use smaller percentage and more constraints
      final widthBased = (availableWidth * 0.10).clamp(20.0, 35.0);
      final heightBased = (availableHeight * 0.06).clamp(20.0, 35.0);
      return widthBased < heightBased ? widthBased : heightBased;
    } else if (isTablet(context)) {
      final widthBased = (availableWidth * 0.07).clamp(30.0, 45.0);
      final heightBased = (availableHeight * 0.05).clamp(30.0, 45.0);
      return widthBased < heightBased ? widthBased : heightBased;
    } else if (isLargeDesktop(context)) {
      final widthBased = (availableWidth * 0.04).clamp(45.0, 70.0);
      final heightBased = (availableHeight * 0.03).clamp(45.0, 70.0);
      return widthBased < heightBased ? widthBased : heightBased;
    } else {
      final widthBased = (availableWidth * 0.05).clamp(35.0, 55.0);
      final heightBased = (availableHeight * 0.04).clamp(35.0, 55.0);
      return widthBased < heightBased ? widthBased : heightBased;
    }
  }

  // Dynamic grid cell size based on gridSize from JSON
  static double getDynamicGridCellSize(
    BuildContext context,
    int gridCols,
    int gridRows,
  ) {
    final availableWidth = getAvailableWidth(context);
    final availableHeight = getAvailableHeight(context);

    // Calculate the maximum grid size (rows or columns)
    final maxGridDimension = max(gridCols, gridRows);

    // Base cell size calculation with dynamic scaling
    double baseCellSize;

    if (isMobile(context)) {
      // For mobile devices
      if (maxGridDimension <= 3) {
        // Small grids (3x3 or smaller) - larger cells
        baseCellSize = (availableWidth * 0.18).clamp(50.0, 80.0);
      } else if (maxGridDimension <= 4) {
        // Medium grids (4x4) - medium cells
        baseCellSize = (availableWidth * 0.15).clamp(45.0, 65.0);
      } else if (maxGridDimension <= 5) {
        // Large grids (5x5) - smaller cells
        baseCellSize = (availableWidth * 0.12).clamp(40.0, 55.0);
      } else {
        // Very large grids (6x6 or larger) - very small cells
        baseCellSize = (availableWidth * 0.10).clamp(35.0, 50.0);
      }
    } else if (isTablet(context)) {
      // For tablet devices
      if (maxGridDimension <= 3) {
        baseCellSize = (availableWidth * 0.15).clamp(60.0, 90.0);
      } else if (maxGridDimension <= 4) {
        baseCellSize = (availableWidth * 0.12).clamp(55.0, 80.0);
      } else if (maxGridDimension <= 5) {
        baseCellSize = (availableWidth * 0.10).clamp(50.0, 75.0);
      } else {
        baseCellSize = (availableWidth * 0.08).clamp(45.0, 65.0);
      }
    } else {
      // For desktop devices
      if (maxGridDimension <= 3) {
        baseCellSize = (availableWidth * 0.10).clamp(70.0, 110.0);
      } else if (maxGridDimension <= 4) {
        baseCellSize = (availableWidth * 0.09).clamp(65.0, 95.0);
      } else if (maxGridDimension <= 5) {
        baseCellSize = (availableWidth * 0.08).clamp(60.0, 85.0);
      } else {
        baseCellSize = (availableWidth * 0.07).clamp(55.0, 80.0);
      }
    }

    // Calculate total grid dimensions
    double totalGridWidth = gridCols * baseCellSize;
    double totalGridHeight = gridRows * baseCellSize;

    // Get available space for grid (considering letter wheel at bottom)
    double maxGridWidth = availableWidth * 0.9;
    double maxGridHeight =
        availableHeight * 0.5; // Leave space for letter wheel

    // Calculate scale factor if grid is too large
    double scaleFactor = 1.0;
    if (totalGridWidth > maxGridWidth || totalGridHeight > maxGridHeight) {
      double widthScale = maxGridWidth / totalGridWidth;
      double heightScale = maxGridHeight / totalGridHeight;
      scaleFactor = min(widthScale, heightScale);
    }

    // Apply scale factor and ensure minimum size
    double finalCellSize = (baseCellSize * scaleFactor).clamp(
      30.0,
      baseCellSize,
    );

    print(
      'Grid: ${gridCols}x$gridRows, Base: ${baseCellSize.toStringAsFixed(1)}, Final: ${finalCellSize.toStringAsFixed(1)}, Scale: ${scaleFactor.toStringAsFixed(2)}',
    );

    return finalCellSize;
  }

  static double getResponsiveLetterCircleSize(BuildContext context) {
    final availableWidth = getAvailableWidth(context);
    final availableHeight = getAvailableHeight(context);

    if (isMobile(context)) {
      final widthBased = (availableWidth * 0.65).clamp(250.0, 350.0);
      final heightBased = (availableHeight * 0.25).clamp(250.0, 350.0);
      return widthBased < heightBased ? widthBased : heightBased;
    } else if (isTablet(context)) {
      final widthBased = (availableWidth * 0.45).clamp(320.0, 450.0);
      final heightBased = (availableHeight * 0.20).clamp(320.0, 450.0);
      return widthBased < heightBased ? widthBased : heightBased;
    } else if (isLargeDesktop(context)) {
      final widthBased = (availableWidth * 0.25).clamp(450.0, 700.0);
      final heightBased = (availableHeight * 0.15).clamp(450.0, 700.0);
      return widthBased < heightBased ? widthBased : heightBased;
    } else {
      final widthBased = (availableWidth * 0.30).clamp(380.0, 550.0);
      final heightBased = (availableHeight * 0.18).clamp(380.0, 550.0);
      return widthBased < heightBased ? widthBased : heightBased;
    }
  }

  static double getResponsiveLetterSize(
    BuildContext context, {
    double mobile = 28.0,
    double tablet = 32.0,
    double desktop = 36.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveShuffleButtonSize(
    BuildContext context, {
    double mobile = 60.0,
    double tablet = 70.0,
    double desktop = 80.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveHintButtonSize(
    BuildContext context, {
    double mobile = 50.0,
    double tablet = 60.0,
    double desktop = 70.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveSettingsButtonSize(
    BuildContext context, {
    double mobile = 40.0,
    double tablet = 45.0,
    double desktop = 50.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveScoreBoxHeight(
    BuildContext context, {
    double mobile = 36.0,
    double tablet = 42.0,
    double desktop = 48.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  static double getResponsiveScoreBoxPadding(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 10.0,
    double desktop = 12.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  // Border radius - Updated with better scaling
  static double getResponsiveBorderRadius(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 10.0,
    double desktop = 12.0,
    double? largeDesktop,
  }) => getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );

  // Layout helpers - Updated with better logic
  static bool shouldUseCompactLayout(BuildContext context) {
    final availableHeight = getAvailableHeight(context);
    final availableWidth = getAvailableWidth(context);

    // Use compact layout for very small screens or landscape on mobile
    return availableHeight < 600 ||
        (isMobile(context) && isLandscape(context)) ||
        (availableWidth < 400);
  }

  static bool shouldUseHorizontalLayout(BuildContext context) {
    return isTablet(context) || isDesktop(context) || isLargeDesktop(context);
  }

  static double getResponsiveTopOffset(BuildContext context) {
    final topPadding = getTopPadding(context);
    if (isMobile(context)) {
      return topPadding +
          getResponsiveSpacing(
            context,
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          );
    } else if (isTablet(context)) {
      return topPadding +
          getResponsiveSpacing(
            context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          );
    } else if (isLargeDesktop(context)) {
      return topPadding +
          getResponsiveSpacing(
            context,
            mobile: 24.0,
            tablet: 28.0,
            desktop: 32.0,
          );
    } else {
      return topPadding +
          getResponsiveSpacing(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          );
    }
  }

  static double getResponsiveBottomOffset(BuildContext context) {
    final bottomPadding = getBottomPadding(context);
    if (isMobile(context)) {
      return bottomPadding +
          getResponsiveSpacing(
            context,
            mobile: 12.0,
            tablet: 16.0,
            desktop: 20.0,
          );
    } else if (isTablet(context)) {
      return bottomPadding +
          getResponsiveSpacing(
            context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          );
    } else if (isLargeDesktop(context)) {
      return bottomPadding +
          getResponsiveSpacing(
            context,
            mobile: 24.0,
            tablet: 28.0,
            desktop: 32.0,
          );
    } else {
      return bottomPadding +
          getResponsiveSpacing(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          );
    }
  }

  // Dialog sizes - Updated with better proportions
  static double getResponsiveDialogWidth(BuildContext context) {
    final availableWidth = getAvailableWidth(context);
    if (isMobile(context)) {
      return availableWidth * 0.92;
    } else if (isTablet(context)) {
      return availableWidth * 0.75;
    } else if (isLargeDesktop(context)) {
      return availableWidth * 0.40;
    } else {
      return availableWidth * 0.55;
    }
  }

  static double getResponsiveDialogHeight(BuildContext context) {
    final availableHeight = getAvailableHeight(context);
    if (isMobile(context)) {
      return availableHeight * 0.75;
    } else if (isTablet(context)) {
      return availableHeight * 0.65;
    } else if (isLargeDesktop(context)) {
      return availableHeight * 0.45;
    } else {
      return availableHeight * 0.55;
    }
  }

  // New methods for better responsive design
  static double getResponsiveContainerWidth(
    BuildContext context, {
    double percentage = 1.0,
  }) {
    final availableWidth = getAvailableWidth(context);
    if (isMobile(context)) {
      return availableWidth * percentage;
    } else if (isTablet(context)) {
      return availableWidth * (percentage * 0.9);
    } else if (isLargeDesktop(context)) {
      return availableWidth * (percentage * 0.7);
    } else {
      return availableWidth * (percentage * 0.8);
    }
  }

  static double getResponsiveContainerHeight(
    BuildContext context, {
    double percentage = 1.0,
  }) {
    final availableHeight = getAvailableHeight(context);
    if (isMobile(context)) {
      return availableHeight * percentage;
    } else if (isTablet(context)) {
      return availableHeight * (percentage * 0.9);
    } else if (isLargeDesktop(context)) {
      return availableHeight * (percentage * 0.8);
    } else {
      return availableHeight * (percentage * 0.85);
    }
  }

  // Aspect ratio helpers
  static double getResponsiveAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 16 / 9 : 9 / 16;
    } else if (isTablet(context)) {
      return isLandscape(context) ? 4 / 3 : 3 / 4;
    } else {
      return 16 / 10;
    }
  }

  // Grid layout helpers
  static int getResponsiveGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 4 : 3;
    } else if (isTablet(context)) {
      return isLandscape(context) ? 6 : 4;
    } else {
      return 8;
    }
  }

  // Animation duration helpers
  static Duration getResponsiveAnimationDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(milliseconds: 300);
    } else if (isTablet(context)) {
      return const Duration(milliseconds: 400);
    } else {
      return const Duration(milliseconds: 500);
    }
  }
}
