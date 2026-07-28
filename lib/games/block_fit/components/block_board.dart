import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/block_fit/block_fit_game.dart';

/// The playing grid.
///
/// It draws nothing of its own state: the filled cells live on the game, and
/// the board renders whatever is there, plus a preview of the piece being
/// dragged so the player can see where it would land.
class BlockBoard extends PositionComponent with HasGameReference<BlockFitGame> {
  BlockBoard() : super(anchor: Anchor.topLeft);

  final Paint _emptyPaint = Paint()..color = const Color(0x1AFFFFFF);

  @override
  void render(Canvas canvas) {
    final cell = game.cellSize;
    final radius = Radius.circular(cell * 0.18);

    for (var row = 0; row < BlockFitGame.gridSize; row++) {
      for (var column = 0; column < BlockFitGame.gridSize; column++) {
        final filled = game.cellAt(column, row);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(column * cell, row * cell, cell, cell).deflate(
            cell * 0.06,
          ),
          radius,
        );
        canvas.drawRRect(
          rect,
          filled == null ? _emptyPaint : (Paint()..color = filled),
        );
      }
    }

    _renderPreview(canvas, cell, radius);
  }

  void _renderPreview(Canvas canvas, double cell, Radius radius) {
    final preview = game.preview;
    if (preview == null) return;

    final (shape, column, row) = preview;
    final paint = Paint()..color = shape.colour.withValues(alpha: 0.45);

    for (final (offsetColumn, offsetRow) in shape.cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (column + offsetColumn) * cell,
            (row + offsetRow) * cell,
            cell,
            cell,
          ).deflate(cell * 0.06),
          radius,
        ),
        paint,
      );
    }
  }
}
