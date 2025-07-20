import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _soundEnabled = true;
  static bool _musicEnabled = true;

  // Load sound settings
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
    print('Sound enabled: $_soundEnabled');
    print('Music enabled: $_musicEnabled');
  }

  // Save sound settings
  static Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    _soundEnabled = enabled;
    print('Sound saved as: $enabled');
  }

  // Save music settings
  static Future<void> saveMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
    _musicEnabled = enabled;
    print('Music saved as: $enabled');
  }

  // Toggle sound on/off
  static Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await saveSoundEnabled(_soundEnabled);
    print('Sound toggled to: $_soundEnabled');
  }

  // Toggle music on/off
  static Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await saveMusicEnabled(_musicEnabled);
    print('Music toggled to: $_musicEnabled');
  }

  // Check if sound is enabled
  static bool get isSoundEnabled => _soundEnabled;

  // Check if music is enabled
  static bool get isMusicEnabled => _musicEnabled;

  // Play button click sound
  static Future<void> playButtonClick() async {
    if (!_soundEnabled) {
      print('Sound disabled, not playing button click');
      return;
    }
    try {
      print('Playing button click sound');
      await _audioPlayer.play(AssetSource('sounds/button_click.mp3'));
    } catch (e) {
      print('Error playing button click sound: $e');
    }
  }

  // Play word found sound
  static Future<void> playWordFound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/word_found.mp3'));
    } catch (e) {
      print('Error playing word found sound: $e');
    }
  }

  // Play level complete sound
  static Future<void> playLevelComplete() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/level_complete.mp3'));
    } catch (e) {
      print('Error playing level complete sound: $e');
    }
  }

  // Play error sound
  static Future<void> playError() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      print('Error playing error sound: $e');
    }
  }

  // Play shuffle sound
  static Future<void> playShuffle() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/shuffle.mp3'));
    } catch (e) {
      print('Error playing shuffle sound: $e');
    }
  }

  // Reset sound settings (for debugging)
  static Future<void> resetSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', true);
    _soundEnabled = true;
    print('Sound settings reset to enabled');
  }

  // Dispose audio player
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  // Play letter selection sound (softer than button click)
  static Future<void> playLetterSelect() async {
    if (!_soundEnabled) return;
    try {
      // Use a softer volume or different sound for letter selection
      await _audioPlayer.play(AssetSource('sounds/button_click.mp3'));
    } catch (e) {
      print('Error playing letter select sound: $e');
    }
  }
}
