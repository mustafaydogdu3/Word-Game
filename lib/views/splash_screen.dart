import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/responsive_helper.dart';
import '../viewmodels/game_view_model.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Sabit animasyon süreleri kullan (initState'de MediaQuery'ye erişemeyiz)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startAnimations();
    _initializeGame();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
  }

  Future<void> _initializeGame() async {
    // Wait a bit to ensure the widget is fully built
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      final viewModel = Provider.of<GameViewModel>(context, listen: false);
      await viewModel.initializeGame();
    }

    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isLargeDesktop = ResponsiveHelper.isLargeDesktop(context);
    final shouldUseHorizontalLayout =
        ResponsiveHelper.shouldUseHorizontalLayout(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF87CEEB), // Sky blue at top
              Color(0xFFFFB6C1), // Light pink in middle
              Color(0xFFFFE4E1), // Misty rose at bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: shouldUseHorizontalLayout
              ? _buildHorizontalLayout(context)
              : _buildVerticalLayout(context),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: ResponsiveHelper.getResponsiveMargin(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon or logo placeholder
                _buildAppIcon(context),

                SizedBox(
                  height: ResponsiveHelper.getResponsiveLargeSpacing(context),
                ),

                // App title
                _buildAppTitle(context),

                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(context),
                ),

                // Subtitle
                _buildSubtitle(context),

                SizedBox(
                  height: ResponsiveHelper.getResponsiveExtraLargeSpacing(
                    context,
                  ),
                ),

                // Loading indicator
                _buildLoadingIndicator(context),

                SizedBox(
                  height: ResponsiveHelper.getResponsiveLargeSpacing(context),
                ),

                // Loading text
                _buildLoadingText(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: ResponsiveHelper.getResponsiveMargin(context),
            child: Row(
              children: [
                // Left side - App icon and title
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppIcon(context),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveLargeSpacing(
                          context,
                        ),
                      ),
                      _buildAppTitle(context),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(context),
                      ),
                      _buildSubtitle(context),
                    ],
                  ),
                ),

                SizedBox(
                  width: ResponsiveHelper.getResponsiveExtraLargeSpacing(
                    context,
                  ),
                ),

                // Right side - Loading
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLoadingIndicator(context),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveLargeSpacing(
                          context,
                        ),
                      ),
                      _buildLoadingText(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(BuildContext context) {
    return Container(
      width: ResponsiveHelper.getResponsiveIconSize(
        context,
        mobile: 80.0,
        tablet: 100.0,
        desktop: 120.0,
      ),
      height: ResponsiveHelper.getResponsiveIconSize(
        context,
        mobile: 80.0,
        tablet: 100.0,
        desktop: 120.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.psychology,
        size: ResponsiveHelper.getResponsiveIconSize(
          context,
          mobile: 40.0,
          tablet: 50.0,
          desktop: 60.0,
        ),
        color: Colors.purple,
      ),
    );
  }

  Widget _buildAppTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          'KELİME',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
              context,
              mobile: 28.0,
              tablet: 36.0,
              desktop: 44.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        Text(
          'OYUNU',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveTitleFontSize(
              context,
              mobile: 28.0,
              tablet: 36.0,
              desktop: 44.0,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Kelime Oyunu',
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveSubtitleFontSize(context),
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return SizedBox(
      width: ResponsiveHelper.getResponsiveIconSize(
        context,
        mobile: 30.0,
        tablet: 35.0,
        desktop: 40.0,
      ),
      height: ResponsiveHelper.getResponsiveIconSize(
        context,
        mobile: 30.0,
        tablet: 35.0,
        desktop: 40.0,
      ),
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: ResponsiveHelper.isMobile(context) ? 3.0 : 4.0,
      ),
    );
  }

  Widget _buildLoadingText(BuildContext context) {
    return Text(
      'Yükleniyor...',
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
        color: Colors.white.withOpacity(0.8),
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
