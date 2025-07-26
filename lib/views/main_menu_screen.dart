import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/sound_service.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          title: Text(
            'Ayarlar',
            style: TextStyle(
              fontSize: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  size: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.05,
                ),
                title: Text(
                  'İlerlemeyi Sıfırla',
                  style: TextStyle(
                    fontSize: isSmallScreen
                        ? screenWidth * 0.04
                        : screenWidth * 0.035,
                  ),
                ),
                subtitle: Text(
                  'Tüm seviyeleri baştan başla',
                  style: TextStyle(
                    fontSize: isSmallScreen
                        ? screenWidth * 0.035
                        : screenWidth * 0.03,
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
                  size: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.05,
                ),
                title: Text(
                  'Hakkında',
                  style: TextStyle(
                    fontSize: isSmallScreen
                        ? screenWidth * 0.04
                        : screenWidth * 0.035,
                  ),
                ),
                subtitle: Text(
                  'Kelime Oyunu v1.0',
                  style: TextStyle(
                    fontSize: isSmallScreen
                        ? screenWidth * 0.035
                        : screenWidth * 0.03,
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
                  fontSize: isSmallScreen
                      ? screenWidth * 0.04
                      : screenWidth * 0.035,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLevelNavigationDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    final maxLevels = viewModel.totalLevels;

    // Controller for text input
    final TextEditingController levelController = TextEditingController();
    final FocusNode focusNode = FocusNode();
    int selectedLevel = currentLevel;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              title: Text(
                'Test - Seviye Seç',
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? screenWidth * 0.05
                      : screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mevcut seviye: $currentLevel\nToplam seviye: $maxLevels',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? screenWidth * 0.04
                          : screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.03),

                  // Number picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedLevel > 1
                            ? () => setState(() => selectedLevel--)
                            : null,
                        icon: Icon(Icons.remove_circle_outline),
                        color: selectedLevel > 1 ? Colors.blue : Colors.grey,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        child: Text(
                          '$selectedLevel',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? screenWidth * 0.06
                                : screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedLevel < maxLevels
                            ? () => setState(() => selectedLevel++)
                            : null,
                        icon: Icon(Icons.add_circle_outline),
                        color: selectedLevel < maxLevels
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ],
                  ),

                  SizedBox(height: screenWidth * 0.02),

                  // Text input as alternative
                  TextField(
                    controller: levelController,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Veya seviye numarası yazın (1-$maxLevels)',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: 15',
                    ),
                    onChanged: (value) {
                      final level = int.tryParse(value);
                      if (level != null && level >= 1 && level <= maxLevels) {
                        setState(() => selectedLevel = level);
                      }
                    },
                    onSubmitted: (value) {
                      final level = int.tryParse(value);
                      if (level != null && level >= 1 && level <= maxLevels) {
                        Navigator.of(context).pop();
                        _goToLevel(level);
                      } else {
                        // Show error for invalid input
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lütfen 1 ile $maxLevels arasında bir sayı girin',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenWidth * 0.02),

                  // Quick level buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickLevelButton(context, 1, '1', Colors.blue),
                      _buildQuickLevelButton(context, 10, '10', Colors.green),
                      _buildQuickLevelButton(context, 25, '25', Colors.orange),
                      _buildQuickLevelButton(
                        context,
                        maxLevels,
                        'Son',
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? screenWidth * 0.04
                          : screenWidth * 0.035,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _goToLevel(selectedLevel);
                  },
                  child: Text(
                    'Git',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? screenWidth * 0.04
                          : screenWidth * 0.035,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickLevelButton(
    BuildContext context,
    int level,
    String label,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        _goToLevel(level);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenWidth * 0.015,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _goToLevel(int level) async {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    try {
      viewModel.goToLevel(level);

      // Update local state
      setState(() {
        currentLevel = level;
        currentWorld = level;
        worldName = "YOLCULUK $level";
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Level $level\'e geçildi!',
            style: TextStyle(
              fontSize: isSmallScreen
                  ? screenWidth * 0.04
                  : screenWidth * 0.035,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Level $level\'e geçilemedi: $e',
            style: TextStyle(
              fontSize: isSmallScreen
                  ? screenWidth * 0.04
                  : screenWidth * 0.035,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetProgress() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          title: Text(
            'İlerlemeyi Sıfırla?',
            style: TextStyle(
              fontSize: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Tüm ilerleme kaybedilecek ve Level 1\'den başlayacaksınız. Emin misiniz?',
            style: TextStyle(
              fontSize: isSmallScreen
                  ? screenWidth * 0.04
                  : screenWidth * 0.035,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? screenWidth * 0.04
                      : screenWidth * 0.035,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'Sıfırla',
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? screenWidth * 0.04
                      : screenWidth * 0.035,
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
              fontSize: isSmallScreen
                  ? screenWidth * 0.04
                  : screenWidth * 0.035,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth > 768;
    final isLandscape = screenWidth > screenHeight;
    final shouldUseHorizontalLayout = isLandscape && screenWidth > 900;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.03,
        vertical: isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.025,
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
              SizedBox(
                width: isSmallScreen ? screenWidth * 0.02 : screenWidth * 0.015,
              ),
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

          // Test Level Navigation Button (Temporary)
          GestureDetector(
            onTap: () async {
              await SoundService.playButtonClick();
              _showLevelNavigationDialog();
            },
            child: Container(
              width: isSmallScreen ? screenWidth * 0.12 : screenWidth * 0.08,
              height: isSmallScreen ? screenWidth * 0.12 : screenWidth * 0.08,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade400],
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
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.navigation,
                color: Colors.white,
                size: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.05,
              ),
            ),
          ),

          SizedBox(
            width: isSmallScreen ? screenWidth * 0.02 : screenWidth * 0.015,
          ),

          // Settings button
          GestureDetector(
            onTap: () async {
              await SoundService.playButtonClick();
              Navigator.pushNamed(context, '/settings');
            },
            child: Container(
              width: isSmallScreen ? screenWidth * 0.12 : screenWidth * 0.08,
              height: isSmallScreen ? screenWidth * 0.12 : screenWidth * 0.08,
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
                size: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(
        isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.03,
      ),
      child: Column(
        children: [
          // Top spacing
          SizedBox(height: screenHeight * 0.05),

          // Game title at top
          _buildGameTitle(context),

          // Spacing between title and level circle
          SizedBox(height: screenHeight * 0.04),

          // Level circle right below the title
          _buildLevelInfo(context),

          // Spacer to push play button to bottom
          Expanded(child: SizedBox()),

          // Play button at bottom
          _buildPlayButton(context),

          // Bottom spacing
          SizedBox(height: screenHeight * 0.04),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(
        isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.03,
      ),
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

          SizedBox(width: screenWidth * 0.05),

          // Center - Level info
          Expanded(flex: 1, child: Center(child: _buildLevelInfo(context))),

          SizedBox(width: screenWidth * 0.05),

          // Right side - Play button
          Expanded(flex: 1, child: Center(child: _buildPlayButton(context))),
        ],
      ),
    );
  }

  Widget _buildGameTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth > 768;

    return Column(
      children: [
        Text(
          'WORD',
          style: GoogleFonts.pressStart2p(
            fontSize: isSmallScreen
                ? screenWidth * 0.08
                : (isTablet ? screenWidth * 0.06 : screenWidth * 0.05),
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
            fontSize: isSmallScreen
                ? screenWidth * 0.08
                : (isTablet ? screenWidth * 0.06 : screenWidth * 0.05),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth > 768;
    final circleSize = isSmallScreen
        ? screenWidth * 0.4
        : (isTablet ? screenWidth * 0.25 : screenWidth * 0.3);

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
                fontSize: isSmallScreen
                    ? screenWidth * 0.08
                    : (isTablet ? screenWidth * 0.06 : screenWidth * 0.05),
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
            SizedBox(height: screenWidth * 0.01),
            // YOLCULUK text at bottom
            Text(
              'YOLCULUK',
              style: GoogleFonts.orbitron(
                fontSize: isSmallScreen
                    ? screenWidth * 0.03
                    : (isTablet ? screenWidth * 0.025 : screenWidth * 0.02),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth > 768;

    return GestureDetector(
      onTap: () async {
        await SoundService.playButtonClick();
        Navigator.of(context).pushReplacementNamed('/game');
      },
      child: Container(
        width: isSmallScreen
            ? screenWidth * 0.7
            : (isTablet ? screenWidth * 0.4 : screenWidth * 0.5),
        height: isSmallScreen
            ? screenHeight * 0.08
            : (isTablet ? screenHeight * 0.1 : screenHeight * 0.09),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
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
              padding: EdgeInsets.all(screenWidth * 0.01),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'OYNA',
              style: GoogleFonts.orbitron(
                fontSize: isSmallScreen
                    ? screenWidth * 0.04
                    : (isTablet ? screenWidth * 0.035 : screenWidth * 0.03),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
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
            padding: EdgeInsets.all(screenWidth * 0.01),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isSmallScreen ? screenWidth * 0.045 : screenWidth * 0.04,
            ),
          ),
          SizedBox(width: screenWidth * 0.015),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen
                  ? screenWidth * 0.04
                  : screenWidth * 0.035,
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
