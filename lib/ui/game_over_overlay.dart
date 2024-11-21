import 'package:breakout_game/shared/enums/game_end_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/states/game_state.dart';
import '../config/game_config.dart'; // Assuming GameConfig is defined in this file

class GameOverOverlay extends StatelessWidget {
  static const String id = 'game_over';
  
  final Vector2 size;
  final GameState gameState;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.size,
    required this.gameState,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameConfig.backgroundColor.withOpacity(0.9),
            GameConfig.backgroundColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gameState.gameEndState == GameEndState.won ? 'VICTORY!' : 'GAME OVER',
              style: GameConfig.titleStyle.copyWith(
                fontSize: 64,
                color: gameState.gameEndState == GameEndState.won 
                  ? GameConfig.accentColor 
                  : GameConfig.secondaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Final Score: ${gameState.score}',
              style: GameConfig.subtitleStyle.copyWith(
                fontSize: 32,
                color: GameConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: GameConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: GameConfig.primaryColor.withOpacity(0.5),
              ),
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
