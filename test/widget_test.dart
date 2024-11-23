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
    bool loadingComplete = false;

    game.onLoad().then((_) {
      loadingComplete = true;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: gameState,
            child: GameWidget<BreakoutGame>(
              game: game,
              loadingBuilder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );

    // Wait for the game to initialize
    await tester.pump();
    while (!loadingComplete) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Verify the initial game state
    expect(gameState.score, equals(0));
    expect(gameState.isGameOver, isFalse);

    // Find the GameWidget
    final gameWidgetFinder = find.byType(GameWidget<BreakoutGame>);
    expect(gameWidgetFinder, findsOneWidget);
  });
}
