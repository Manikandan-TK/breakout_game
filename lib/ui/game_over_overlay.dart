import 'package:breakout_game/shared/enums/game_end_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
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
    final isVictory = gameState.gameEndState == GameEndState.won;
    final screenSize = MediaQuery.of(context).size;
    final fontSize = screenSize.width * 0.12;
    final subtitleSize = screenSize.width * 0.06;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameConfig.backgroundColor.withOpacity(0.95),
            GameConfig.backgroundColor.withOpacity(0.85),
          ],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Victory/Game Over Text with Scale Animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Text(
                  isVictory ? 'VICTORY!' : 'GAME OVER',
                  style: GameConfig.titleStyle.copyWith(
                    fontSize: fontSize,
                    color: isVictory ? GameConfig.accentColor : GameConfig.secondaryColor,
                    shadows: [
                      Shadow(
                        color: (isVictory ? GameConfig.accentColor : GameConfig.secondaryColor)
                            .withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Score with Fade Animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeInOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: child,
                ),
                child: Column(
                  children: [
                    Text(
                      'FINAL SCORE',
                      style: GameConfig.subtitleStyle.copyWith(
                        fontSize: subtitleSize * 0.6,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${gameState.score}',
                      style: GameConfig.titleStyle.copyWith(
                        fontSize: subtitleSize,
                        color: GameConfig.primaryColor,
                        shadows: [
                          Shadow(
                            color: GameConfig.primaryColor.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              // Play Again Button with Slide Animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 100.0, end: 0.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                ),
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameConfig.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.1,
                      vertical: screenSize.height * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 8,
                    shadowColor: GameConfig.primaryColor.withOpacity(0.5),
                  ),
                  child: Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: subtitleSize * 0.7,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
