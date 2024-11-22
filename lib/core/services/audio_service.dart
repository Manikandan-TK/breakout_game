import 'package:flame_audio/flame_audio.dart';
import 'dart:developer' as developer;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  double _volume = 1.0;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      // Load all sound effects
      await FlameAudio.audioCache.loadAll([
        'hit.wav',
        'break.wav',
        'powerup.mp3',
        'game_over.wav',
        'background.mp3',
      ]);
      
      _isInitialized = true;
      _isMusicEnabled = true;  // Ensure music is enabled on initialization
      developer.log('Audio initialization successful');
    } catch (e) {
      developer.log('Failed to initialize audio: $e');
      _isInitialized = false;
    }
  }

  void playSound(String sound) {
    if (!_isInitialized || !_isSoundEnabled) return;
    
    try {
      FlameAudio.play(sound, volume: _volume);
    } catch (e) {
      developer.log('Failed to play sound $sound: $e');
    }
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    developer.log('Sound ${_isSoundEnabled ? 'enabled' : 'disabled'}');
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
