import 'package:flutter/material.dart';

class SelectedWordOverlay extends StatelessWidget {
  final String selectedWord;
  final int letterCount;

  const SelectedWordOverlay({
    super.key,
    required this.selectedWord,
    required this.letterCount,
  });

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double circleSize = _getDynamicLetterCircleSize(context, letterCount);
    // Overlay genişliğini çemberin genişliğine göre sınırla
    final double overlayWidth = circleSize * 0.95;
    final double overlayPadding = screenWidth * 0.04;
    final double overlayVerticalPadding = screenHeight * 0.012;
    final double overlayFontSize = (screenWidth * 0.05).clamp(
      screenWidth * 0.04,
      screenWidth * 0.08,
    );

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: overlayWidth),
        padding: EdgeInsets.symmetric(
          horizontal: overlayPadding,
          vertical: overlayVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: screenWidth * 0.02,
              offset: Offset(0, screenHeight * 0.005),
            ),
          ],
        ),
        child: Text(
          selectedWord,
          style: TextStyle(
            fontSize: overlayFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
