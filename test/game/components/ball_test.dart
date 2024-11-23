import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:breakout_game/game/components/ball.dart';
import 'package:breakout_game/game/states/game_state.dart';
import 'dart:math' as math;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Basic Ball Tests', () {
    late Ball ball;
    late GameState gameState;
    final screenSize = Vector2(800, 600);

    setUp(() {
      gameState = GameState();
      ball = Ball(
        screenSize: screenSize,
        gameState: gameState,
      );
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Ball should initialize with zero velocity', () {
      expect(ball.velocity.x, equals(0));
      expect(ball.velocity.y, equals(0));
      expect(ball.isActive, isFalse);
    });

    test('Ball should activate on launch', () {
      ball.launch();
      expect(ball.isActive, isTrue);
      expect(ball.velocity.length, greaterThan(0));
    });

    test('Ball velocity direction should be upward on launch', () {
      ball.launch();
      expect(ball.velocity.y, lessThan(0), reason: 'Ball should move upward (negative y) on launch');
    });
  });

  group('Ball Velocity Tests', () {
    late Ball ball;
    late GameState gameState;
    final screenSize = Vector2(800, 600);

    setUp(() {
      gameState = GameState();
      ball = Ball(
        screenSize: screenSize,
        gameState: gameState,
      );
      ball.launch(); // Start with an active ball
    });

    tearDown(() {
      gameState.dispose();
    });

    test('Ball velocity should maintain approximate direction after update', () {
      // Set a specific velocity at 45 degrees upward
      const angle = -math.pi / 4; // 45 degrees upward
      const speed = 300.0;
      ball.velocity = Vector2(
        speed * math.cos(angle),
        speed * math.sin(angle)
      );
      
      // Position ball in center of screen to avoid wall collisions
      ball.position = Vector2(screenSize.x / 2, screenSize.y / 2);
      
      // Print initial state
      
      // Update ball
      ball.update(0.016);
      
      // Print state after update
      
      // Calculate angle change
      const originalAngle = -math.pi / 4;
      final newAngle = math.atan2(ball.velocity.y, ball.velocity.x);
      final angleDifference = (newAngle - originalAngle).abs();
      
      
      // Angles should be approximately equal (within 5 degrees)
      const maxDifference = 5 * math.pi / 180; // 5 degrees in radians
      expect(
        angleDifference,
        lessThanOrEqualTo(maxDifference),
        reason: 'Ball direction should not change significantly after update'
      );
    });

    test('Ball velocity should never be zero', () {
      // Try to set zero velocity
      ball.velocity = Vector2.zero();
      ball.update(0.016);
      
      expect(ball.velocity.length, greaterThan(0), reason: 'Ball velocity should never be zero');
    });
  });
}
