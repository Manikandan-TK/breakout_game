import 'package:flame/components.dart';
import 'package:breakout_game/game/states/game_state.dart';

mixin GameStateAwareMixin on Component {
  late final GameState gameState;
}
