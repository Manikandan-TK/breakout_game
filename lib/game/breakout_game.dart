import 'package:breakout_game/config/game_config.dart';
import 'package:breakout_game/core/interfaces/game_interface.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'components/ball.dart';
import 'components/brick.dart';
import 'components/paddle.dart';
import 'states/game_state.dart';
import 'managers/brick_manager.dart';
import 'managers/particle_manager.dart';
import 'managers/power_up_manager.dart';
import '../ui/game_over_overlay.dart';
import '../ui/game_ui_manager.dart';

// Mixin for components that need game state
// mixin GameStateAware {
//   GameState get gameState;
// }

class BreakoutGame extends FlameGame
    with HasCollisionDetection, MouseMovementDetector, KeyboardEvents, TapCallbacks
    implements GameInterface {
  late final GameState gameState;
  late final Ball ball;
  late final Paddle paddle;
  late final BrickManager brickManager;
  late final GameUIManager uiManager;
  late final ParticleManager particleManager;
  late final PowerUpManager powerUpManager;

  @override
  Color backgroundColor() => const Color(0xFFF5F5DC);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize game size based on screen size
    final screenSize = Vector2(size.x, size.y);
    final gameSize = GameConfig.defaultGameSize(screenSize);

    // Initialize game state
    gameState = GameState();

    // Initialize UI
    uiManager = GameUIManager(gameState: gameState);
    add(uiManager);

    // Initialize managers
    powerUpManager = PowerUpManager(
      screenSize: gameSize,
      gameState: gameState,
    );
    brickManager = BrickManager(
      gameState: gameState,
      powerUpManager: powerUpManager,
    );
    particleManager = ParticleManager();

    // Initialize components
    paddle = Paddle(
      screenSize: gameSize,
      gameState: gameState,
      color: GameConfig.paddleColor,
    );
    ball = Ball(screenSize: gameSize, gameState: gameState);

    // Add game components
    await addAll([
      powerUpManager,
      paddle,
      ball,
      brickManager,
      particleManager,
    ]);

    // Initialize bricks
    await brickManager.createBricks(gameSize);

    // Initialize game state listener
    gameState.addListener(_handleGameStateChange);
  }

  void _handleGameStateChange() {
    if (gameState.isGameOver) {
      _showGameOver();
    }
  }

  void _showGameOver() {
    if (!gameState.isGameOver) return;

    overlays.add(GameOverOverlay.id);
    pauseEngine();
  }

  void resetGame() {
    overlays.remove(GameOverOverlay.id);
    gameState.restart();
    ball.reset();
    paddle.reset();
    brickManager.resetBricks(size);
    powerUpManager.reset();
    resumeEngine();
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    developer.log('Mouse Move: ${info.eventPosition.global.x}');
    if (!gameState.isGameOver) {
      paddle.moveToPosition(info.eventPosition.global.x);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!gameState.isGameOver && !ball.isActive) {
      ball.start();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    developer.log('Key Event: ${event.logicalKey.keyLabel}, Keys Pressed: ${keysPressed.map((k) => k.keyLabel).join(", ")}');
    
    if (gameState.isGameOver) {
      developer.log('Game is over, ignoring input');
      return KeyEventResult.ignored;
    }

    // Ball launch with spacebar
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      developer.log('Space pressed, ball active: ${ball.isActive}');
      if (!ball.isActive) {
        developer.log('Launching ball');
        ball.start();
        return KeyEventResult.handled;
      }
    }

    // Paddle movement with arrow keys
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      developer.log('Moving paddle left');
      paddle.moveToPosition(paddle.position.x - 10);
      return KeyEventResult.handled;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      developer.log('Moving paddle right');
      paddle.moveToPosition(paddle.position.x + 10);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void onRemove() {
    gameState.removeListener(_handleGameStateChange);
    uiManager.dispose();
    super.onRemove();
  }

  @override
  void addExplosion(Vector2 position, Color color) {
    particleManager.createExplosion(position, color);
  }

  void spawnMultiBall() {
    // Create two additional balls at slightly different angles
    final ballPos = ball.position.clone();
    final velocity1 = Vector2(-1, -1)
      ..normalize()
      ..scale(GameConfig.initialBallSpeed);
    final velocity2 = Vector2(1, -1)
      ..normalize()
      ..scale(GameConfig.initialBallSpeed);

    final ball1 = Ball(screenSize: size, gameState: gameState)
      ..position = ballPos
      ..velocity = velocity1;

    final ball2 = Ball(screenSize: size, gameState: gameState)
      ..position = ballPos
      ..velocity = velocity2;

    add(ball1);
    add(ball2);
  }

  void addExtraLife() {
    gameState.addLife();
  }

  @override
  void removeBrick(Brick brick) {
    gameState.removeBrick(brick);
  }
}
