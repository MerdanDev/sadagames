import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/snake/snake_game.dart';

/// The snake itself, drawn from the cells the game holds.
///
/// Head and tail are drawn part way between cells so the snake glides instead
/// of jumping a whole cell every tick; the segments between them are already
/// touching, so the chain reads as continuous.
class SnakeBodyComponent extends PositionComponent
    with HasGameReference<SnakeGame> {
  SnakeBodyComponent() : super(anchor: Anchor.topLeft);

  static const _head = Color(0xFF9BF6C8);
  static const _tail = Color(0xFF118AB2);

  final Paint _paint = Paint();
  final Paint _eyePaint = Paint()..color = const Color(0xFF10143A);

  @override
  void render(Canvas canvas) {
    final body = game.body;
    if (body.isEmpty) return;

    final cell = game.cellSize;
    final progress = game.tickProgress;
    // A snake waiting for its first swipe sits squarely on its cells. Sliding
    // the head out of the cell behind it would draw the snake a segment
    // shorter than the HUD says it is.
    final isSliding = game.isMoving;

    for (var i = body.length - 1; i >= 0; i--) {
      var centre = _centreOf(body[i], cell);
      if (isSliding) {
        if (i == 0 && body.length > 1) {
          // Still sliding out of the cell behind, into the one it now owns.
          centre = _lerp(_centreOf(body[1], cell), centre, progress);
        } else if (i == body.length - 1 &&
            body.length > 2 &&
            !game.grewLastStep) {
          // And the tail is on its way out of its own cell, unless this tick
          // is the one that grew the snake and left it where it was.
          centre = _lerp(centre, _centreOf(body[i - 1], cell), progress);
        }
      }

      _paint.color = Color.lerp(_head, _tail, i / (body.length + 3)) ?? _head;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: centre,
            width: cell,
            height: cell,
          ).deflate(cell * 0.08),
          Radius.circular(cell * 0.3),
        ),
        _paint,
      );

      if (i == 0) _drawEyes(canvas, centre, cell);
    }
  }

  /// Two eyes looking the way the snake is going, so the head is never in
  /// doubt even when the snake doubles back beside itself.
  void _drawEyes(Canvas canvas, Offset centre, double cell) {
    final direction = game.direction;
    final ahead = Offset(
      direction.dx * cell * 0.16,
      direction.dy * cell * 0.16,
    );
    // Across the direction of travel, so the eyes sit either side of the nose.
    final across = Offset(
      -direction.dy * cell * 0.18,
      direction.dx * cell * 0.18,
    );

    canvas
      ..drawCircle(centre + ahead + across, cell * 0.09, _eyePaint)
      ..drawCircle(centre + ahead - across, cell * 0.09, _eyePaint);
  }

  Offset _centreOf(int cell, double side) => Offset(
    (cell % SnakeGame.columns + 0.5) * side,
    (cell ~/ SnakeGame.columns + 0.5) * side,
  );

  Offset _lerp(Offset from, Offset to, double t) =>
      Offset.lerp(from, to, t) ?? to;
}
