import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/components/brick.dart';

abstract class GameInterface {
  void addExplosion(Vector2 position, Color color);
  void removeBrick(Brick brick);
}
