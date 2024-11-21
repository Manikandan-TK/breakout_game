import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/brick.dart';
import '../states/game_state.dart';
import 'power_up_manager.dart';
import '../../config/game_config.dart';

class BrickManager extends Component {
  final GameState gameState;
  final PowerUpManager powerUpManager;
  late final FlameGame game;

  BrickManager({
    required this.gameState,
    required this.powerUpManager,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game = findGame()!;
  }

  Future<void> createBricks(Vector2 screenSize) async {
    const brickWidth = GameConfig.brickWidth;
    const brickHeight = GameConfig.brickHeight;
    const rows = GameConfig.brickRows;
    const cols = GameConfig.bricksPerRow;
    const spacing = GameConfig.brickSpacing;
    const topOffset = GameConfig.brickTopOffset;

    // Calculate total width of all bricks and spacing
    const totalWidth = (cols * brickWidth) + ((cols - 1) * spacing);
    final startX = (screenSize.x - totalWidth) / 2; // Center horizontally

    // Define colors for each row
    final rowColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
    ];

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final brick = Brick(
          position: Vector2(
            startX + (j * (brickWidth + spacing)),
            topOffset + (i * (brickHeight + spacing))
          ),
          size: Vector2(brickWidth, brickHeight),
          color: rowColors[i % rowColors.length],
          powerUpManager: powerUpManager,
        );
        gameState.bricks.add(brick);
        await game.add(brick);
      }
    }
  }

  void resetBricks(Vector2 screenSize) {
    for (var brick in gameState.bricks) {
      brick.removeFromParent();
    }
    gameState.bricks.clear();
    createBricks(screenSize);
  }
}
