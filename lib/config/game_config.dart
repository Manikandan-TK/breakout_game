import 'package:flutter/material.dart';
import 'package:flame/components.dart';

class GameConfig {
  // Ball configuration
  static const double initialBallSpeed = 300.0;
  static const double ballRadius = 8.0;
  static const double maxBallSpeed = 600.0;
  static const double ballSpeedIncrement = 20.0;
  static const Color ballColor = Colors.red;

  // Paddle configuration
  static const double paddleWidth = 200.0;  // Increased from 100.0
  static const double paddleHeight = 20.0;
  static const double paddleSpeed = 400.0;
  static const double paddleBottomOffset = 40.0;  // Distance from bottom of screen
  static const Color paddleColor = Colors.blue;

  // Brick configuration
  static const double brickWidth = 50.0;
  static const double brickHeight = 20.0;
  static const double brickSpacing = 4.0;
  static const int brickRows = 5;
  static const int bricksPerRow = 7;
  static const double brickTopOffset = 80.0;

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
  static const double topBarHeight = 60.0;  // Changed from gameAreaTopPadding
  
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
      Color(0xFF1A1A2E),  // Dark navy blue
      Color(0xFF16213E),  // Deeper navy
      Color(0xFF0F3460),  // Dark blue
    ],
  );

  // Vibrant color palette
  static const Color primaryColor = Color(0xFF00A8E8);       // Bright blue
  static const Color secondaryColor = Color(0xFFFF6B6B);     // Soft red
  static const Color accentColor = Color(0xFF4ECDC4);        // Teal
  static const Color backgroundColor = Color(0xFF1A1A2E);    // Dark background

  // UI Colors
  static final Color scoreColor = primaryColor.withOpacity(0.8);
  static final Color livesColor = secondaryColor.withOpacity(0.8);

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
