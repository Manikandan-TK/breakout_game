/// Game module exports for the Breakout game.
///
/// This barrel file provides a centralized point for accessing all game-related
/// components, managers, and systems. It helps maintain clean imports throughout
/// the codebase and provides a clear overview of available game elements.
///
/// Components:
/// - Ball: The bouncing ball that breaks bricks
/// - Brick: Destructible blocks that the ball hits
/// - Paddle: Player-controlled platform to bounce the ball
/// - PowerUp: Special items that provide gameplay bonuses
///
/// Managers:
/// - BrickManager: Handles brick creation and layout
/// - ParticleManager: Controls particle effects
/// - PowerUpManager: Manages power-up spawning and behavior
///
/// Systems:
/// - SpatialGrid: Optimizes collision detection with spatial partitioning
library;

// Components
export 'components/ball.dart';
export 'components/brick.dart';
export 'components/paddle.dart';
export 'components/power_up.dart';

// Managers
export 'managers/managers.dart';

// Systems
export 'systems/spatial_grid.dart';
