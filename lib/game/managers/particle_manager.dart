import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

// Interface for particle effects
abstract class ParticleEffect {
  List<Component> generateParticles(Vector2 position, Color color);
}

// Concrete implementation of explosion effect
class ExplosionEffect implements ParticleEffect {
  static const defaultParticleCount = 10;
  static const defaultMinSpeed = 50.0;
  static const defaultMaxSpeed = 150.0;
  static const defaultMinSize = 2.0;
  static const defaultMaxSize = 6.0;
  static const defaultLifespan = 1.0;
  static final defaultGravity = Vector2(0, 200);

  final int particleCount;
  final double minSpeed;
  final double maxSpeed;
  final double minSize;
  final double maxSize;
  final double lifespan;
  final Vector2 gravity;

  ExplosionEffect({
    this.particleCount = defaultParticleCount,
    this.minSpeed = defaultMinSpeed,
    this.maxSpeed = defaultMaxSpeed,
    this.minSize = defaultMinSize,
    this.maxSize = defaultMaxSize,
    this.lifespan = defaultLifespan,
    Vector2? gravity,
  }) : gravity = gravity ?? defaultGravity;

  @override
  List<Component> generateParticles(Vector2 position, Color color) {
    final random = Random();
    return List.generate(particleCount, (index) {
      final randomAngle = random.nextDouble() * 2 * pi;
      final randomSpeed = random.nextDouble() * (maxSpeed - minSpeed) + minSpeed;
      final randomSize = random.nextDouble() * (maxSize - minSize) + minSize;
      
      return ParticleSystemComponent(
        particle: AcceleratedParticle(
          position: position.clone(),
          speed: Vector2(cos(randomAngle), sin(randomAngle)) * randomSpeed,
          acceleration: gravity,
          child: CircleParticle(
            paint: Paint()..color = color.withOpacity(0.8),
            radius: randomSize,
          ),
          lifespan: lifespan,
        ),
      );
    });
  }
}

// Manager class that handles particle effects
class ParticleManager extends Component {
  final Map<String, ParticleEffect> _effects = {};
  late final FlameGame game;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game = findGame()!;
    registerEffect('explosion', ExplosionEffect());
  }

  void registerEffect(String name, ParticleEffect effect) {
    _effects[name] = effect;
  }

  void createExplosion(Vector2 position, Color color) {
    final effect = _effects['explosion'];
    if (effect != null) {
      final particles = effect.generateParticles(position, color);
      particles.forEach(game.add);
    }
  }
}
