import 'package:breakout_game/config/game_config.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/breakout_game.dart';
import 'game/states/game_state.dart';
import 'ui/game_over_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Orbitron',
          colorScheme: ColorScheme.fromSeed(
            seedColor: GameConfig.primaryColor,
            brightness: Brightness.dark,
            primary: GameConfig.primaryColor,
            secondary: GameConfig.secondaryColor,
            surface: GameConfig.backgroundColor,
          ),
          textTheme: TextTheme(
            displayLarge: GameConfig.titleStyle,
            displayMedium: GameConfig.subtitleStyle,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: GameConfig.primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: const GameScreen(),
      ),
    ),
  );
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BREAKOUT',
          style: GameConfig.titleStyle.copyWith(
            fontSize: 32,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        backgroundColor: GameConfig.backgroundColor.withOpacity(0.9),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameConfig.backgroundGradient,
        ),
        child: SafeArea(
          child: GameWidget<BreakoutGame>(
            game: BreakoutGame(),
            overlayBuilderMap: {
              'game_over': (context, game) => GameOverOverlay(
                    size: game.size,
                    gameState: game.gameState,
                    onRestart: game.resetGame,
                  ),
            },
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorBuilder: (context, error) => Center(
              child: Text('Error: $error'),
            ),
            initialActiveOverlays: const [],
          ),
        ),
      ),
    );
  }
}
