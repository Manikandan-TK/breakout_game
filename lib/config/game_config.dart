import 'package:flutter/material.dart';
import 'package:flame/components.dart';

class GameConfig {
  // Ball configuration
  static const double initialBallSpeed = 300.0;
  static const double ballRadius = 8.0;
  static const double maxBallSpeed = 600.0;
  static const double ballSpeedIncrement = 20.0;
  static const double ballPaddleOffset = 25.0;  // Distance between ball and paddle when reset
  static const Color ballColor = Colors.red;

  // Paddle configuration
  static const double paddleWidth = 100.0;  
  static const double paddleHeight = 15.0;
  static const double paddleSpeed = 400.0;
  static const double paddleBottomOffset = 40.0;  
  static const Color paddleColor = Colors.blue;

  // Brick configuration
  static const double brickWidth = 50.0;
  static const double brickHeight = 20.0;
  static const double brickSpacing = 4.0;
  static const int brickRows = 4;  
  static const int bricksPerRow = 7;
  static const double brickTopOffset = 120.0;  

  // Game settings
  static const int initialLives = 3;
  static const int pointsPerBrick = 10;
  static const double particleLifespan = 0.8;
  
  // Power-up settings
  static const double powerUpChance = 0.2;
  static const double powerUpDuration = 10.0;

  // UI settings
  static const double uiPadding = 16.0;
  static const double uiFontSize = 20.0;
  static const double uiSpacing = 10.0;
  static const double topBarHeight = 60.0;  
  
  // Physics settings
  static const double minBounceAngle = 0.2;
  static const double maxBounceAngle = 1.0;
  static const double paddleBounceDampening = 0.8;

  // Game area dimensions
  static Vector2 defaultGameSize(Vector2 screenSize) {
    return Vector2(screenSize.x, screenSize.y - topBarHeight);
  }

  // Background aesthetics
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),  
      Color(0xFF16213E),  
      Color(0xFF0F3460),  
    ],
  );

  // Vibrant color palette
  static const Color backgroundColor = Color(0xFF2C3E50);
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color secondaryColor = Color(0xFFE74C3C);
  static const Color accentColor = Color(0xFF4ECDC4);       
  static const Color scoreColor = Color(0xFF2ECC71);
  static const Color livesColor = Color(0xFFE74C3C);
  static const Color powerUpColor = Color(0xFFE67E22);  

  // UI Text Styles
  static final TextStyle titleStyle = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 2,
    shadows: [
      Shadow(
        blurRadius: 10.0,
        color: primaryColor.withOpacity(0.5),
        offset: const Offset(0, 0),
      ),
    ],
  );

  static const TextStyle uiTextStyle = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: uiFontSize,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 24,
    color: accentColor,
  );

  // Heart and Score Styling
  static const String heartIcon = '❤️';
  static const String emptyHeartIcon = '💔';
}
