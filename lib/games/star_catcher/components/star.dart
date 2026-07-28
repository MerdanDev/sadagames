import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A star that falls from the top of the screen towards the basket.
class Star extends PositionComponent {
  Star({required super.position, required this.speed})
    : super(size: Vector2.all(28), anchor: Anchor.center);

  /// Falling speed in logical pixels per second.
  final double speed;

  late final Path _path = _buildPath();

  final Paint _paint = Paint()..color = const Color(0xFFFFD166);

  Path _buildPath() {
    const points = 5;
    final center = size / 2;
    final outerRadius = size.x / 2;
    final innerRadius = outerRadius / 2.4;
    final path = Path();

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      // Start at the top of the star instead of the right hand side.
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(
        center.x + radius * cos(angle),
        center.y + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    angle += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_path, _paint);
  }
}
