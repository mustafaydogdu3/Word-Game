import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/sound_service.dart';
import 'viewmodels/game_view_model.dart';
import 'views/game_screen.dart';
import 'views/main_menu_screen.dart';
import 'views/settings_screen.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.loadSettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameViewModel>(
          create: (_) => GameViewModel(),
          lazy: true, // Lazy initialization to avoid build-time issues
        ),
      ],
      child: MaterialApp(
        title: 'Word Game',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/main-menu': (context) => const MainMenuScreen(),
          '/game': (context) => const GameScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
