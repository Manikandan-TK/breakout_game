import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../managers/managers.dart';

class Brick extends RectangleComponent with CollisionCallbacks {
  final Color color;
  final PowerUpManager powerUpManager;
  bool _isDestroyed = false;
  bool _isBeingDestroyed = false;
  
  Brick({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.powerUpManager,
  }) : super(
    position: position,
    size: size,
    anchor: Anchor.topLeft,
  );

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4.0));
    
    canvas.drawRRect(rRect, paint);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: size,
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    ));
  }

  void hit() {
    if (!_isDestroyed && !_isBeingDestroyed) {
      _isBeingDestroyed = true;
      
      // Immediately disable collision and remove from game state
      removeAll(children.whereType<RectangleHitbox>());
      
      // Try to spawn power-up
      powerUpManager.trySpawnPowerUp(position + size / 2, this);
      
      // Start fade out animation
      add(
        ColorEffect(
          const Color(0x00000000),
          EffectController(duration: 0.2),
          onComplete: () {
            _isDestroyed = true;
            removeFromParent();
          },
        ),
      );
    }
  }

  bool get isDestroyed => _isDestroyed;
  bool get isBeingDestroyed => _isBeingDestroyed;
}