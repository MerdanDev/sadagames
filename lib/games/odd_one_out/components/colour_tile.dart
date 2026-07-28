import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/odd_one_out/odd_one_out_game.dart';

/// One square of the board.
///
/// Every tile on a level shares a colour except the odd one, which is a shade
/// lighter. The gap between the two shrinks as the player climbs.
class ColourTile extends PositionComponent
    with TapCallbacks, HasGameReference<OddOneOutGame> {
  ColourTile({
    required this.index,
    required this.colour,
    required super.position,
    required double side,
  }) : super(size: Vector2.all(side));

  /// Slot on the board, counted left to right and top to bottom.
  final int index;

  final Color colour;

  late final Paint _paint = Paint()..color = colour;

  @override
  void onTapDown(TapDownEvent event) => game.chooseTile(index);

  /// Shakes the tile to answer a wrong tap.
  void rejectTap() {
    final effect = add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(0.88), EffectController(duration: 0.06)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.12)),
      ]),
    );
    if (effect is Future<void>) unawaited(effect);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(size.x * 0.05),
        Radius.circular(size.x * 0.18),
      ),
      _paint,
    );
  }
}
