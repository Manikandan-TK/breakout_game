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
  AudioService? _audioService;
  bool _isPaused = false;
  final loadingProgress = ValueNotifier<double>(0);

  // Getters for game components
  Paddle get paddle => _paddle;
  Ball get ball => _ball;
  AudioService get audioService => _audioService!;

  @override
  Color backgroundColor() => const Color(0xFFF5F5DC);

  @override
  Future<void> onLoad() async {
    try {
      double progress = 0.0;
      void updateProgress(double value) {
        progress = value;
        loadingProgress.value = progress;
      }

      updateProgress(0.1);
      // Initialize services
      if (_audioService == null) {
        _audioService = AudioService();
        await _audioService!.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            developer.log('Audio initialization timed out');
            return;
          },
        );
      }
      
      updateProgress(0.3);
      // Start background music
      await audioService.startBackgroundMusic();
      
      updateProgress(0.4);
      // Initialize game state
      gameState = GameState();
      
      updateProgress(0.5);
      // Wait for super.onLoad() to complete before proceeding
      await super.onLoad();

      updateProgress(0.6);
      // Initialize game size based on screen size
      final screenSize = Vector2(size.x, size.y);
      final gameSize = GameConfig.defaultGameSize(screenSize);

      updateProgress(0.7);
      // Initialize UI and managers
      uiManager = GameUIManager(gameState: gameState);
      await add(uiManager);

      _powerUpManager = PowerUpManager(
        screenSize: gameSize,
        gameState: gameState,
      );
      _brickManager = BrickManager(
        gameState: gameState,
        powerUpManager: _powerUpManager,
      );
      particleManager = ParticleManager();

      updateProgress(0.8);
      // Initialize components
      _paddle = Paddle(
        screenSize: gameSize,
        gameState: gameState,
        color: GameConfig.paddleColor,
      );
      _ball = Ball(screenSize: gameSize, gameState: gameState);

      updateProgress(0.9);
      // Add game components
      await add(_powerUpManager);
      await add(_paddle);
      await add(_ball);
      await add(_brickManager);
      await add(particleManager);

      updateProgress(1.0);
      // Initialize bricks
      await _brickManager.createBricks(size);
      
      // Initialize game state listener
      gameState.addListener(_handleGameStateChange);

      // Add a small delay to ensure loading screen is visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Remove loading overlay when everything is ready
      overlays.remove('loading');
      
    } catch (e, stackTrace) {
      developer.log(
        'Error during game initialization',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
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
    
    // Reset UI
    uiManager.reset();
    
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

  void spawnExtraBall() {
    final newBall = Ball(screenSize: size, gameState: gameState);
    // Position the new ball slightly above the paddle
    newBall.position = Vector2(
      _paddle.position.x,
      _paddle.position.y - _paddle.size.y * 3
    );
    
    // Set initial velocity (upward and slightly to the right)
    newBall.velocity = Vector2(150, -300);
    
    add(newBall);
  }

  void addExtraLife() {
    gameState.addLife();
  }

  @override
  void removeBrick(Brick brick) {
    gameState.removeBrick(brick);
  }
}
