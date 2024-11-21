// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:async'; // Added import for Duration
import 'dart:developer'; // Import for logging
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/game_config.dart';  // Changed from shared/config
import '../states/game_state.dart';      // This one is correct
import '../../mixins/game_state_aware.dart';  // Changed from shared/mixins
import 'brick.dart';                     // This one is correct
import 'paddle.dart';                    // This one is correct

class Ball extends CircleComponent with CollisionCallbacks, GameStateAwareMixin {
  // Constants
  static const double defaultSpeed = 400.0;
  static const double minSpeed = 200.0;
  static const double maxSpeed = 600.0;
  
  // Collision Prevention Configurations
  static const double collisionEscapeThreshold = 5.0;
  static const int maxConsecutiveCollisions = 3;
  
  // Dependencies
  final Vector2 screenSize;
  
  // State
  Vector2 _velocity = Vector2.zero();
  bool _isActive = false;
  double _speed = defaultSpeed;
  final List<PositionComponent> _activeCollisions = [];
  
  // Collision Tracking
  int _consecutiveCollisions = 0;
  DateTime? _lastCollisionTime;
  final Set<Brick> _recentlyCollidedBricks = {};

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

  void _resetCollisionTracking() {
    _consecutiveCollisions = 0;
    _recentlyCollidedBricks.clear();
    _lastCollisionTime = null;
  }

  bool _isRecentCollision(Brick brick) {
    final now = DateTime.now();
    const recentThreshold = Duration(milliseconds: 100);
    
    return _recentlyCollidedBricks.contains(brick) && 
           now.difference(_lastCollisionTime ?? now) < recentThreshold;
  }

  void _trackCollision(Brick brick) {
    _lastCollisionTime = DateTime.now();
    _recentlyCollidedBricks.add(brick);
    _consecutiveCollisions++;

    // More Lenient Collision Reset
    if (_consecutiveCollisions > maxConsecutiveCollisions * 2) {
      _performEmergencyReset(brick);
    }
  }

  void _performEmergencyReset(Brick brick) {
    log('🚨 Emergency Ball Reset: Excessive Collisions Detected', 
      error: {
        'brick_position': brick.position,
        'ball_position': position,
        'current_velocity': _velocity,
        'consecutive_collisions': _consecutiveCollisions
      }
    );

    // Multi-Stage Reset Strategy
    _forceResetTrajectory();
    _resetCollisionTracking();

    // Additional Safety: Ensure ball is not near brick
    final safetyOffset = Vector2(
      (math.Random().nextDouble() - 0.5) * radius * 5,
      -radius * 3  // Ensure upward movement
    );
    position += safetyOffset;
  }

  void _forceResetTrajectory() {
    // More Dynamic and Predictable Reset
    final randomAngle = -math.pi/2 + (math.Random().nextDouble() - 0.5) * math.pi/2;
    
    _velocity = Vector2(
      math.cos(randomAngle) * _speed * 1.2,
      math.sin(randomAngle) * _speed * 1.2
    );

    // Ensure Minimum and Maximum Speed
    _velocity.normalize();
    _velocity *= math.max(math.min(_speed, maxSpeed), minSpeed);
  }

  void _logCollisionDiagnostics(Brick brick, Set<Vector2> points) {
    log('🔍 Collision Analysis: '
      'Brick: ${brick.hashCode}, '
      'Position: ${brick.position}, '
      'Ball Position: $position, '
      'Velocity: $_velocity, '
      'Collision Points: $points'
    );
  }

  void _escapeCollision(Vector2 collisionNormal, Brick brick) {
    // More Sophisticated Escape Mechanism
    final escapeDistance = radius * 1.5;
    final randomFactor = math.Random().nextDouble() * 0.5 + 0.75;
    
    // Primary Escape: Normal-based Movement with Randomness
    position += collisionNormal * escapeDistance * randomFactor;

    // Additional Escape Strategy: Move away from brick center
    final brickCenterOffset = (position - (brick.position + brick.size / 2)).normalized();
    position += brickCenterOffset * escapeDistance * 0.3;

    // Velocity Adjustment to Prevent Sticking
    _velocity += brickCenterOffset * _speed * 0.2;
  }

