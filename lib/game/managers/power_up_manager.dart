import 'dart:math';
import 'package:flame/components.dart';
import '../components/power_up.dart';
import '../components/brick.dart';
import '../../config/game_config.dart';
import '../states/game_state.dart';
import '../../ui/game_ui_manager.dart';
import '../breakout_game.dart';

class PowerUpManager extends Component with HasGameRef<BreakoutGame> {
  final Vector2 screenSize;
  final GameState gameState;
  final Random _random = Random();
  PowerUpDisplay? _powerUpDisplay;
  
  PowerUpManager({
    required this.screenSize,
    required this.gameState,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final uiManager = gameRef.uiManager;
    _powerUpDisplay = uiManager.powerUpDisplay;
  }

  void trySpawnPowerUp(Vector2 position, Brick brick) {
    if (_random.nextDouble() < GameConfig.powerUpChance) {
      final powerUpType = _getRandomPowerUpType();
      final powerUp = PowerUp(
        type: powerUpType,
        screenSize: screenSize,
        position: position,
        onCollect: _onPowerUpCollected,
      );
      add(powerUp);
    }
  }

  void _onPowerUpCollected(PowerUpType type) {
    _powerUpDisplay?.addPowerUp(type, GameConfig.powerUpDuration);
  }

  PowerUpType _getRandomPowerUpType() {
    const values = PowerUpType.values;
    return values[_random.nextInt(values.length)];
  }

  void reset() {
    removeAll(children);
  }
}
