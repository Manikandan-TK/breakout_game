import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breakout_game/game/breakout_game.dart';
import 'package:breakout_game/game/states/game_state.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Breakout game initial state test', (WidgetTester tester) async {
    final gameState = GameState();
    final game = BreakoutGame();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: gameState,
          child: GameWidget(game: game),
        ),
      ),
    );


    // Wait for a short time to allow the game to initialize
    await tester.pump(const Duration(seconds: 2));

    // Verify the initial game state
    expect(gameState.score, equals(0));
    
    expect(gameState.isGameOver, isFalse);

    // Find the GameWidget
    final gameWidgetFinder = find.byType(GameWidget);
    expect(gameWidgetFinder, findsOneWidget);

    // Check if the score text is present
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
