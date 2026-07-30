import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/snake/snake_game.dart';

/// The empty board the snake runs on.
///
/// The frame is drawn solid rather than faint: the walls end runs, so they
/// have to read as walls and not as the edge of a background.
class SnakeBoard extends PositionComponent with HasGameReference<SnakeGame> {
  SnakeBoard() : super(anchor: Anchor.topLeft);

  final Paint _cellPaint = Paint()..color = const Color(0x0DFFFFFF);
  final Paint _wallPaint = Paint()
    ..color = const Color(0x66FFFFFF)
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final cell = game.cellSize;
    final radius = Radius.circular(cell * 0.18);

    for (var row = 0; row < SnakeGame.rows; row++) {
      for (var column = 0; column < SnakeGame.columns; column++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              column * cell,
              row * cell,
              cell,
              cell,
            ).deflate(cell * 0.06),
            radius,
          ),
          _cellPaint,
        );
      }
    }

    _wallPaint.strokeWidth = cell * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().inflate(_wallPaint.strokeWidth / 2),
        Radius.circular(cell * 0.3),
      ),
      _wallPaint,
    );
  }
}
