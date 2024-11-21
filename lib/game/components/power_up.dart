import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'paddle.dart';

enum PowerUpType {
  expandPaddle,
  shrinkPaddle,
  speedUp,
  slowDown,
  multiBall,
  extraLife
}

class PowerUp extends SpriteComponent with CollisionCallbacks {
  final PowerUpType type;
  final Vector2 screenSize;
  static const double fallSpeed = 100.0;
  static const double powerUpSize = 20.0;
  
  PowerUp({
    required this.type,
    required this.screenSize,
    required Vector2 position,
  }) : super(
    position: position,
    size: Vector2.all(powerUpSize),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()..color = _getColorForType(type);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;
    
    // Remove if fallen off screen
    if (position.y > screenSize.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is Paddle) {
      _applyPowerUp(other);
      removeFromParent();
    }
  }

  void _applyPowerUp(Paddle paddle) {
    switch (type) {
      case PowerUpType.expandPaddle:
        paddle.applyPowerUp(PowerUpType.expandPaddle);
        break;
      case PowerUpType.shrinkPaddle:
        paddle.applyPowerUp(PowerUpType.shrinkPaddle);
        break;
      case PowerUpType.speedUp:
        paddle.applyPowerUp(PowerUpType.speedUp);
        break;
      case PowerUpType.slowDown:
        paddle.applyPowerUp(PowerUpType.slowDown);
        break;
      case PowerUpType.multiBall:
        paddle.applyPowerUp(PowerUpType.multiBall);
        break;
      case PowerUpType.extraLife:
        paddle.applyPowerUp(PowerUpType.extraLife);
        break;
    }
  }

  Color _getColorForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.expandPaddle:
        return Colors.green;
      case PowerUpType.shrinkPaddle:
        return Colors.red;
      case PowerUpType.speedUp:
        return Colors.yellow;
      case PowerUpType.slowDown:
        return Colors.blue;
      case PowerUpType.multiBall:
        return Colors.purple;
      case PowerUpType.extraLife:
        return Colors.pink;
    }
  }
}
