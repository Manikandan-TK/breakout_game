import 'package:flame_audio/flame_audio.dart';
import 'dart:developer' as developer;

/// Represents pre-processed audio data
class PreprocessedAudio {
  final String path;
  final int size;
  DateTime lastUsed;
  int useCount;

  PreprocessedAudio({
    required this.path,
    required this.size,
    DateTime? lastUsed,
  })  : lastUsed = lastUsed ?? DateTime.now(),
        useCount = 0;

  void markUsed() {
    lastUsed = DateTime.now();
    useCount++;
  }
}

/// Manages pre-processed audio data caching for better performance
class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();

  // Cache to store pre-processed audio data
  final Map<String, PreprocessedAudio> _audioCache = {};
  bool _isInitialized = false;

  // Maximum size for the audio cache (in bytes)
  static const int _maxCacheSize = 10 * 1024 * 1024; // 10MB
  int _currentCacheSize = 0;

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Pre-process and cache frequently used sounds
      await _preprocessAudio('hit.wav', priority: true);
      await _preprocessAudio('break.wav', priority: true);
      await _preprocessAudio('powerup.mp3', priority: true);
      await _preprocessAudio('game_over.wav');
      
      _isInitialized = true;
      developer.log('Audio cache initialized successfully');
    } catch (e) {
      developer.log('Failed to initialize audio cache: $e');
      _isInitialized = false;
    }
  }

  /// Pre-process and cache audio data
  Future<void> _preprocessAudio(String soundPath, {bool priority = false}) async {
    try {
      // Check if we need to make space in the cache
      if (!priority && _currentCacheSize >= _maxCacheSize) {
        _cleanCache();
      }

      // Estimate size (this is a rough estimate as actual processed data size may vary)
      final estimatedSize = await _estimateAudioSize(soundPath);
      
      if (!priority && _currentCacheSize + estimatedSize > _maxCacheSize) {
        developer.log('Cache full, skipping non-priority audio: $soundPath');
        return;
      }

      // Pre-load the audio using Flame's cache
      await FlameAudio.audioCache.load(soundPath);
      
      // Store in our cache
      _audioCache[soundPath] = PreprocessedAudio(
        path: soundPath,
        size: estimatedSize,
      );
      _currentCacheSize += estimatedSize;

      developer.log('Cached audio: $soundPath (${estimatedSize ~/ 1024}KB)');
    } catch (e) {
      developer.log('Failed to preprocess audio $soundPath: $e');
    }
  }

  /// Clean up least recently used non-priority audio
  void _cleanCache() {
    if (_audioCache.isEmpty) return;

    // Sort by last used time and use count
    final sortedEntries = _audioCache.entries.toList()
      ..sort((a, b) {
        // Priority files are kept
        if (_isPriorityAudio(a.key) != _isPriorityAudio(b.key)) {
          return _isPriorityAudio(a.key) ? 1 : -1;
        }
        // Then sort by use count and last used time
        if (a.value.useCount != b.value.useCount) {
          return a.value.useCount.compareTo(b.value.useCount);
        }
        return a.value.lastUsed.compareTo(b.value.lastUsed);
      });

    // Remove least used entries until we're under the size limit
    for (var entry in sortedEntries) {
      if (_currentCacheSize < (_maxCacheSize * 0.8).toInt() || _isPriorityAudio(entry.key)) {
        break;
      }
      _currentCacheSize -= entry.value.size;
      _audioCache.remove(entry.key);
      developer.log('Removed from cache: ${entry.key}');
    }
  }

  /// Check if audio is cached and ready
  bool isAudioCached(String soundPath) {
    return _audioCache.containsKey(soundPath);
  }

  /// Mark audio as used for cache management
  void markAudioUsed(String soundPath) {
    final audio = _audioCache[soundPath];
    if (audio != null) {
      audio.markUsed();
    }
  }

  /// Estimate audio file size
  Future<int> _estimateAudioSize(String soundPath) async {
    // In a real implementation, you might want to actually check the file size
    // For now, we'll use reasonable estimates based on file type
    if (soundPath.endsWith('.mp3')) {
      return 100 * 1024; // Estimate 100KB for MP3s
    } else if (soundPath.endsWith('.wav')) {
      return 50 * 1024; // Estimate 50KB for WAVs
    }
    return 75 * 1024; // Default estimate
  }

  /// Check if audio is priority
  bool _isPriorityAudio(String soundPath) {
    return soundPath == 'hit.wav' || 
           soundPath == 'break.wav' || 
           soundPath == 'powerup.mp3';
  }

  /// Clear the entire cache
  void clearCache() {
    _audioCache.clear();
    _currentCacheSize = 0;
    developer.log('Audio cache cleared');
  }
}
