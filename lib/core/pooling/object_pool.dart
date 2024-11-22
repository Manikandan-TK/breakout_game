import 'package:flame/components.dart';

class ObjectPool<T extends Component> {
  final int initialSize;
  final T Function() factory;
  final void Function(T)? resetFunction;
  final List<T> _activeObjects = [];
  final List<T> _inactiveObjects = [];

  ObjectPool({
    required this.initialSize,
    required this.factory,
    this.resetFunction,
  }) {
    _initialize();
  }

  void _initialize() {
    for (var i = 0; i < initialSize; i++) {
      _inactiveObjects.add(factory());
    }
  }

  T obtain() {
    final T object;
    if (_inactiveObjects.isEmpty) {
      object = factory();
    } else {
      object = _inactiveObjects.removeLast();
    }
    _activeObjects.add(object);
    return object;
  }

  void release(T object) {
    if (_activeObjects.remove(object)) {
      if (resetFunction != null) {
        resetFunction!(object);
      }
      _inactiveObjects.add(object);
    }
  }

  void releaseAll() {
    for (final object in _activeObjects) {
      if (resetFunction != null) {
        resetFunction!(object);
      }
      _inactiveObjects.add(object);
    }
    _activeObjects.clear();
  }

  int get activeCount => _activeObjects.length;
  int get inactiveCount => _inactiveObjects.length;
  int get totalCount => activeCount + inactiveCount;
}
