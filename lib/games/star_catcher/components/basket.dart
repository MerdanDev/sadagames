import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The player controlled basket that catches falling stars.
class Basket extends PositionComponent {
  Basket({required super.position})
    : super(size: Vector2(96, 24), anchor: Anchor.center);

  final Paint _bodyPaint = Paint()..color = const Color(0xFF2A48DF);
  final Paint _rimPaint = Paint()..color = const Color(0xFF8FA4FF);

  /// Moves the basket to [x], keeping it fully inside a screen of [maxWidth].
  void moveTo(double x, double maxWidth) {
    final halfWidth = size.x / 2;
    position.x = x.clamp(halfWidth, maxWidth - halfWidth);
  }

  @override
  void render(Canvas canvas) {
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10)),
        _bodyPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, 7),
          const Radius.circular(4),
        ),
        _rimPaint,
      );
  }
}
