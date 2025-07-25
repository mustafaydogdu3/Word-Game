import 'package:flutter/material.dart';

import '../../viewmodels/game_view_model.dart';

class LevelCompleteOverlay extends StatelessWidget {
  final GameViewModel viewModel;

  const LevelCompleteOverlay({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24.0),
          margin: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
                Colors.green.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),

              SizedBox(height: 24.0),

              // Level completed text
              Text(
                'SEVİYE TAMAMLANDI!',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.0),

              // Level info
              Text(
                'Seviye ${viewModel.game.currentLevel}',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 12.0),

              // Next level info
              Text(
                'Sonraki seviyeye geçiliyor...',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
