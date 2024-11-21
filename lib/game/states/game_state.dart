import 'package:flutter/material.dart';
import '../../core/interfaces/game_state_interface.dart';
import '../../shared/enums/game_end_state.dart';
import '../components/brick.dart';

class GameState extends ChangeNotifier implements GameStateInterface {
  // Score-related state
  int _score = 0;
  int _lives = 3;
  static const int maxLives = 5;
  
  // Game lifecycle state
  GameEndState _gameEndState = GameEndState.playing;
  bool _isGameOver = false;
  
  // Brick management state
  final List<Brick> _bricks = [];
  final List<Color> _brickColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD93D),
    const Color(0xFF6E44FF),
    const Color(0xFF6E44FF),
    const Color(0xFFF9844A),
  ];

  // ScoreInterface implementation
  @override
  int get score => _score;
  
  @override
  int get lives => _lives;
  
  @override
  void updateScore() {
    if (_gameEndState == GameEndState.playing) {
      _score += 10;
      notifyListeners();
    }
  }
  
  @override
  void loseLife() {
    if (_gameEndState == GameEndState.playing) {
      _lives--;
      if (_lives <= 0) {
        setGameOver(true);
      }
      notifyListeners();
    }
  }

  // Additional life management
  void addLife() {
    if (_gameEndState == GameEndState.playing && _lives < maxLives) {
      _lives++;
      notifyListeners();
    }
  }

  // GameLifecycleInterface implementation
  @override
  bool get isGameOver => _isGameOver;
  
  @override
  GameEndState get gameEndState => _gameEndState;
  
  @override
  void setGameOver(bool value, {bool won = false}) {
    _isGameOver = value;
    if (value) {
      _gameEndState = won ? GameEndState.won : GameEndState.lost;
    } else {
      _gameEndState = GameEndState.playing;
    }
    notifyListeners();
  }
  
  @override
  void restart() {
    _score = 0;
    _lives = 3;
    _isGameOver = false;
    _gameEndState = GameEndState.playing;
    _bricks.clear();
    notifyListeners();
  }

  // BrickManagerInterface implementation
  @override
  List<Brick> get bricks => _bricks;
  
  @override
  List<Color> get brickColors => List.unmodifiable(_brickColors);
  
  @override
  void addBrick(Brick brick) {
    if (_gameEndState == GameEndState.playing) {
      _bricks.add(brick);
      notifyListeners();
    }
  }
  
  @override
  void removeBrick(Brick brick) {
    if (_gameEndState == GameEndState.playing && _bricks.remove(brick)) {
      updateScore();
      if (_bricks.isEmpty) {
        setGameOver(true, won: true);
      }
      notifyListeners();
    }
  }
}
