import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game/viewmodels/game_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _textPositionAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Progress bar animasyonu (0'dan 1'e)
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // Yazının main menu'deki konumuna doğru kayma animasyonu
    _textPositionAnimation =
        Tween<double>(
          begin: 0.0, // Başlangıç pozisyonu (orta)
          end: -0.35, // Main menu'deki üst konuma doğru yukarı kayma
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
          ),
        );

    _startLoading();
  }

  void _startLoading() async {
    try {
      // GameViewModel'i initialize et - post-frame callback ile güvenli şekilde
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final viewModel = Provider.of<GameViewModel>(context, listen: false);
          await viewModel.initializeGame();
        }
      });

      // Animasyonu başlat
      if (mounted) {
        _animationController.forward();
      }

      // Animasyon tamamen bittiğinde main menu'ye geç
      await Future.delayed(const Duration(milliseconds: 3000));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main-menu');
      }
    } catch (e) {
      print('Error in splash screen loading: $e');
      // Even if there's an error, try to navigate to main menu
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main-menu');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth > 768;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/main_menu.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WORD GAME yazısı (main menu'deki ile aynı stil)
              AnimatedBuilder(
                animation: _textPositionAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _textPositionAnimation.value * screenHeight,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'WORD',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? screenWidth * 0.08
                                : (isTablet
                                      ? screenWidth * 0.06
                                      : screenWidth * 0.05),
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
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? screenWidth * 0.08
                                : (isTablet
                                      ? screenWidth * 0.06
                                      : screenWidth * 0.05),
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
                    ),
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.05),

              // Progress bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Container(
                    width: screenWidth * 0.6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.green],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
