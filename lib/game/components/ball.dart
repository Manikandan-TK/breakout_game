// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:async';
import 'dart:developer';
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
    add(CircleHitbox());
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
      screenSize.y - GameConfig.paddleBottomOffset - GameConfig.ballPaddleOffset,
    );
  }

  void launch() {
    if (_isActive) return;
    
    _isActive = true;
    // Launch at an angle between -45 and 45 degrees, favoring more vertical angles
    final angle = (math.Random().nextDouble() - 0.5) * math.pi / 4;
    _velocity = Vector2(math.sin(angle) * _speed, -math.cos(angle) * _speed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lastDt = dt;
    
    if (!_isActive) return;
    
    // Store previous position for collision checks
    position.clone();
    
    // Update position using current velocity
    position += _velocity * dt;
    
    // Check if ball is moving too slowly horizontally
    if (_velocity.x.abs() < _speed * 0.2) {
      // Add a slight horizontal component to prevent purely vertical movement
      final sign = _velocity.x >= 0 ? 1 : -1;
      _velocity.x = sign * _speed * 0.2;
      _velocity.normalize();
      _velocity *= _speed;
    }
    
    _performBoundaryChecks();
  }

  void _handleBrickCollision(Brick brick, Set<Vector2> points) {
    if (brick.isBeingDestroyed) return;

    // Calculate collision normal based on entry point
    final brickRect = brick.toRect();
    final ballRect = toRect();
    final normal = _calculateCollisionNormal(ballRect, brickRect);
    
    // Reflect velocity around the normal vector
    _velocity = _reflect(_velocity, normal);
    
    // Ensure ball is outside the brick
    if (normal.x != 0) {
      // Horizontal collision
      position.x = normal.x > 0 
          ? brickRect.right + radius 
          : brickRect.left - radius;
    } else {
      // Vertical collision
      position.y = normal.y > 0 
          ? brickRect.bottom + radius 
          : brickRect.top - radius;
    }
    
    // Play break sound
    (findGame() as BreakoutGame).audioService.playSound('break.wav');
    
    // Destroy brick
    brick.hit();
  }

  void _handlePaddleCollision(Paddle paddle, Set<Vector2> points) {
    if (!_isActive) return;

    // Get previous and current positions
    final previousY = position.y - _velocity.y * _lastDt;
    
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
    final speed = _velocity.length;
    _velocity.x = speed * math.sin(angle);
    _velocity.y = -speed * math.cos(angle).abs(); // Always bounce upward
    
    // Ensure ball is above paddle
    position.y = paddle.position.y - radius - 1;
    
    // Play hit sound
    (findGame() as BreakoutGame).audioService.playSound('hit.wav');
    
    // Apply slight speed increase, but respect maximum speed
    _speed = math.min(_speed * 1.05, maxSpeed);
    _velocity = _velocity.normalized() * _speed;
  }

  void _handleBallLost() {
    // Play game over sound
    (findGame() as BreakoutGame).audioService.playSound('game_over.wav');
    
    gameState.loseLife();
    reset();
  }

  Vector2 _calculateCollisionNormal(Rect ballRect, Rect brickRect) {
    final ballCenter = Vector2(ballRect.center.dx, ballRect.center.dy);
    final brickCenter = Vector2(brickRect.center.dx, brickRect.center.dy);
    final toCenter = ballCenter - brickCenter;
    
    // Calculate intersection depths
    final xOverlap = (ballRect.width + brickRect.width) / 2 - (ballCenter.x - brickCenter.x).abs();
    final yOverlap = (ballRect.height + brickRect.height) / 2 - (ballCenter.y - brickCenter.y).abs();
    
    // Return normal based on smallest overlap
    if (xOverlap < yOverlap) {
      return Vector2(toCenter.x > 0 ? 1 : -1, 0);
    } else {
      return Vector2(0, toCenter.y > 0 ? 1 : -1);
    }
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
    if (position.x - radius <= 0 || position.x + radius >= screenWidth) {
      _velocity.x *= -1;
      position.x = position.x - radius <= 0 ? radius : screenWidth - radius;
    }

    // Top Boundary
    if (position.y - radius <= 0) {
      _velocity.y *= -1;
      position.y = radius;
    }

    // Bottom Boundary (Ball Lost)
    if (position.y + radius >= screenHeight) {
      _handleBallLost();
    }
  }

  void _balanceVelocityComponents() {
    final absX = _velocity.x.abs();
    final absY = _velocity.y.abs();
    
    // Store original velocity for interpolation
    final originalVelocity = _velocity.clone();
    var velocityChanged = false;
    
    // If vertical velocity is too high compared to horizontal
    if (absY > absX * maxVerticalRatio) {
      final newAbsY = absX * maxVerticalRatio;
      _velocity.y = _velocity.y.sign * newAbsY;
      velocityChanged = true;
      log('📊 Adjusted high vertical velocity: ${_velocity.toString()}');
    }
    
    // If horizontal velocity is too low compared to vertical
    if (absX < absY * minHorizontalRatio) {
      final newAbsX = absY * minHorizontalRatio;
      _velocity.x = _velocity.x.sign * newAbsX;
      velocityChanged = true;
      log('📊 Adjusted low horizontal velocity: ${_velocity.toString()}');
    }
    
    if (velocityChanged) {
      // Smoothly interpolate between old and new velocity (70% new, 30% old)
      _velocity = _velocity * 0.7 + originalVelocity * 0.3;
      
      // Normalize and maintain speed
      _velocity.normalize();
      _velocity *= _speed;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Brick) {
      _handleBrickCollision(other, intersectionPoints);
    } else if (other is Paddle) {
      _handlePaddleCollision(other, intersectionPoints);
    }
  }
}
