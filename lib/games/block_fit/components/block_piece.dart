import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/block_fit/block_shape.dart';

/// A piece sitting in the tray, or being dragged towards the board.
///
/// It is drawn small while waiting in the tray and at full board scale once
/// picked up, so what the player drags matches what will land.
class BlockPiece extends PositionComponent {
  BlockPiece({
    required this.shape,
    required this.slot,
    required double cellSize,
    super.position,
  }) : super(anchor: Anchor.topLeft) {
    // Through the setter, so the component sizes itself to the shape.
    this.cellSize = cellSize;
  }

  final BlockShape shape;

  /// Tray slot this piece came from. Shapes repeat, so the slot identifies a
  /// piece, not its shape.
  final int slot;

  double _cellSize = 0;

  /// Side of one cell in logical pixels.
  double get cellSize => _cellSize;

  set cellSize(double value) {
    _cellSize = value;
    size = Vector2(shape.width * value, shape.height * value);
  }

  /// Where the piece rests when it is not being dragged.
  Vector2 traySlot = Vector2.zero();

  /// Sends the piece back to its slot at tray scale.
  void returnToTray(double trayCellSize) {
    cellSize = trayCellSize;
    position = traySlot.clone();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = shape.colour;
    final radius = Radius.circular(_cellSize * 0.18);

    for (final (column, row) in shape.cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            column * _cellSize,
            row * _cellSize,
            _cellSize,
            _cellSize,
          ).deflate(_cellSize * 0.06),
          radius,
        ),
        paint,
      );
    }
  }
}
