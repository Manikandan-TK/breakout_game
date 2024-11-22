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
import 'brick.dart';
import 'paddle.dart';

class Ball extends CircleComponent with CollisionCallbacks, GameStateAwareMixin {
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
  final List<PositionComponent> _activeCollisions = [];
  DateTime? _lastCollisionTime;
  int _consecutiveCollisions = 0;
  Vector2? _lastCollisionPosition;

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
    _isActive = false;
    _velocity = Vector2.zero();
    _speed = defaultSpeed;
    position = Vector2(
      screenSize.x / 2,
      screenSize.y - GameConfig.paddleBottomOffset - GameConfig.paddleHeight - radius - 1,
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
    
    if (!_isActive) return;
    
    final oldPosition = position.clone();
    position += _velocity * dt;
    
    // Check for potential stuck conditions
    if ((position - oldPosition).length < _speed * dt * 0.1) {
      log('⚠️ Potential stuck condition detected! Speed: ${_velocity.length}, Movement: ${(position - oldPosition).length}');
      // Add a stronger random impulse to help unstick
      _velocity += Vector2(
        (math.Random().nextDouble() - 0.5) * _speed * 0.4,
        (math.Random().nextDouble() - 0.5) * _speed * 0.4
      );
      _balanceVelocityComponents();
    }
    
    // Periodically balance velocity components
    if (math.Random().nextDouble() < 0.05) { // 5% chance each frame
      _balanceVelocityComponents();
    }
    
    _performBoundaryChecks();
  }

  void _handleBrickCollision(Brick brick, Set<Vector2> points) {
    if (brick.isBeingDestroyed) return;

    // Check for rapid consecutive collisions
    final now = DateTime.now();
    if (_lastCollisionTime != null) {
      final timeSinceLastCollision = now.difference(_lastCollisionTime!).inMilliseconds;
      if (timeSinceLastCollision < 16) { // Less than one frame at 60fps
        _consecutiveCollisions++;
        log('⚠️ Rapid collision detected! Count: $_consecutiveCollisions, Time: ${timeSinceLastCollision}ms');
        
        if (_consecutiveCollisions >= maxConsecutiveCollisions) {
          _performEmergencyEscape();
          return;
        }
      } else {
        _consecutiveCollisions = 0;
      }
    }
    _lastCollisionTime = now;
    _lastCollisionPosition = position.clone();

    // Get the collision point (average if multiple points)
    final collisionPoint = points.reduce((a, b) => a + b) / points.length.toDouble();
    
    // Calculate collision normal based on which side was hit
    final brickCenter = brick.position + brick.size / 2;
    final toBall = position - brickCenter;
    final relativeCollision = collisionPoint - brickCenter;
    
    // Calculate collision angles
    final horizontalAngle = (relativeCollision.x / brick.size.x).abs();
    final verticalAngle = (relativeCollision.y / brick.size.y).abs();
    
    // Add slight randomness to reflection
    final randomFactor = 1.0 + (math.Random().nextDouble() * 0.1 - 0.05);
    
    // Determine collision side with improved accuracy
    if (horizontalAngle > verticalAngle) {
      _velocity.x *= -1.0 * randomFactor;
      if (toBall.x > 0) {
        position.x = brick.position.x + brick.size.x + radius + 2;
      } else {
        position.x = brick.position.x - radius - 2;
      }
    } else {
      _velocity.y *= -1.0 * randomFactor;
      if (toBall.y > 0) {
        position.y = brick.position.y + brick.size.y + radius + 2;
      } else {
        position.y = brick.position.y - radius - 2;
      }
    }
    
    // Balance velocity components
    _balanceVelocityComponents();
    
    // Add very slight randomness to prevent repetitive patterns
    _velocity.rotate((math.Random().nextDouble() * 0.035) - 0.0175);
    
    log('🎯 Brick Collision - Before: pos=${position.toString()}, vel=${_velocity.toString()}');
    log('🎯 Brick Collision - After: pos=${position.toString()}, vel=${_velocity.toString()}');
    
    // Destroy brick
    brick.hit();
  }

  void _performEmergencyEscape() {
    log('🚨 Emergency escape triggered!');
    
    // Move ball away from last collision
    if (_lastCollisionPosition != null) {
      final escapeDirection = position - _lastCollisionPosition!;
      if (escapeDirection.length < 0.1) {
        // If no clear escape direction, move diagonally down-right
        position += Vector2(radius * 4, radius * 4);
      } else {
        position += escapeDirection.normalized() * (radius * 4);
      }
    }
    
    // Reset collision counter
    _consecutiveCollisions = 0;
    
    // Add strong random velocity change
    final angle = math.Random().nextDouble() * math.pi * 2;
    _velocity = Vector2(math.cos(angle), math.sin(angle)) * _speed;
    _balanceVelocityComponents();
  }

  void _handlePaddleCollision(Paddle paddle, Set<Vector2> points) {
    if (!_isActive) return;

    // Get collision point
    final collisionPoint = points.reduce((a, b) => a + b) / points.length.toDouble();
    
    // Calculate relative hit position (-1 to 1)
    final paddleCenter = paddle.position + paddle.size / 2;
    final hitPosition = (collisionPoint.x - paddleCenter.x) / (paddle.size.x / 2);
    
    // Calculate new angle based on hit position
    // Max angle is 60 degrees (π/3 radians)
    const maxAngle = math.pi / 3;
    final angle = hitPosition * maxAngle * 0.8;
    
    // Set new velocity direction
    final direction = Vector2(math.sin(angle), -math.cos(angle));
    
    // Add slight speed variation
    final speedVariation = 1.0 + (math.Random().nextDouble() * 0.1 - 0.05);
    _velocity = direction * (_speed * speedVariation);
    
    // Ensure minimum vertical component
    if (_velocity.y.abs() < _speed * 0.4) {
      _velocity.y = -_speed * 0.4 * _velocity.y.sign;
      _balanceVelocityComponents();
    }
    
    // Push ball out of paddle
    position.y = paddle.position.y - radius - 1;
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

  void _handleBallLost() {
    gameState.loseLife();
    reset();
  }

  void _balanceVelocityComponents() {
    final absX = _velocity.x.abs();
    final absY = _velocity.y.abs();
    
    // If vertical velocity is too high compared to horizontal
    if (absY > absX * maxVerticalRatio) {
      final newAbsY = absX * maxVerticalRatio;
      _velocity.y = _velocity.y.sign * newAbsY;
      log('📊 Adjusted high vertical velocity: ${_velocity.toString()}');
    }
    
    // If horizontal velocity is too low compared to vertical
    if (absX < absY * minHorizontalRatio) {
      final newAbsX = absY * minHorizontalRatio;
      _velocity.x = _velocity.x.sign * newAbsX;
      log('📊 Adjusted low horizontal velocity: ${_velocity.toString()}');
    }
    
    // Normalize and maintain speed
    _velocity.normalize();
    _velocity *= _speed;
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
