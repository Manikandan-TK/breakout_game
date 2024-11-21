import 'package:flutter/material.dart';
import '../../shared/enums/game_end_state.dart';
import '../../game/components/brick.dart';

abstract class GameStateInterface {
  int get score;
  int get lives;
  bool get isGameOver;
  GameEndState get gameEndState;
  List<Brick> get bricks;
  List<Color> get brickColors;
  
  void setGameOver(bool value, {bool won = false});
  void loseLife();
  void updateScore();
  void restart();
  void addBrick(Brick brick);
  void removeBrick(Brick brick);
}
