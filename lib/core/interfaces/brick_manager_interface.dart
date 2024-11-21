import 'package:flutter/material.dart';
import '../../game/components/brick.dart';

abstract class BrickManagerInterface {
  List<Brick> get bricks;
  List<Color> get brickColors;
  
  void addBrick(Brick brick);
  void removeBrick(Brick brick);
}
