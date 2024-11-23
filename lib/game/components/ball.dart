// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';
import '../states/game_state.dart';
import '../../mixins/game_state_aware.dart';
import '../breakout_game.dart';
import 'brick.dart';
import 'paddle.dart';

class Ball extends CircleComponent
    with CollisionCallbacks, GameStateAwareMixin, HasGameRef<BreakoutGame> {
  // Constants
  static const double defaultSpeed = 400.0;
  static const double minSpeed = 300.0;
  static const double maxSpeed = 600.0;
  static const double maxVerticalRatio = 1.2;
  static const double minHorizontalRatio = 0.6;
  static const int maxConsecutiveCollisions = 3;

  // Dependencies
  final Vector2 screenSize;

  // State
  Vector2 _velocity = Vector2.zero();
  bool _isActive = false;
  double _speed = defaultSpeed;
  double _lastDt = 0;

  // Getters and setters
  Vector2 get velocity => _velocity;
  set velocity(Vector2 value) {
    _velocity = value;
    _speed = _velocity.length;
  }

  bool get isActive => _isActive;

  Ball({
    required this.screenSize,
    required GameState gameState,
  }) : super(
          radius: GameConfig.ballRadius,
          paint: Paint()..color = GameConfig.ballColor,
          anchor: Anchor.center,
        ) {
    this.gameState = gameState;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for precise collision detection
    add(CircleHitbox(
      radius: radius,
      isSolid: true,
      position: Vector2.zero(),
      anchor: Anchor.center,
    ));

    reset();
  }

  void reset() {
    // Reset ball state
    _isActive = false;
    _velocity = Vector2.zero();
    _speed = defaultSpeed;
    _lastDt = 0;

    // Reset position to just above paddle
    position = Vector2(
      screenSize.x / 2,
      screenSize.y -
          GameConfig.paddleBottomOffset -
          GameConfig.ballPaddleOffset,
    );
  }

  void launch() {
    if (_isActive) return;

    _isActive = true;
    // Launch at an angle between -45 and 45 degrees, favoring more vertical angles
    final angle = (math.Random().nextDouble() - 0.5) * math.pi / 4;
    _velocity = Vector2(math.sin(angle), -math.cos(angle));
    // Ensure initial speed is at least minSpeed
    _velocity.normalize();
    _velocity *= math.max(_speed, minSpeed);
  }

  @override
  void update(double dt) {
    if (!isActive) return;

    // Never allow zero velocity
    if (velocity.length < 0.0001) {
      velocity = Vector2(0, -1) * minSpeed; // Default upward movement
    }

    // Normalize velocity while preserving direction
    final currentSpeed = velocity.length;
    if (currentSpeed < minSpeed) {
      velocity = velocity.normalized() * minSpeed;
    } else if (currentSpeed > maxSpeed) {
      velocity = velocity.normalized() * maxSpeed;
    }

    // Update position
    final newPosition = position + velocity * dt;

    // Handle wall collisions only if we would actually hit a wall
    if (newPosition.x <= radius) {
      position.x = radius;
      velocity.x = velocity.x.abs(); // Ensure positive x velocity
    } else if (newPosition.x >= screenSize.x - radius) {
      position.x = screenSize.x - radius;
      velocity.x = -velocity.x.abs(); // Ensure negative x velocity
    } else {
      position.x = newPosition.x; // No collision, update normally
    }

    if (newPosition.y <= radius) {
      position.y = radius;
      velocity.y = velocity.y.abs(); // Ensure positive y velocity
    } else {
      position.y = newPosition.y; // No collision, update normally
    }

    // Check if ball is below paddle (game over)
    if (position.y >= screenSize.y + radius) {
      reset();
      gameState.loseLife();
    }

    // Store dt for collision handling
    _lastDt = dt;
  }

  void _handleBrickCollision(Brick brick, Set<Vector2> points) {
    if (brick.isBeingDestroyed) return;

    // Get previous position
    final previousBallRect = Rect.fromCircle(
      center: Offset(position.x - (velocity.x * _lastDt), position.y - (velocity.y * _lastDt)),
      radius: radius,
    );

    // Calculate collision normal based on entry point and previous position
    final brickRect = brick.toRect();
    final ballRect = toRect();
    final normal =
        _calculateCollisionNormal(ballRect, previousBallRect, brickRect);

    // Reflect velocity around the normal vector
    velocity = _reflect(velocity, normal);

    // Apply a small speed increase on brick hit, but respect max speed
    velocity = velocity.normalized() * math.min(velocity.length * 1.02, maxSpeed);

    // Prevent too vertical or horizontal movement
    const minAngle = math.pi / 6; // 30 degrees
    final angle = math.atan2(velocity.y, velocity.x);
    if (angle.abs() < minAngle || (math.pi - angle.abs()) < minAngle) {
      // Too horizontal - adjust angle while maintaining direction
      final newAngle = angle.sign * minAngle;
      final speed = velocity.length;
      velocity.x = speed * math.cos(newAngle);
      velocity.y = speed * math.sin(newAngle);
    } else if ((math.pi / 2 - angle.abs()) < minAngle) {
      // Too vertical - adjust angle while maintaining direction
      final newAngle = angle.sign * (math.pi / 2 - minAngle);
      final speed = velocity.length;
      velocity.x = speed * math.cos(newAngle);
      velocity.y = speed * math.sin(newAngle);
    }

    // Ensure ball is outside the brick with a small buffer
    const buffer = 1.0; // 1 pixel buffer
    if (normal.x != 0) {
      // Horizontal collision
      position.x = normal.x > 0
          ? brickRect.right + radius + buffer
          : brickRect.left - radius - buffer;
    } else {
      // Vertical collision
      position.y = normal.y > 0
          ? brickRect.bottom + radius + buffer
          : brickRect.top - radius - buffer;
    }

    // Play break sound
    (findGame() as BreakoutGame).audioService.playSound('break.wav');

    // Destroy brick
    brick.hit();
  }

  Vector2 _calculateCollisionNormal(
      Rect ballRect, Rect previousBallRect, Rect brickRect) {
    final ballCenter = Vector2(ballRect.center.dx, ballRect.center.dy);
    final previousBallCenter =
        Vector2(previousBallRect.center.dx, previousBallRect.center.dy);
    final brickCenter = Vector2(brickRect.center.dx, brickRect.center.dy);

    // Calculate movement direction
    final movementDir = ballCenter - previousBallCenter;
    if (movementDir.length2 > 0) {
      movementDir.normalize();
    }

    // Calculate relative position to brick center
    final toBrick = ballCenter - brickCenter;

    // Calculate intersection points with brick edges
    final intersectTop = previousBallCenter.y - radius <= brickRect.top &&
        ballCenter.y + radius >= brickRect.top;
    final intersectBottom = previousBallCenter.y + radius >= brickRect.bottom &&
        ballCenter.y - radius <= brickRect.bottom;
    final intersectLeft = previousBallCenter.x - radius <= brickRect.left &&
        ballCenter.x + radius >= brickRect.left;
    final intersectRight = previousBallCenter.x + radius >= brickRect.right &&
        ballCenter.x - radius <= brickRect.right;

    // Determine collision face based on movement and intersection
    if (movementDir.y > 0 && intersectTop) {
      return Vector2(0, -1); // Hit from top
    } else if (movementDir.y < 0 && intersectBottom) {
      return Vector2(0, 1); // Hit from bottom
    } else if (movementDir.x > 0 && intersectLeft) {
      return Vector2(-1, 0); // Hit from left
    } else if (movementDir.x < 0 && intersectRight) {
      return Vector2(1, 0); // Hit from right
    }

    // Fallback: use closest edge if no clear intersection
    final toEdge = Vector2(
        toBrick.x.abs() > brickRect.width / 2 ? toBrick.x.sign : 0,
        toBrick.y.abs() > brickRect.height / 2 ? toBrick.y.sign : 0);

    return toEdge.normalized();
  }

  void _handlePaddleCollision(Paddle paddle, Set<Vector2> points) {
    if (!_isActive) return;

    // Get previous and current positions
    final previousY = position.y - velocity.y * _lastDt;

    // Only handle collision if the ball was above the paddle in the previous frame
    if (previousY >= paddle.position.y - radius) {
      return; // Ball hit paddle from below or side, ignore collision
    }

    // Calculate hit position relative to paddle center (-1 to 1)
    final paddleCenter = paddle.position + paddle.size / 2;
    final hitPosition = (position.x - paddleCenter.x) / (paddle.size.x / 2);

    // Clamp hit position to ensure it stays within bounds
    final clampedHit = hitPosition.clamp(-1.0, 1.0);

    // Calculate reflection angle based on hit position
    // Center hits bounce more vertically, edge hits bounce at wider angles
    const baseAngle = math.pi / 6; // 30 degrees
    final angle = baseAngle * clampedHit;

    // Calculate new velocity while preserving momentum
    final speed = velocity.length;
    velocity.x = speed * math.sin(angle);
    velocity.y = -speed * math.cos(angle).abs(); // Always bounce upward

    // Ensure ball is above paddle
    position.y = paddle.position.y - radius - 1;

    // Play hit sound
    (findGame() as BreakoutGame).audioService.playSound('hit.wav');

    // Apply slight speed increase, but respect maximum speed
    velocity = velocity.normalized() * math.min(velocity.length * 1.05, maxSpeed);
  }

  void _handleBallLost() {
    // Play game over sound
    (findGame() as BreakoutGame).audioService.playSound('game_over.wav');

    gameState.loseLife();
    reset();
  }

  Vector2 _reflect(Vector2 velocity, Vector2 normal) {
    // v' = v - 2(v·n)n
    final dot = velocity.dot(normal);
    return velocity - (normal * (2 * dot));
  }

  void _performBoundaryChecks() {
    // Screen Boundary Detection with Bounce
    final screenWidth = screenSize.x;
    final screenHeight = screenSize.y;

    // Horizontal Boundaries
    if (position.x - radius <= 0) {
      position.x = radius;
      velocity.x = velocity.x.abs(); // Ensure positive x velocity
    } else if (position.x + radius >= screenWidth) {
      position.x = screenWidth - radius;
      velocity.x = -velocity.x.abs(); // Ensure negative x velocity
    }

    // Top Boundary
    if (position.y - radius <= 0) {
      position.y = radius;
      velocity.y = velocity.y.abs(); // Ensure positive y velocity
    }

    // Bottom Boundary (Ball Lost)
    if (position.y + radius >= screenHeight) {
      _handleBallLost();
    }
  }

  void _balanceVelocityComponents() {
    // Temporarily disabled for testing
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Brick) {
      _handleBrickCollision(other, intersectionPoints);
    } else if (other is Paddle) {
      _handlePaddleCollision(other, intersectionPoints);
    }
  }
}
