import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SpatialCell {
  final Set<PositionComponent> objects = {};
  final Rect bounds;

  SpatialCell(this.bounds);
}

class SpatialGrid {
  final List<List<SpatialCell>> grid;
  final int rows;
  final int columns;
  final double cellWidth;
  final double cellHeight;
  final Rect worldBounds;

  SpatialGrid({
    required this.rows,
    required this.columns,
    required this.worldBounds,
  }) : grid = List.generate(
         rows,
         (y) => List.generate(
           columns,
           (x) => SpatialCell(
             Rect.fromLTWH(
               worldBounds.left + (worldBounds.width / columns) * x,
               worldBounds.top + (worldBounds.height / rows) * y,
               worldBounds.width / columns,
               worldBounds.height / rows,
             ),
           ),
         ),
       ),
       cellWidth = worldBounds.width / columns,
       cellHeight = worldBounds.height / rows;

  void clear() {
    for (var row in grid) {
      for (var cell in row) {
        cell.objects.clear();
      }
    }
  }

  List<(int, int)> _getCellCoordinates(Rect bounds) {
    final startX = ((bounds.left - worldBounds.left) / cellWidth).floor().clamp(0, columns - 1);
    final startY = ((bounds.top - worldBounds.top) / cellHeight).floor().clamp(0, rows - 1);
    final endX = ((bounds.right - worldBounds.left) / cellWidth).ceil().clamp(0, columns - 1);
    final endY = ((bounds.bottom - worldBounds.top) / cellHeight).ceil().clamp(0, rows - 1);

    final coordinates = <(int, int)>[];
    for (var y = startY; y <= endY; y++) {
      for (var x = startX; x <= endX; x++) {
        coordinates.add((x, y));
      }
    }
    return coordinates;
  }

  void insertObject(PositionComponent object) {
    final bounds = object.toRect();
    final cells = _getCellCoordinates(bounds);
    
    for (final (x, y) in cells) {
      grid[y][x].objects.add(object);
    }
  }

  Set<PositionComponent> queryArea(Rect bounds) {
    final result = <PositionComponent>{};
    final cells = _getCellCoordinates(bounds);
    
    for (final (x, y) in cells) {
      result.addAll(grid[y][x].objects);
    }
    return result;
  }
}
