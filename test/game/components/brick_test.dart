import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breakout_game/game/components/brick.dart';
import 'package:breakout_game/game/managers/managers.dart';
import 'package:breakout_game/game/states/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Basic Brick Tests', () {
    late PowerUpManager powerUpManager;
    late GameState gameState;
    late Brick brick;
    final screenSize = Vector2(800, 600);
    final brickSize = Vector2(60, 20);
    const brickColor = Colors.blue;

    setUp(() {
      gameState = GameState();
      powerUpManager = PowerUpManager(
        screenSize: screenSize,
        gameState: gameState,
      );
      brick = Brick(
        position: Vector2.zero(),
        size: brickSize,
        color: brickColor,
        powerUpManager: powerUpManager,
        gameState: gameState,
      );
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Brick initializes with correct properties', () {
      expect(brick.size.x, equals(brickSize.x));
      expect(brick.size.y, equals(brickSize.y));
      expect(brick.color, equals(brickColor));
      expect(brick.isDestroyed, isFalse);
      expect(brick.isBeingDestroyed, isFalse);
    });

    test('Brick starts destruction sequence on hit', () {
      expect(brick.isDestroyed, isFalse);
      expect(brick.isBeingDestroyed, isFalse);
      
      brick.hit();
      
      expect(brick.isDestroyed, isFalse);
      expect(brick.isBeingDestroyed, isTrue);
    });
  });

  group('Brick Game State Tests', () {
    late PowerUpManager powerUpManager;
    late GameState gameState;
    late Brick brick;
    final screenSize = Vector2(800, 600);
    final brickSize = Vector2(60, 20);

    setUp(() {
      gameState = GameState();
      powerUpManager = PowerUpManager(
        screenSize: screenSize,
        gameState: gameState,
      );
      brick = Brick(
        position: Vector2.zero(),
        size: brickSize,
        color: Colors.blue,
        powerUpManager: powerUpManager,
        gameState: gameState,
      );
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Brick updates score on destruction', () {
      final initialScore = gameState.score;
      
      brick.hit();
      
      // Score should update immediately when brick is hit
      expect(gameState.score, equals(initialScore + 10));
    });

    test('Brick is removed from game state on destruction', () {
      gameState.addBrick(brick);
      expect(gameState.bricks.contains(brick), isTrue);
      
      brick.hit();
      
      expect(gameState.bricks.contains(brick), isFalse);
    });
  });

  group('Brick Animation Tests', () {
    late PowerUpManager powerUpManager;
    late GameState gameState;
    late Brick brick;
    final screenSize = Vector2(800, 600);
    final brickSize = Vector2(60, 20);

    setUp(() {
      gameState = GameState();
      powerUpManager = PowerUpManager(
        screenSize: screenSize,
        gameState: gameState,
      );
      brick = Brick(
        position: Vector2.zero(),
        size: brickSize,
        color: Colors.blue,
        powerUpManager: powerUpManager,
        gameState: gameState,
      );
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Brick starts fade out animation on hit', () {
      expect(brick.children.whereType<ColorEffect>().isEmpty, isTrue);
      
      brick.hit();
      
      expect(brick.children.whereType<ColorEffect>().length, equals(1));
    });

    test('Brick removes hitbox on hit', () async {
      await brick.onLoad(); // Add hitbox
      expect(brick.children.whereType<RectangleHitbox>().length, equals(1));
      
      brick.hit();
      
      expect(brick.children.whereType<RectangleHitbox>().isEmpty, isTrue);
    });
  });
}
