import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// The thing on the board worth eating.
///
/// An apple is a circle and a trim is a diamond: the two never differ by
/// colour alone, so the gold one still reads as different at a glance.
class Fruit extends PositionComponent {
  Fruit() : super(anchor: Anchor.center);

  static const _appleColour = Color(0xFFE63946);
  static const _trimColour = Color(0xFFFFD166);

  /// Whether this is the gold fruit that hands segments back.
  bool isTrim = false;

  final Paint _paint = Paint();

  /// Moves the fruit to [centre] and sizes it to a [cell].
  void placeAt(Vector2 centre, double cell) {
    position = centre;
    size = Vector2.all(cell * 0.74);
  }

  /// Pops the fruit in, so a new one is never just suddenly there.
  void appear() {
    scale.setValues(0.2, 0.2);
    final grow = add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(1.15), EffectController(duration: 0.1)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.08)),
      ]),
    );
    if (grow is Future<void>) unawaited(grow);
  }

  @override
  void render(Canvas canvas) {
    _paint.color = isTrim ? _trimColour : _appleColour;
    final half = size.x / 2;

    if (!isTrim) {
      canvas.drawCircle(Offset(half, half), half, _paint);
      return;
    }

    canvas.drawPath(
      Path()
        ..moveTo(half, 0)
        ..lineTo(size.x, half)
        ..lineTo(half, size.y)
        ..lineTo(0, half)
        ..close(),
      _paint,
    );
  }
}
