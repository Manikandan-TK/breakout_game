import 'package:flame_audio/flame_audio.dart';
import 'dart:developer' as developer;
import '../pooling/audio_pool.dart';
import 'audio_cache_manager.dart';

enum AudioPriority {
  low,    // Regular hits
  medium, // Power-up collection
  high    // Game over, level complete
}

class AudioInstance {
  final String soundName;
  DateTime lastPlayedTime;
  bool isPlaying;

  AudioInstance(this.soundName)
      : lastPlayedTime = DateTime(1970),
        isPlaying = false;
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  double _volume = 1.0;
  bool _isInitialized = false;
  
  final AudioCacheManager _cacheManager = AudioCacheManager();
  
  // Audio pools for different priorities
  late final AudioPool _lowPriorityPool;
  late final AudioPool _mediumPriorityPool;
  late final AudioPool _highPriorityPool;
  
  // Sound priority mappings
  final Map<String, AudioPriority> _soundPriorities = {
    'hit.wav': AudioPriority.low,
    'break.wav': AudioPriority.low,
    'powerup.mp3': AudioPriority.medium,
    'game_over.wav': AudioPriority.high,
  };
  
  static const Duration _minPlayInterval = Duration(milliseconds: 50);
  static const int _maxConcurrentSounds = 8;
  int _currentlyPlayingSounds = 0;

  Future<void> initialize() async {
    try {
      // Initialize audio cache first
      await _cacheManager.initialize();

      // Initialize audio pools
      _lowPriorityPool = AudioPool(maxSize: 10);
      _mediumPriorityPool = AudioPool(maxSize: 5);
      _highPriorityPool = AudioPool(maxSize: 3);
      
      _isInitialized = true;
      _isMusicEnabled = true;
      developer.log('Audio service initialized successfully');
    } catch (e) {
      developer.log('Failed to initialize audio service: $e');
      _isInitialized = false;
    }
  }

  AudioPool _getPoolForPriority(AudioPriority priority) {
    switch (priority) {
      case AudioPriority.low:
        return _lowPriorityPool;
      case AudioPriority.medium:
        return _mediumPriorityPool;
      case AudioPriority.high:
        return _highPriorityPool;
    }
  }

  void _cleanupOldSounds() {
    final now = DateTime.now();
    void checkAndReleasePool(AudioPool pool) {
      pool.releaseAll((instance) {
        if (instance.isPlaying && 
            now.difference(instance.lastPlayedTime) > const Duration(seconds: 2)) {
          _currentlyPlayingSounds--;
          return true;
        }
        return false;
      });
    }

    checkAndReleasePool(_lowPriorityPool);
    checkAndReleasePool(_mediumPriorityPool);
    checkAndReleasePool(_highPriorityPool);
  }

  Future<void> playSound(String sound) async {
    if (!_isInitialized || !_isSoundEnabled) return;

    final priority = _soundPriorities[sound] ?? AudioPriority.low;
    final pool = _getPoolForPriority(priority);
    
    // Clean up any completed sounds
    _cleanupOldSounds();
    
    // Check if we can play more sounds
    if (_currentlyPlayingSounds >= _maxConcurrentSounds) {
      // If at max capacity, only allow high priority sounds
      if (priority != AudioPriority.high) {
        return;
      }
      // For high priority sounds, stop a low priority sound if possible
      _lowPriorityPool.releaseAll((instance) => instance.isPlaying);
      _currentlyPlayingSounds--;
    }
    
    // Get an instance from the pool
    final instance = pool.acquire();
    if (instance == null) return;
    
    // Check debouncing
    final now = DateTime.now();
    if (now.difference(instance.lastPlayedTime) < _minPlayInterval) {
      pool.release(instance);
      return;
    }

    try {
      instance.markPlayed();
      _currentlyPlayingSounds++;
      
      // Mark the sound as used in cache
      _cacheManager.markAudioUsed(sound);
      
      // Play the sound
      await FlameAudio.play(sound, volume: _volume);
      
      // Schedule cleanup
      Future.delayed(const Duration(milliseconds: 100), () {
        instance.isPlaying = false;
        _currentlyPlayingSounds--;
        pool.release(instance);
      });
    } catch (e) {
      developer.log('Failed to play sound $sound: $e');
      instance.isPlaying = false;
      _currentlyPlayingSounds--;
      pool.release(instance);
    }
  }

  Future<void> toggleMusic() async {
    if (!_isInitialized) {
      developer.log('Cannot toggle music - audio not initialized');
      return;
    }
    
    _isMusicEnabled = !_isMusicEnabled;
    try {
      if (!_isMusicEnabled) {
        await FlameAudio.bgm.stop();
        developer.log('Background music stopped');
      } else {
        await FlameAudio.bgm.play('background.mp3', volume: _volume);
        developer.log('Playing background music');
      }
    } catch (e) {
      developer.log('Failed to toggle music: $e');
    }
  }

  Future<void> startBackgroundMusic() async {
    if (!_isInitialized) {
      developer.log('Cannot play music - audio not initialized');
      return;
    }

    try {
      _isMusicEnabled = true;
      await FlameAudio.bgm.play('background.mp3', volume: _volume);
      developer.log('Started background music');
    } catch (e) {
      developer.log('Failed to start background music: $e');
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    if (_isMusicEnabled && _isInitialized) {
      FlameAudio.bgm.audioPlayer.setVolume(_volume);
    }
  }
}
