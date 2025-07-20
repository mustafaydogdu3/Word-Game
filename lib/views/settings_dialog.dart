import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import 'main_menu_screen.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isSoundEnabled = SoundService.isSoundEnabled;
      _isMusicEnabled = SoundService.isMusicEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC), // Krem rengi
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık Bölümü
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF8B4513), // Sıcak kahverengi
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                'SETTINGS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // İçerik Bölümü
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // İkon Butonları Grid (2x2)
                  Row(
                    children: [
                      Expanded(
                        child: _buildIconButton(
                          icon: _isSoundEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                          label: 'Sound',
                          isEnabled: _isSoundEnabled,
                          onPressed: () async {
                            await SoundService.playButtonClick();
                            await SoundService.toggleSound();
                            setState(() {
                              _isSoundEnabled = SoundService.isSoundEnabled;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isSoundEnabled
                                        ? 'Sound: ON'
                                        : 'Sound: OFF',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIconButton(
                          icon: _isMusicEnabled
                              ? Icons.music_note
                              : Icons.music_off,
                          label: 'Music',
                          isEnabled: _isMusicEnabled,
                          onPressed: () async {
                            await SoundService.playButtonClick();
                            await SoundService.toggleMusic();
                            setState(() {
                              _isMusicEnabled = SoundService.isMusicEnabled;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isMusicEnabled
                                        ? 'Music: ON'
                                        : 'Music: OFF',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIconButton(
                          icon: Icons.help,
                          label: 'Help',
                          isEnabled: true,
                          onPressed: () async {
                            await SoundService.playButtonClick();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Help feature coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIconButton(
                          icon: Icons.home,
                          label: 'Home',
                          isEnabled: true,
                          onPressed: () async {
                            await SoundService.playButtonClick();
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Dialog'u kapat
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const MainMenuScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Back Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await SoundService.playButtonClick();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        // Dairesel İkon Butonu
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green.shade600 : Colors.grey.shade500,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: onPressed,
              child: Center(child: Icon(icon, color: Colors.white, size: 32)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Buton Etiketi
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isEnabled ? const Color(0xFF8B4513) : Colors.grey.shade600,
          ),
        ),
        // Durum Göstergesi
        if (label == 'Sound' || label == 'Music')
          Text(
            isEnabled ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.green.shade700 : Colors.red.shade600,
            ),
          ),
      ],
    );
  }
}