  void _handleBrickCollision(Brick brick, Set<Vector2> points) {
    if (brick.isBeingDestroyed) return;

    // Simple reflection based on which side of the brick was hit
    final brickCenter = brick.position + brick.size / 2;
    final toBall = position - brickCenter;
    
    // Determine if collision is more horizontal or vertical
    if (toBall.x.abs() * brick.size.y > toBall.y.abs() * brick.size.x) {
      _velocity.x *= -1; // Horizontal collision
    } else {
      _velocity.y *= -1; // Vertical collision
    }
    
    // Maintain consistent speed
    _velocity.normalize();
    _velocity *= math.min(math.max(_velocity.length, minSpeed), maxSpeed);
    
    // Destroy brick
    brick.hit();
  }

  void _handlePaddleCollision(Paddle paddle, Set<Vector2> points) {
    if (!_isActive || points.isEmpty) return;

    // Calculate relative position on paddle (-1 to 1)
    final relativeX = (position.x - paddle.position.x) / (paddle.size.x / 2);
    
    // Calculate bounce angle (between -60 and -120 degrees)
    final angle = math.pi * (0.33 + 0.33 * relativeX);
    
    // Set new velocity with consistent speed
    final speed = math.min(math.max(_velocity.length, minSpeed), maxSpeed);
    _velocity.x = speed * math.cos(angle);
    _velocity.y = -speed * math.sin(angle).abs(); // Ensure upward movement
    
    // Ensure ball is above paddle
    position.y = paddle.position.y - paddle.size.y/2 - radius - 1;
  }

  void _performBoundaryChecks() {
    // Screen Boundary Detection with Bounce
    final screenWidth = screenSize.x;
    final screenHeight = screenSize.y;

    // Horizontal Boundaries
    if (position.x - radius <= 0 || position.x + radius >= screenWidth) {
      _velocity.x *= -1;
      
      // Adjust Position to Prevent Sticking
      position.x = position.x - radius <= 0 
        ? radius 
        : screenWidth - radius;
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
    log('💥 Ball Lost: Position $position');
    gameState.loseLife();
    reset();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    add(CircleHitbox(
      radius: radius * 0.9,
      position: Vector2(radius * 0.1, radius * 0.1),
    ));
    reset();
  }
  
  void start() {
    if (!_isActive) {
      _isActive = true;
      // Initialize with a slightly random upward angle
      final angle = -math.pi/2 + (math.Random().nextDouble() - 0.5) * math.pi/3;
      _velocity = Vector2(math.cos(angle), math.sin(angle));
      // Normalize and scale to ensure consistent speed
      _velocity.normalize();
      _velocity.scale(_speed);
      
      log('🚀 Ball Launch: Angle: ${angle * 180 / math.pi}°, Velocity: $_velocity');
    }
  }
  
  void reset() {
    _isActive = false;
    _velocity.setZero();
    _speed = defaultSpeed;
    _activeCollisions.clear();
    position = Vector2(
      screenSize.x / 2,
      screenSize.y - GameConfig.paddleBottomOffset - GameConfig.paddleHeight - radius - 5
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (!_isActive) return;

    _activeCollisions.add(other);
    
    if (other is Paddle) {
      _handlePaddleCollision(other, intersectionPoints);
    } else if (other is Brick) {
      _handleBrickCollision(other, intersectionPoints);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    _activeCollisions.remove(other);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isActive) return;

    // Update position based on velocity
    position += _velocity * dt;

    // Enhanced Boundary Checks
    _performBoundaryChecks();

    // Prevent Extremely Low Velocity
    if (_velocity.length < minSpeed * 0.5) {
      _velocity.normalize();
      _velocity *= minSpeed;
    }

    // Log position and velocity for debugging
    if (_isActive) {
      log('Ball Update: Position: $position, Velocity: $_velocity');
    }
  }

  bool _checkBoundaries() {
    bool bounced = false;
    
    // Horizontal Boundaries
    if (position.x <= radius) {
      _velocity.x = _velocity.x.abs();
      position.x = radius;
      bounced = true;
    } else if (position.x >= screenSize.x - radius) {
      _velocity.x = -_velocity.x.abs();
      position.x = screenSize.x - radius;
      bounced = true;
    }
    
    // Vertical Boundaries
    if (position.y <= radius) {
      _velocity.y = _velocity.y.abs();
      position.y = radius;
      bounced = true;
    }

    // Bottom Boundary (Ball Lost)
    if (position.y + radius >= screenSize.y) {
      _handleBallLost();
      bounced = true;
    }
    
    return bounced;
  }
}
