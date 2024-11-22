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
import 'components/power_up.dart';
import 'states/game_state.dart';
import 'managers/brick_manager.dart';
import 'managers/particle_manager.dart';
import 'managers/power_up_manager.dart';
import '../ui/game_over_overlay.dart';
import '../ui/game_ui_manager.dart';
import '../core/services/audio_service.dart';

// Mixin for components that need game state
// mixin GameStateAware {
//   GameState get gameState;
// }

class BreakoutGame extends FlameGame
    with HasCollisionDetection, MouseMovementDetector, KeyboardEvents, TapCallbacks
    implements GameInterface {
  late final GameState gameState;
  late final Ball _ball;
  late final Paddle _paddle;
  late final BrickManager _brickManager;
  late final GameUIManager uiManager;
  late final ParticleManager particleManager;
  late final PowerUpManager _powerUpManager;
  late final AudioService audioService;
  bool _isPaused = false;

  // Getters for game components
  Paddle get paddle => _paddle;
  Ball get ball => _ball;

  @override
  Color backgroundColor() => const Color(0xFFF5F5DC);

  @override
  Future<void> onLoad() async {
    try {
      // Initialize services
      audioService = AudioService();
      await audioService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('Audio initialization timed out');
          return;
        },
      );
      
      // Start background music
      await audioService.startBackgroundMusic();
      
      // Initialize game state
      gameState = GameState();
      
      // Wait for super.onLoad() to complete before proceeding
      await super.onLoad();

      // Initialize game size based on screen size
      final screenSize = Vector2(size.x, size.y);
      final gameSize = GameConfig.defaultGameSize(screenSize);

      // Initialize UI
      uiManager = GameUIManager(gameState: gameState);
      await add(uiManager);

      // Initialize managers
      _powerUpManager = PowerUpManager(
        screenSize: gameSize,
        gameState: gameState,
      );
      _brickManager = BrickManager(
        gameState: gameState,
        powerUpManager: _powerUpManager,
      );
      particleManager = ParticleManager();

      // Initialize components
      _paddle = Paddle(
        screenSize: gameSize,
        gameState: gameState,
        color: GameConfig.paddleColor,
      );
      _ball = Ball(screenSize: gameSize, gameState: gameState);

      // Add game components one by one and wait for each
      await add(_powerUpManager);
      await add(_paddle);
      await add(_ball);
      await add(_brickManager);
      await add(particleManager);

      // Initialize bricks
      await _brickManager.createBricks(gameSize);

      // Initialize game state listener
      gameState.addListener(_handleGameStateChange);
      
    } catch (e) {
      developer.log('Error during game initialization: $e');
      rethrow;  // Let the error builder handle it
    }
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
    // Remove all existing power-ups
    children.whereType<PowerUp>().forEach((powerUp) => powerUp.removeFromParent());

    // Reset game state
    _isPaused = false;
    overlays.remove('pause_menu');
    overlays.remove('game_over');
    gameState.restart();
    
    // Reset all game components
    _ball.reset();
    _paddle.reset();
    _brickManager.resetBricks(size);
    _powerUpManager.reset();
    
    // Resume game engine
    resumeEngine();
  }


  @override
  void onMouseMove(PointerHoverInfo info) {
    developer.log('Mouse Move: ${info.eventPosition.global.x}');
    if (!gameState.isGameOver) {
      _paddle.moveToPosition(info.eventPosition.global.x);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!gameState.isGameOver && !_ball.isActive) {
      _ball.launch();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    developer.log('Key Event: ${event.logicalKey.keyLabel}, Keys Pressed: ${keysPressed.map((k) => k.keyLabel).join(", ")}');
    
    // Handle pause menu
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _togglePause();
      return KeyEventResult.handled;
    }

    if (_isPaused) {
      return KeyEventResult.ignored;
    }

    if (gameState.isGameOver) {
      developer.log('Game is over, ignoring input');
      return KeyEventResult.ignored;
    }

    // Ball launch with spacebar
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      developer.log('Space pressed, ball active: ${_ball.isActive}');
      if (!_ball.isActive) {
        developer.log('Launching ball');
        _ball.launch();
        return KeyEventResult.handled;
      }
    }

    // Paddle movement with arrow keys
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      developer.log('Moving paddle left');
      _paddle.moveToPosition(_paddle.position.x - 10);
      return KeyEventResult.handled;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      developer.log('Moving paddle right');
      _paddle.moveToPosition(_paddle.position.x + 10);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _togglePause() {
    if (gameState.isGameOver) return;
    
    _isPaused = !_isPaused;
    if (_isPaused) {
      overlays.add('pause_menu');
      pauseEngine();
    } else {
      overlays.remove('pause_menu');
      resumeEngine();
    }
  }

  void resumeGame() {
    if (_isPaused) {
      _togglePause();
    }
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
    final ballPos = _ball.position.clone();
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
