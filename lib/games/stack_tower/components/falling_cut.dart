import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// The overhang sliced off a badly aimed block, tumbling away.
///
/// Decoration only: the tower has already been trimmed by the time one of
/// these appears, so it can never affect where the next block lands.
class FallingCut extends PositionComponent with HasPaint {
  FallingCut({
    required Color colour,
    required this.towardsLeft,
    required super.position,
    required super.size,
  }) : super(anchor: Anchor.topLeft) {
    paint.color = colour;
  }

  /// Which way the slice spins as it drops.
  final bool towardsLeft;

  static const _fallDuration = 0.55;

  @override
  Future<void> onLoad() async {
    await addAll([
      MoveByEffect(
        Vector2(towardsLeft ? -40 : 40, 420),
        EffectController(duration: _fallDuration, curve: Curves.easeIn),
      ),
      RotateEffect.by(
        towardsLeft ? -0.6 : 0.6,
        EffectController(duration: _fallDuration),
      ),
      OpacityEffect.fadeOut(EffectController(duration: _fallDuration)),
      RemoveEffect(delay: _fallDuration + 0.02),
    ]);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(1),
        Radius.circular(height * 0.22),
      ),
      paint,
    );
  }
}
