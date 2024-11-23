import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../breakout_game.dart';
import 'paddle.dart';

enum PowerUpType {
  expandPaddle('⬌', Color(0xFF00E676)),    // Bright green for positive
  shrinkPaddle('⬍', Color(0xFFFF1744)),    // Bright red for negative
  speedUp('⚡', Color(0xFFFFD700)),         // Gold for speed boost
  slowDown('🐢', Color(0xFF29B6F6)),        // Light blue for slow
  multiBall('⚅', Color(0xFFAA00FF)),       // Bright purple for multi-ball
  extraLife('♥', Color(0xFFFF4081));       // Pink for life

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

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw glow effect
    final glowPaint = Paint()
      ..color = type.color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRect(size.toRect(), glowPaint);
    
    // Draw power-up background
    final bgPaint = Paint()
      ..color = type.color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4.0));
    canvas.drawRRect(rRect, bgPaint);

    // Draw icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: type.icon,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.x * 0.7,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}
