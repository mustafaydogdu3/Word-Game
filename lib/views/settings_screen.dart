import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/sound_service.dart';
import '../utils/responsive_helper.dart';
import '../viewmodels/game_view_model.dart';
import 'main_menu_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // SoundService'den mevcut ayarları yükle
    setState(() {
      _isSoundEnabled = SoundService.isSoundEnabled;
      _isMusicEnabled = SoundService.isMusicEnabled;
    });
  }

  Future<void> _toggleSound() async {
    print('Ses butonu tıklandı');
    try {
      await SoundService.playButtonClick();
      await SoundService.toggleSound();
      setState(() {
        _isSoundEnabled = SoundService.isSoundEnabled;
      });
      print('Ses durumu değiştirildi: $_isSoundEnabled');
    } catch (e) {
      print('Ses toggle hatası: $e');
    }
  }

  Future<void> _toggleMusic() async {
    print('Müzik butonu tıklandı');
    try {
      await SoundService.playButtonClick();
      await SoundService.toggleMusic();
      setState(() {
        _isMusicEnabled = SoundService.isMusicEnabled;
      });
      print('Müzik durumu değiştirildi: $_isMusicEnabled');
    } catch (e) {
      print('Müzik toggle hatası: $e');
    }
  }

  Future<void> _navigateToMainMenu() async {
    print('Ana menü butonu tıklandı');
    try {
      await SoundService.playButtonClick();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      }
    } catch (e) {
      print('Ana menü navigasyon hatası: $e');
    }
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
            'Levelleri Sıfırla?',
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

      // Reset game view model
      final viewModel = Provider.of<GameViewModel>(context, listen: false);
      await viewModel.resetProgress();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Leveller başarıyla sıfırlandı! Level 1\'den başlayabilirsiniz.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveBodyFontSize(context),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainMenuScreen()),
            );
          },
          icon: const Icon(Icons.home, color: Colors.grey),
        ),
        title: const Text('AYARLAR', style: TextStyle(color: Colors.grey)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sayfa başlığı
              Text(
                'AYARLAR',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 48),

              // Ana Menü butonu
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _navigateToMainMenu,
                  icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                  label: const Text(
                    'Ana Menü',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Ses ayarları butonu
              _buildToggleButton(
                icon: _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                title: 'Ses',
                subtitle: _isSoundEnabled ? 'Açık' : 'Kapalı',
                isEnabled: _isSoundEnabled,
                onTap: _toggleSound,
              ),

              const SizedBox(height: 16),

              // Müzik ayarları butonu
              _buildToggleButton(
                icon: _isMusicEnabled ? Icons.music_note : Icons.music_off,
                title: 'Müzik',
                subtitle: _isMusicEnabled ? 'Açık' : 'Kapalı',
                isEnabled: _isMusicEnabled,
                onTap: _toggleMusic,
              ),

              const SizedBox(height: 16),

              // Levelleri Sıfırla butonu
              _buildResetButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // İkon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Metin içeriği
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle switch
              Container(
                width: 48,
                height: 24,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.green.shade400
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment: isEnabled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _resetProgress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // İkon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Metin içeriği
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Levelleri Sıfırla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tüm seviyeleri baştan başla',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
