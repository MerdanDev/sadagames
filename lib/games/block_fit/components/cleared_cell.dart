import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A cell that has just been cleared, animating itself away.
///
/// This is decoration only. The board is emptied the moment a line completes,
/// so gameplay never waits for the animation, and one of these can linger over
/// a cell that has already been filled again without affecting anything.
class ClearedCell extends PositionComponent with HasPaint {
  ClearedCell({
    required Color colour,
    required this.delay,
    required super.position,
    required double side,
  }) : super(size: Vector2.all(side), anchor: Anchor.center) {
    paint.color = colour;
  }

  /// Head start before this cell pops, so a line sweeps rather than blinking.
  final double delay;

  static const _popDuration = 0.1;
  static const _shrinkDuration = 0.2;

  @override
  Future<void> onLoad() async {
    await addAll([
      SequenceEffect([
        // A quick swell first, so the clear reads as a pop rather than a fade.
        ScaleEffect.to(
          Vector2.all(1.25),
          EffectController(duration: _popDuration, startDelay: delay),
        ),
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: _shrinkDuration, curve: Curves.easeIn),
        ),
      ]),
      OpacityEffect.fadeOut(
        EffectController(
          duration: _popDuration + _shrinkDuration,
          startDelay: delay,
        ),
      ),
      RemoveEffect(delay: delay + _popDuration + _shrinkDuration + 0.02),
    ]);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(size.x * 0.06),
        Radius.circular(size.x * 0.18),
      ),
      paint,
    );
  }
}
