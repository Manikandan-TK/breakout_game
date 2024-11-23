import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:breakout_game/game/components/paddle.dart';
import 'package:breakout_game/game/states/game_state.dart';
import 'package:breakout_game/config/game_config.dart';
import 'package:breakout_game/game/components/power_up.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Basic Paddle Tests', () {
    late Paddle paddle;
    late GameState gameState;
    final screenSize = Vector2(800, 600);

    setUp(() {
      gameState = GameState();
      paddle = Paddle(
        screenSize: screenSize,
        gameState: gameState,
        color: Colors.blue,
      );
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Paddle initializes with correct properties', () async {
      await paddle.onLoad();
      
      expect(paddle.position.x, screenSize.x / 2);
      expect(paddle.position.y, screenSize.y - GameConfig.paddleBottomOffset);
      expect(paddle.size.x, GameConfig.paddleWidth);
      expect(paddle.size.y, GameConfig.paddleHeight);
    });

    test('Paddle has correct hitbox after initialization', () async {
      await paddle.onLoad();
      
      final hitbox = paddle.children.whereType<RectangleHitbox>().first;
      expect(hitbox.size.x, GameConfig.paddleWidth);
      expect(hitbox.size.y, GameConfig.paddleHeight);
      expect(hitbox.isSolid, isTrue);
    });
  });

  group('Paddle Movement Tests', () {
    late Paddle paddle;
    late GameState gameState;
    final screenSize = Vector2(800, 600);

    setUp(() async {
      gameState = GameState();
      paddle = Paddle(
        screenSize: screenSize,
        gameState: gameState,
        color: Colors.blue,
      );
      await paddle.onLoad();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Paddle movement is constrained to left screen bound', () {
      paddle.moveToPosition(0);
      expect(paddle.position.x, paddle.size.x / 2);
    });

    test('Paddle movement is constrained to right screen bound', () {
      paddle.moveToPosition(screenSize.x);
      expect(paddle.position.x, screenSize.x - paddle.size.x / 2);
    });

    test('Paddle moves to valid position within bounds', () {
      final targetX = screenSize.x / 2;
      paddle.moveToPosition(targetX);
      expect(paddle.position.x, targetX);
    });
  });

  group('Paddle Power-up Tests', () {
    late Paddle paddle;
    late GameState gameState;
    final screenSize = Vector2(800, 600);

    setUp(() async {
      gameState = GameState();
      paddle = Paddle(
        screenSize: screenSize,
        gameState: gameState,
        color: Colors.blue,
      );
      await paddle.onLoad();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Paddle expands correctly with expand power-up', () {
      final initialWidth = paddle.size.x;
      
      paddle.applyPowerUp(PowerUpType.expandPaddle);
      
      expect(paddle.size.x, initialWidth * 1.5);
      expect(paddle.size.y, GameConfig.paddleHeight);
    });

    test('Paddle hitbox updates with size change', () {
      final initialHitboxSize = paddle.children
          .whereType<RectangleHitbox>()
          .first
          .size;
      
      paddle.applyPowerUp(PowerUpType.expandPaddle);
      
      final expandedHitboxSize = paddle.children
          .whereType<RectangleHitbox>()
          .first
          .size;
      
      expect(expandedHitboxSize.x, initialHitboxSize.x * 1.5);
      expect(expandedHitboxSize.y, initialHitboxSize.y);
    });

    test('Paddle resets to base size after power-up cancellation', () {
      paddle.applyPowerUp(PowerUpType.expandPaddle);
      paddle.cancelAllPowerUps();
      
      expect(paddle.size.x, GameConfig.paddleWidth);
      expect(paddle.size.y, GameConfig.paddleHeight);
    });
  });

  group('Paddle Reset Tests', () {
    late Paddle paddle;
    late GameState gameState;
    final screenSize = Vector2(800, 600);

    setUp(() async {
      gameState = GameState();
      paddle = Paddle(
        screenSize: screenSize,
        gameState: gameState,
        color: Colors.blue,
      );
      await paddle.onLoad();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Paddle resets position and size correctly', () {
      // Move paddle and apply power-up
      paddle.moveToPosition(100);
      paddle.applyPowerUp(PowerUpType.expandPaddle);
      
      // Reset paddle
      paddle.reset();
      
      // Check position and size
      expect(paddle.position.x, screenSize.x / 2);
      expect(paddle.position.y, screenSize.y - GameConfig.paddleBottomOffset);
      expect(paddle.size.x, GameConfig.paddleWidth);
      expect(paddle.size.y, GameConfig.paddleHeight);
    });

    test('Paddle cancels all power-ups on reset', () {
      // Apply power-up
      paddle.applyPowerUp(PowerUpType.expandPaddle);
      
      // Reset paddle
      paddle.reset();
      
      // Check that power-up effects are removed
      expect(paddle.size.x, GameConfig.paddleWidth);
      expect(paddle.children.whereType<RectangleHitbox>().first.size.x, GameConfig.paddleWidth);
    });
  });
}
