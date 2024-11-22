import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../breakout_game.dart';
import 'paddle.dart';

enum PowerUpType {
  expandPaddle('↔', Colors.green),
  shrinkPaddle('↕', Colors.red),
  speedUp('⚡', Colors.yellow),
  slowDown('🐌', Colors.blue),
  multiBall('⚪', Colors.purple),
  extraLife('❤', Colors.pink);

  final String icon;
  final Color color;

  const PowerUpType(this.icon, this.color);
}

typedef PowerUpCollectCallback = void Function(PowerUpType type);

class PowerUp extends RectangleComponent with CollisionCallbacks {
  final PowerUpType type;
  final Vector2 screenSize;
  final PowerUpCollectCallback? onCollect;
  static const double fallSpeed = 100.0;
  static const double powerUpSize = 20.0;
  bool _isCollected = false;

  PowerUp({
    required this.type,
    required this.screenSize,
    required Vector2 position,
    this.onCollect,
  }) : super(
    position: position,
    size: Vector2.all(powerUpSize),
    paint: Paint()..color = type.color,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isCollected) {
      position.y += fallSpeed * dt;
      
      // Remove if fallen off screen
      if (position.y > screenSize.y) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (!_isCollected && other is Paddle) {
      collect();
    }
  }

  void collect() {
    if (!_isCollected) {
      _isCollected = true;
      
      // Play power-up sound
      (findGame() as BreakoutGame).audioService.playSound('powerup.mp3');
      
      // Apply power-up effect
      _applyPowerUp();
      
      // Remove from game
      removeFromParent();
    }
  }

  void _applyPowerUp() {
    switch (type) {
      case PowerUpType.expandPaddle:
        (findGame() as BreakoutGame).paddle.applyPowerUp(PowerUpType.expandPaddle);
        break;
      case PowerUpType.shrinkPaddle:
        (findGame() as BreakoutGame).paddle.applyPowerUp(PowerUpType.shrinkPaddle);
        break;
      case PowerUpType.speedUp:
        (findGame() as BreakoutGame).paddle.applyPowerUp(PowerUpType.speedUp);
        break;
      case PowerUpType.slowDown:
        (findGame() as BreakoutGame).paddle.applyPowerUp(PowerUpType.slowDown);
        break;
      case PowerUpType.multiBall:
        (findGame() as BreakoutGame).paddle.applyPowerUp(PowerUpType.multiBall);
        break;
      case PowerUpType.extraLife:
        (findGame() as BreakoutGame).paddle.applyPowerUp(PowerUpType.extraLife);
        break;
    }
    onCollect?.call(type);
  }
}
