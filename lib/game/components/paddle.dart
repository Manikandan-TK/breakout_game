import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';
import '../states/game_state.dart';
import 'power_up.dart';
import '../breakout_game.dart';

class Paddle extends RectangleComponent with CollisionCallbacks {
  final Vector2 screenSize;
  final GameState gameState;
  static const double _baseWidth = GameConfig.paddleWidth;
  static const double _baseHeight = GameConfig.paddleHeight;
  final Color color;
  
  double _currentWidth = _baseWidth;
  final Map<PowerUpType, async.Timer?> _activeTimers = {};
  
  Paddle({
    required this.screenSize,
    required this.gameState,
    required this.color,
  }) : super(
    size: Vector2(_baseWidth, _baseHeight),
    anchor: Anchor.center,
    paint: Paint()..color = color,
    position: Vector2(0, 0), // Will be set properly in onLoad
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(
      screenSize.x / 2, 
      screenSize.y - GameConfig.paddleBottomOffset
    );
    
    // Update size to match the new configuration
    size.x = _baseWidth;
    
    // Add a hitbox that exactly matches the paddle's current visual size
    add(RectangleHitbox(
      size: Vector2(size.x, size.y),
      position: Vector2(0, 0),
      isSolid: true,  // Ensure solid collision
    ));
  }

  void moveToPosition(double x) {
    final halfWidth = size.x / 2;
    final newX = x.clamp(halfWidth, screenSize.x - halfWidth);
    position.x = newX;
  }

  void cancelAllPowerUps() {
    // Cancel all active power-up timers
    for (var timer in _activeTimers.values) {
      timer?.cancel();
    }
    _activeTimers.clear();

    // Reset paddle size to base size
    _currentWidth = _baseWidth;
    size.x = _currentWidth;
    _updateHitbox(); // Update hitbox to match new size
  }

  void reset() {
    // Cancel all power-ups
    cancelAllPowerUps();

    // Reset position
    position = Vector2(
      screenSize.x / 2, 
      screenSize.y - GameConfig.paddleBottomOffset
    );
  }

  void _updateHitbox() {
    // Remove existing hitbox
    final hitboxes = children.whereType<RectangleHitbox>().toList();
    removeAll(hitboxes);
    
    // Add new hitbox that exactly matches the paddle's current visual size
    add(RectangleHitbox(
      size: Vector2(size.x, size.y),
      position: Vector2(0, 0),
      isSolid: true,  // Ensure solid collision
    ));
  }

  void applyPowerUp(PowerUpType type) {
    // Cancel existing power-up of the same type
    _activeTimers[type]?.cancel();
    
    switch (type) {
      case PowerUpType.expandPaddle:
        _currentWidth = _baseWidth * 1.5;
        size.x = _currentWidth;
        _updateHitbox();  // Update hitbox to match new size
        _startPowerUpTimer(type);
        break;
      case PowerUpType.shrinkPaddle:
        _currentWidth = _baseWidth * 0.75;
        size.x = _currentWidth;
        _updateHitbox();  // Update hitbox to match new size
        _startPowerUpTimer(type);
        break;
      case PowerUpType.speedUp:
        _startPowerUpTimer(type);
        break;
      case PowerUpType.slowDown:
        _startPowerUpTimer(type);
        break;
      case PowerUpType.multiBall:
        // Create additional balls through the game
        (findParent<BreakoutGame>() as BreakoutGame).spawnExtraBall();
        break;
      case PowerUpType.extraLife:
        // Add extra life through game state
        gameState.addLife();
        break;
    }
  }

  void _startPowerUpTimer(PowerUpType type) {
    _activeTimers[type] = async.Timer(
      Duration(seconds: GameConfig.powerUpDuration.toInt()),
      () => _endPowerUp(type),
    );
  }

  void _endPowerUp(PowerUpType type) {
    _activeTimers[type] = null;
    
    switch (type) {
      case PowerUpType.expandPaddle:
      case PowerUpType.shrinkPaddle:
        _currentWidth = _baseWidth;
        size.x = _currentWidth;
        _updateHitbox();  // Update hitbox after resetting size
        break;
      case PowerUpType.speedUp:
      case PowerUpType.slowDown:
        break;
      default:
        break;
    }
  }

  @override
  void onRemove() {
    cancelAllPowerUps();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
    
    canvas.drawRRect(rRect, paint);
  }
}
