import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../core/pooling/object_pool.dart';

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
            radius: randomSize,
            paint: Paint()..color = color.withOpacity(0.8),
          ),
          lifespan: lifespan,
        ),
      );
    });
  }
}

// Concrete implementation of sparkle effect
class SparkleEffect implements ParticleEffect {
  final int particleCount;
  final double lifespan;

  SparkleEffect({
    this.particleCount = 5,
    this.lifespan = 0.5,
  });

  @override
  List<Component> generateParticles(Vector2 position, Color color) {
    return List.generate(particleCount, (index) {
      return ParticleSystemComponent(
        particle: ComputedParticle(
          renderer: (canvas, particle) {
            final paint = Paint()
              ..color = color.withOpacity((1 - particle.progress) * 0.8);
            canvas.drawCircle(
              Offset.zero,
              2 * (1 - particle.progress),
              paint,
            );
          },
          lifespan: lifespan,
        ),
      );
    });
  }
}

// Manager class that handles particle effects
class ParticleManager extends Component with HasGameRef {
  late final ObjectPool<ParticleSystemComponent> _particlePool;
  final Map<String, ParticleEffect> _effects = {};
  
  @override
  Future<void> onLoad() async {
    _particlePool = ObjectPool<ParticleSystemComponent>(
      initialSize: 50,
      factory: () => ParticleSystemComponent(),
      resetFunction: (component) {
        component.removeFromParent();
      },
    );
    
    // Register default effects
    registerEffect('explosion', ExplosionEffect());
    registerEffect('sparkle', SparkleEffect());
  }

  void registerEffect(String name, ParticleEffect effect) {
    _effects[name] = effect;
  }

  void createEffect(String effectName, Vector2 position, Color color) {
    final effect = _effects[effectName];
    if (effect != null) {
      final particles = effect.generateParticles(position, color);
      for (final particle in particles) {
        if (particle is ParticleSystemComponent) {
          final pooledParticle = _particlePool.obtain()
            ..particle = particle.particle;
          
          // Add a timer component to handle cleanup
          final timer = TimerComponent(
            period: particle.particle?.lifespan ?? 1.0,
            repeat: false,
            removeOnFinish: true,
            onTick: () {
              _particlePool.release(pooledParticle);
            },
          );
          
          pooledParticle.add(timer);
          gameRef.add(pooledParticle);
        }
      }
    }
  }

  void createExplosion(Vector2 position, Color color) {
    createEffect('explosion', position, color);
  }

  void createSparkle(Vector2 position, Color color) {
    createEffect('sparkle', position, color);
  }
}
