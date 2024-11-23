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

class ScoreDisplay extends PositionComponent with HasGameRef<BreakoutGame> implements UIElement {
  final GameState gameState;
  late TextComponent _scoreText;
  static const double margin = 20.0;
  static const double fontSizePercent = 0.04;

  ScoreDisplay(this.gameState);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    position = Vector2(
      gameRef.size.x - margin,
      margin,
    );

    _scoreText = TextComponent(
      text: 'Score: ${gameState.score}',
      textRenderer: TextPaint(
        style: GameConfig.uiTextStyle.copyWith(
          color: GameConfig.scoreColor,
          fontSize: gameRef.size.x * fontSizePercent,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: GameConfig.scoreColor.withOpacity(0.5),
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      anchor: Anchor.topRight,
    );
    await add(_scoreText);
  }

  @override
  void updateDisplay() {
    _scoreText.text = 'Score: ${gameState.score}';
  }
}

class LivesDisplay extends PositionComponent with HasGameRef<BreakoutGame> {
  final GameState gameState;
  late TextComponent _livesText;
  int _previousLives;
  bool _isAnimating = false;
  static const double margin = 20.0;
  static const double fontSizePercent = 0.04;
  late final double _fontSize;

  LivesDisplay(this.gameState) : _previousLives = gameState.lives;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    position = Vector2(
      margin,
      margin,
    );

    _fontSize = gameRef.size.x * fontSizePercent;

    _livesText = TextComponent(
      text: '❤️ x${gameState.lives}',
      textRenderer: TextPaint(
        style: GameConfig.uiTextStyle.copyWith(
          color: GameConfig.livesColor,
          fontSize: _fontSize,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: GameConfig.livesColor.withOpacity(0.5),
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    await add(_livesText);
  }

  void reset() {
    _isAnimating = false;
    _previousLives = gameState.lives;
    _livesText.scale = Vector2.all(1.0);
    updateDisplay();
  }

  void updateDisplay() {
    if (_previousLives > gameState.lives && !_isAnimating) {
      _animateLifeLoss();
    }
    _previousLives = gameState.lives;
    _livesText.text = '❤️ x${gameState.lives}';
    
    // Ensure text renderer maintains consistent font size
    _livesText.textRenderer = TextPaint(
      style: GameConfig.uiTextStyle.copyWith(
        color: GameConfig.livesColor,
        fontSize: _fontSize,
        shadows: [
          Shadow(
            blurRadius: 8.0,
            color: GameConfig.livesColor.withOpacity(0.5),
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }

  void _animateLifeLoss() async {
    if (_isAnimating) return;
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
      )..onComplete = () {
        _isAnimating = false;
        _livesText.scale = Vector2.all(1.0); // Ensure scale is reset
      },
    );
  }
}

class PowerUpDisplay extends PositionComponent with HasGameRef<BreakoutGame> {
  final GameState gameState;
  List<TextComponent> _powerUpTexts = [];
  final Map<PowerUpType, double> _activePowerUps = {};
  static const double powerUpSpacing = 85.0; 
  static const double verticalOffset = 50.0;
  static const int maxVisiblePowerUps = 6; 

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
    // Clear active power-ups map
    _activePowerUps.clear();
    
    // Remove all power-up text components
    for (var text in _powerUpTexts) {
      text.removeFromParent();
    }
    _powerUpTexts.clear();
    
    // Force display update
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
    for (final text in _powerUpTexts) {
      text.removeFromParent();
    }
    _powerUpTexts.clear();

    // Calculate available width for power-ups
    final availableWidth = gameRef.size.x - (GameConfig.uiPadding * 2);
    final maxItems = (availableWidth / powerUpSpacing).floor().clamp(1, maxVisiblePowerUps);

    // Sort power-ups by remaining time and take only the most recent ones
    final sortedPowerUps = _activePowerUps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create new power-up texts horizontally (only most recent ones)
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
                blurRadius: 8.0,
                color: entry.key.color.withOpacity(0.5),
                offset: const Offset(2, 2),
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

  void reset() {
    _livesDisplay.reset();
    _powerUpDisplay.clearAllPowerUps();
    _updateUI();
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
