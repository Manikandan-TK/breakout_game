import 'package:breakout_game/config/game_config.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/breakout_game.dart';
import 'game/states/game_state.dart';
import 'ui/game_over_overlay.dart';
import 'ui/loading_screen.dart';

// Helper extension to get game instance
extension GameContextX on BuildContext {
  BreakoutGame get gameRef => 
      findAncestorWidgetOfExactType<GameWidget<BreakoutGame>>()?.game as BreakoutGame;
}

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
          child: GameWidget<BreakoutGame>.controlled(
            gameFactory: () => BreakoutGame(),
            overlayBuilderMap: {
              'game_over': (BuildContext context, BreakoutGame game) => GameOverOverlay(
                    size: game.size,
                    gameState: game.gameState,
                    onRestart: game.resetGame,
                  ),
              'loading': (BuildContext context, BreakoutGame game) => ValueListenableBuilder<double>(
                valueListenable: game.loadingProgress,
                builder: (context, progress, _) {
                  return LoadingScreen(progress: progress);
                },
              ),
            },
            loadingBuilder: (BuildContext context) => const LoadingScreen(progress: 0),
            errorBuilder: (BuildContext context, Object error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            initialActiveOverlays: const ['loading'],
          ),
        ),
      ),
    );
  }
}
