import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sadagames/games/star_catcher/components/falling_collectible.dart';

/// A bonus pickup that gives the player a life back when caught.
///
/// It pulses gently so it stands out from the much more common stars.
class Heart extends FallingCollectible {
  Heart({required super.position, required super.speed, super.diameter = 34});

  late final Path _path = buildHeartPath(size.x, size.y);

  final Paint _paint = Paint()..color = const Color(0xFFE63946);

  double _elapsed = 0;

  /// Builds a heart shape that fills a [width] by [height] box.
  static Path buildHeartPath(double width, double height) {
    return Path()
      ..moveTo(width / 2, height)
      ..cubicTo(
        -width * 0.25,
        height * 0.55,
        width * 0.2,
        -height * 0.15,
        width / 2,
        height * 0.28,
      )
      ..cubicTo(
        width * 0.8,
        -height * 0.15,
        width * 1.25,
        height * 0.55,
        width / 2,
        height,
      )
      ..close();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    scale.setValues(
      1 + sin(_elapsed * 6) * 0.08,
      1 + sin(_elapsed * 6) * 0.08,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_path, _paint);
  }
}
