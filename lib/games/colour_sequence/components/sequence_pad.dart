import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/colour_sequence/colour_sequence_game.dart';

/// One of the four pads the sequence is played on.
///
/// A pad lights up both when the game plays the sequence back and when the
/// player presses it, so watching and answering look the same.
class SequencePad extends PositionComponent
    with TapCallbacks, HasGameReference<ColourSequenceGame> {
  SequencePad({
    required this.index,
    required this.colour,
    required super.position,
    required double side,
  }) : super(size: Vector2.all(side));

  /// Pad number, counted left to right and top to bottom.
  final int index;

  final Color colour;

  late final Color _litColour = HSLColor.fromColor(colour)
      .withLightness(
        (HSLColor.fromColor(colour).lightness + 0.28).clamp(0.0, 1.0),
      )
      .toColor();

  /// How much longer the pad stays lit. Set it to light the pad up.
  double litSeconds = 0;

  /// Whether the pad is currently lit.
  bool get isLit => litSeconds > 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (litSeconds > 0) litSeconds -= dt;
  }

  @override
  void onTapDown(TapDownEvent event) => game.pressPad(index);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(size.x * 0.05),
        Radius.circular(size.x * 0.16),
      ),
      Paint()..color = isLit ? _litColour : colour,
    );
  }
}
