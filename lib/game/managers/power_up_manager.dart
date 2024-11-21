import 'dart:math';
import 'package:flame/components.dart';
import '../components/power_up.dart';
import '../components/brick.dart';
import '../../config/game_config.dart';
import '../states/game_state.dart';

class PowerUpManager extends Component {
  final Vector2 screenSize;
  final GameState gameState;
  final Random _random = Random();
  
  PowerUpManager({
    required this.screenSize,
    required this.gameState,
  });

  void trySpawnPowerUp(Vector2 position, Brick brick) {
    if (_random.nextDouble() < GameConfig.powerUpChance) {
      final powerUpType = _getRandomPowerUpType();
      final powerUp = PowerUp(
        type: powerUpType,
        screenSize: screenSize,
        position: position,
      );
      add(powerUp);
    }
  }

  PowerUpType _getRandomPowerUpType() {
    const values = PowerUpType.values;
    return values[_random.nextInt(values.length)];
  }

  void reset() {
    removeAll(children);
  }
}
