import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/breakout_game.dart';
import '../game/states/game_state.dart';
import '../config/game_config.dart';

// Interface for UI elements
abstract class UIElement extends Component {
  void updateDisplay();
}

class ScoreDisplay extends UIElement {
  final GameState gameState;
  late TextComponent _scoreText;

  ScoreDisplay(this.gameState);

  @override
  Future<void> onLoad() async {
    _scoreText = TextComponent(
      text: 'SCORE: 0',
      textRenderer: TextPaint(
        style: GameConfig.uiTextStyle.copyWith(
          color: GameConfig.scoreColor,
          shadows: [
            Shadow(
              blurRadius: 5.0,
              color: GameConfig.scoreColor.withOpacity(0.5),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      position: Vector2(GameConfig.uiPadding, GameConfig.uiPadding),
      priority: 1,
    );
    add(_scoreText);
  }

  @override
  void updateDisplay() {
    _scoreText.text = 'SCORE: ${gameState.score}';
  }
}

class LivesDisplay extends UIElement with HasGameRef<BreakoutGame> {
  final GameState gameState;
  late TextComponent _livesText;

  LivesDisplay(this.gameState);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final screenWidth = gameRef.size.x;
    final heartsText = _generateHearts(GameConfig.initialLives);
    _livesText = TextComponent(
      text: heartsText,
      textRenderer: TextPaint(
        style: GameConfig.uiTextStyle.copyWith(
          color: GameConfig.livesColor,
          shadows: [
            Shadow(
              blurRadius: 5.0,
              color: GameConfig.livesColor.withOpacity(0.5),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      position: Vector2(
        screenWidth - (GameConfig.uiPadding + 120), 
        GameConfig.uiPadding
      ),
      priority: 1,
    );
    await add(_livesText);
  }

  @override
  void updateDisplay() {
    final heartsText = _generateHearts(gameState.lives);
    _livesText.text = heartsText;
  }

  String _generateHearts(int lives) {
    return List.generate(
      GameConfig.initialLives, 
      (index) => index < lives ? GameConfig.heartIcon : GameConfig.emptyHeartIcon
    ).join(' ');
  }
}

class GameUIManager extends Component with HasGameRef<BreakoutGame> {
  late final ScoreDisplay _scoreDisplay;
  late final LivesDisplay _livesDisplay;
  final GameState gameState;

  GameUIManager({required this.gameState});

  @override
  Future<void> onLoad() async {
    _scoreDisplay = ScoreDisplay(gameState);
    _livesDisplay = LivesDisplay(gameState);
    
    await addAll([_scoreDisplay, _livesDisplay]);
    
    gameState.addListener(_updateUI);
  }

  void _updateUI() {
    _scoreDisplay.updateDisplay();
    _livesDisplay.updateDisplay();
  }

  @override
  void onRemove() {
    gameState.removeListener(_updateUI);
    super.onRemove();
  }

  void dispose() {
    gameState.removeListener(_updateUI);
  }
}
