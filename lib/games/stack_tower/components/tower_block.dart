import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// One slab of the tower, either sliding across or already stacked.
class TowerBlock extends PositionComponent {
  TowerBlock({
    required this.colour,
    required super.position,
    required super.size,
  }) : super(anchor: Anchor.topLeft);

  final Color colour;

  late final Paint _paint = Paint()..color = colour;

  /// Left edge in the tower's own coordinates.
  double get left => position.x;

  double get right => position.x + width;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(1),
        Radius.circular(height * 0.22),
      ),
      _paint,
    );
  }
}
