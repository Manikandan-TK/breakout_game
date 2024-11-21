import '../../shared/enums/game_end_state.dart';

abstract class GameLifecycleInterface {
  bool get isGameOver;
  GameEndState get gameEndState;
  
  void setGameOver(bool value, {bool won = false});
  void restart();
}
