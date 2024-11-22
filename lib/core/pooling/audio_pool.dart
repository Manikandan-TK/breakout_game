import 'dart:collection';

/// A simple pool for managing audio instances
class AudioPool {
  final int maxSize;
  final Queue<AudioInstance> _available = Queue();
  final Set<AudioInstance> _inUse = {};
  
  AudioPool({required this.maxSize});

  /// Get an available instance or create a new one if possible
  AudioInstance? acquire() {
    if (_available.isEmpty && _inUse.length >= maxSize) {
      return null;
    }

    final instance = _available.isEmpty 
        ? AudioInstance() 
        : _available.removeFirst();
    
    _inUse.add(instance);
    return instance;
  }

  /// Return an instance to the pool
  void release(AudioInstance instance) {
    if (_inUse.remove(instance)) {
      instance.reset();
      _available.add(instance);
    }
  }

  /// Release all instances that match the predicate
  void releaseAll(bool Function(AudioInstance) predicate) {
    final toRelease = _inUse.where(predicate).toList();
    for (final instance in toRelease) {
      release(instance);
    }
  }

  /// Get the number of instances currently in use
  int get inUseCount => _inUse.length;

  /// Clear the pool
  void clear() {
    _available.clear();
    _inUse.clear();
  }
}

/// Represents an audio instance that can be pooled
class AudioInstance {
  DateTime lastPlayedTime = DateTime(1970);
  bool isPlaying = false;

  void reset() {
    isPlaying = false;
  }

  void markPlayed() {
    lastPlayedTime = DateTime.now();
    isPlaying = true;
  }
}
