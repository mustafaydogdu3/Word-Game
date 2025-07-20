import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/sound_service.dart';
import '../utils/responsive_helper.dart';
import '../viewmodels/game_view_model.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int currentLevel = 1;
  int currentWorld = 5;
  String worldName = "YOLCULUK";

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final viewModel = Provider.of<GameViewModel>(context, listen: false);

    setState(() {
      // Get current level from GameViewModel instead of SharedPreferences
      currentLevel = viewModel.game.currentLevel;
      currentWorld = currentLevel;
      worldName = "YOLCULUK $currentLevel";
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', currentLevel);
    await prefs.setInt('current_world', currentWorld);
    await prefs.setString('world_name', worldName);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context),
            ),
          ),
          title: Text(
            'Ayarlar',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveTitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  size: ResponsiveHelper.getResponsiveIconSize(context),
                ),
                title: Text(
                  'İlerlemeyi Sıfırla',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveBodyFontSize(
                      context,
                    ),
                  ),
                ),
                subtitle: Text(
                  'Tüm seviyeleri baştan başla',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveCaptionFontSize(
                      context,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _resetProgress();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.info,
                  size: ResponsiveHelper.getResponsiveIconSize(context),
                ),
                title: Text(
                  'Hakkında',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveBodyFontSize(
                      context,
                    ),
                  ),
                ),
                subtitle: Text(
                  'Kelime Oyunu v1.0',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveCaptionFontSize(
                      context,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Kapat',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetProgress() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context),
            ),
          ),
          title: Text(
            'İlerlemeyi Sıfırla?',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveTitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Tüm ilerleme kaybedilecek ve Level 1\'den başlayacaksınız. Emin misiniz?',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'Sıfırla',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all saved progress

      // Reset local state
      setState(() {
        currentLevel = 1;
        currentWorld = 1;
        worldName = "YOLCULUK 1";
      });

      // Reset game view model
      final viewModel = Provider.of<GameViewModel>(context, listen: false);
      await viewModel.resetProgress();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İlerleme başarıyla sıfırlandı! Level 1\'den başlayabilirsiniz.',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isLargeDesktop = ResponsiveHelper.isLargeDesktop(context);
    final shouldUseHorizontalLayout =
        ResponsiveHelper.shouldUseHorizontalLayout(context);

    // Update current level from viewModel
    currentLevel = viewModel.game.currentLevel;
    currentWorld = currentLevel;
    worldName = "YOLCULUK $currentLevel";

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/main_menu.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with score and settings
              _buildTopSection(context),

              // Main content area
              Expanded(
                child: shouldUseHorizontalLayout
                    ? _buildHorizontalLayout(context)
                    : _buildVerticalLayout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
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

          // Settings button
          GestureDetector(
            onTap: () async {
              await SoundService.playButtonClick();
              Navigator.pushNamed(context, '/settings');
            },
            child: Container(
              width: ResponsiveHelper.getResponsiveSettingsButtonSize(context),
              height: ResponsiveHelper.getResponsiveSettingsButtonSize(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.black54],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsiveMargin(context),
      child: Column(
        children: [
          // Top spacing
          SizedBox(
            height: ResponsiveHelper.getResponsiveExtraLargeSpacing(context),
          ),

          // Game title at top
          _buildGameTitle(context),

          // Spacing between title and level circle
          SizedBox(height: ResponsiveHelper.getResponsiveLargeSpacing(context)),

          // Level circle right below the title
          _buildLevelInfo(context),

          // Spacer to push play button to bottom
          Expanded(child: SizedBox()),

          // Play button at bottom
          _buildPlayButton(context),

          // Bottom spacing
          SizedBox(height: ResponsiveHelper.getResponsiveLargeSpacing(context)),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsiveMargin(context),
      child: Row(
        children: [
          // Left side - Game title
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildGameTitle(context)],
            ),
          ),

          SizedBox(
            width: ResponsiveHelper.getResponsiveExtraLargeSpacing(context),
          ),

          // Center - Level info
          Expanded(flex: 1, child: Center(child: _buildLevelInfo(context))),

          SizedBox(
            width: ResponsiveHelper.getResponsiveExtraLargeSpacing(context),
          ),

          // Right side - Play button
          Expanded(flex: 1, child: Center(child: _buildPlayButton(context))),
        ],
      ),
    );
  }

  Widget _buildGameTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          'WORD',
          style: GoogleFonts.pressStart2p(
            fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
              context,
              mobile: 32.0,
              tablet: 42.0,
              desktop: 52.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(3, 3),
                blurRadius: 8,
              ),
              Shadow(
                color: Colors.blue.withOpacity(0.5),
                offset: const Offset(1, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        Text(
          'GAME',
          style: GoogleFonts.pressStart2p(
            fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
              context,
              mobile: 32.0,
              tablet: 42.0,
              desktop: 52.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(3, 3),
                blurRadius: 8,
              ),
              Shadow(
                color: Colors.orange.withOpacity(0.5),
                offset: const Offset(1, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelInfo(BuildContext context) {
    final circleSize = ResponsiveHelper.getResponsiveButtonWidth(context) * 0.6;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Level number at top
            Text(
              '$currentLevel',
              style: GoogleFonts.orbitron(
                fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
                  context,
                  mobile: 32.0,
                  tablet: 40.0,
                  desktop: 48.0,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
            ),
            // YOLCULUK text at bottom
            Text(
              'YOLCULUK',
              style: GoogleFonts.orbitron(
                fontSize: ResponsiveHelper.getResponsiveCaptionFontSize(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await SoundService.playButtonClick();
        Navigator.of(context).pushReplacementNamed('/game');
      },
      child: Container(
        width: ResponsiveHelper.getResponsiveButtonWidth(context),
        height: ResponsiveHelper.getResponsiveButtonHeight(context),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: ResponsiveHelper.getResponsiveIconSize(context),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
            Text(
              'OYNA',
              style: GoogleFonts.orbitron(
                fontSize: ResponsiveHelper.getResponsiveSubtitleFontSize(
                  context,
                  mobile: 16.0,
                  tablet: 20.0,
                  desktop: 24.0,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveHelper.getResponsiveSpacing(context) * 0.3,
            ),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 18.0,
                tablet: 20.0,
                desktop: 22.0,
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75,
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified tulip field painter
class SimpleTulipFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw simple tulip rows
    for (int row = 0; row < 4; row++) {
      final double y = size.height * 0.3 + (row * 30);

      for (int col = 0; col < 10; col++) {
        final double x = (size.width / 10) * col + (row * 15);
        final double tulipSize = 6 + (row * 2);

        // Tulip colors
        final colors = [
          const Color(0xFFFF69B4), // Hot pink
          const Color(0xFF9370DB), // Medium purple
          const Color(0xFFDC143C), // Crimson
        ];

        paint.color = colors[(row + col) % colors.length];

        // Draw tulip
        canvas.drawCircle(Offset(x, y), tulipSize.toDouble(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
