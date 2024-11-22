import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../game/breakout_game.dart';
import '../game/states/game_state.dart';
import '../config/game_config.dart';
import '../game/components/power_up.dart';

// Interface for UI elements
abstract class UIElement extends Component {
  void updateDisplay();
}

class ScoreDisplay extends PositionComponent with HasGameRef<BreakoutGame> {
  final GameState gameState;
  late TextComponent _scoreText;
  static const double margin = 20.0;

  ScoreDisplay(this.gameState);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Position score with consistent margin
    position = Vector2(
      gameRef.size.x - margin,
      margin,
    );

    _scoreText = TextComponent(
      text: 'SCORE: ${gameState.score}',
      textRenderer: TextPaint(
        style: GameConfig.uiTextStyle.copyWith(
          color: GameConfig.primaryColor,
          fontSize: gameRef.size.x * 0.04,
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      anchor: Anchor.topRight,
    );
    await add(_scoreText);
  }

  void updateDisplay() {
    _scoreText.text = 'SCORE: ${gameState.score}';
  }
}

class LivesDisplay extends PositionComponent with HasGameRef<BreakoutGame> {
  final GameState gameState;
  late TextComponent _livesText;
  int _previousLives;
  bool _isAnimating = false;
  static const double margin = 20.0;

  LivesDisplay(this.gameState) : _previousLives = gameState.lives;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    position = Vector2(
      margin,
      margin,
    );

    _livesText = TextComponent(
      text: '❤️ x${gameState.lives}',
      textRenderer: TextPaint(
        style: GameConfig.uiTextStyle.copyWith(
          color: GameConfig.secondaryColor,
          fontSize: gameRef.size.x * 0.04,
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    await add(_livesText);
  }

  void updateDisplay() {
    if (_previousLives > gameState.lives && !_isAnimating) {
      _animateLifeLoss();
    }
    _previousLives = gameState.lives;
    _livesText.text = '❤️ x${gameState.lives}';
  }

  void _animateLifeLoss() async {
    _isAnimating = true;
    
    await _livesText.add(
      ScaleEffect.by(
        Vector2.all(1.3),
        EffectController(
          duration: 0.15,
          curve: Curves.easeOut,
        ),
      ),
    );
    
    await _livesText.add(
      ScaleEffect.by(
        Vector2.all(1/1.3),
        EffectController(
          duration: 0.3,
          curve: Curves.elasticIn,
        ),
      ),
    );
    
    _isAnimating = false;
  }
}

class PowerUpDisplay extends PositionComponent with HasGameRef<BreakoutGame> {
  final GameState gameState;
  List<TextComponent> _powerUpTexts = [];
  final Map<PowerUpType, double> _activePowerUps = {};
  static const double powerUpSpacing = 120.0; // Horizontal spacing between power-ups
  static const double verticalOffset = 50.0;
  static const int maxVisiblePowerUps = 5; // Maximum visible power-ups

  PowerUpDisplay(this.gameState);

  void addPowerUp(PowerUpType type, double duration) {
    _activePowerUps[type] = duration;
    updateDisplay();
  }

  void removePowerUp(PowerUpType type) {
    _activePowerUps.remove(type);
    updateDisplay();
  }

  void clearAllPowerUps() {
    _activePowerUps.clear();
    updateDisplay();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Position power-ups at the top of the screen with padding
    position = Vector2(
      GameConfig.uiPadding,
      GameConfig.uiPadding + verticalOffset,
    );
    _powerUpTexts = [];
    updateDisplay();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final expiredPowerUps = <PowerUpType>[];
    
    _activePowerUps.forEach((type, remainingTime) {
      _activePowerUps[type] = remainingTime - dt;
      if (remainingTime - dt <= 0) {
        expiredPowerUps.add(type);
      }
    });
    
    for (var type in expiredPowerUps) {
      removePowerUp(type);
    }
    
    if (expiredPowerUps.isNotEmpty) {
      updateDisplay();
    }
  }

  void updateDisplay() {
    // Remove existing power-up texts
    for (var text in _powerUpTexts) {
      text.removeFromParent();
    }
    _powerUpTexts.clear();

    // Calculate available width for power-ups
    final availableWidth = gameRef.size.x - (GameConfig.uiPadding * 2);
    final maxItems = (availableWidth / powerUpSpacing).floor().clamp(1, maxVisiblePowerUps);

    // Sort power-ups by remaining time to keep the most recent ones
    final sortedPowerUps = _activePowerUps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create new power-up texts horizontally
    var index = 0;
    for (var entry in sortedPowerUps.take(maxItems)) {
      final powerUpText = TextComponent(
        text: '${entry.key.icon} ${entry.value.toStringAsFixed(1)}s',
        textRenderer: TextPaint(
          style: GameConfig.uiTextStyle.copyWith(
            color: entry.key.color,
            fontSize: 16,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        position: Vector2(index * powerUpSpacing, 0),
      );
      _powerUpTexts.add(powerUpText);
      add(powerUpText);
      index++;
    }

    // Add counter if there are more power-ups than can be displayed
    if (sortedPowerUps.length > maxItems) {
      final remainingCount = sortedPowerUps.length - maxItems;
      final countText = TextComponent(
        text: '+$remainingCount',
        textRenderer: TextPaint(
          style: GameConfig.uiTextStyle.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        position: Vector2(index * powerUpSpacing, 0),
      );
      _powerUpTexts.add(countText);
      add(countText);
    }
  }
}

class GameUIManager extends Component with HasGameRef<BreakoutGame> {
  late final ScoreDisplay _scoreDisplay;
  late final LivesDisplay _livesDisplay;
  late final PowerUpDisplay _powerUpDisplay;
  final GameState gameState;

  GameUIManager({required this.gameState});

  PowerUpDisplay get powerUpDisplay => _powerUpDisplay;

  @override
  Future<void> onLoad() async {
    _scoreDisplay = ScoreDisplay(gameState);
    _livesDisplay = LivesDisplay(gameState);
    _powerUpDisplay = PowerUpDisplay(gameState);

    await addAll([_scoreDisplay, _livesDisplay, _powerUpDisplay]);
    gameState.addListener(_updateUI);
  }

  void _updateUI() {
    _scoreDisplay.updateDisplay();
    _livesDisplay.updateDisplay();
    _powerUpDisplay.updateDisplay();
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
