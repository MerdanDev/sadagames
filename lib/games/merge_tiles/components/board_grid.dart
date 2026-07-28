import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/merge_tiles/merge_tiles_game.dart';

/// The empty board behind the tiles.
///
/// Without it the tiles float in space and there is no way to see where a
/// slide will end up, so it is drawn faintly under everything else.
class BoardGrid extends PositionComponent
    with HasGameReference<MergeTilesGame> {
  BoardGrid() : super(anchor: Anchor.topLeft);

  final Paint _paint = Paint()..color = const Color(0x14FFFFFF);

  @override
  void render(Canvas canvas) {
    final cell = game.cellSize;
    final radius = Radius.circular(cell * 0.14);

    for (var row = 0; row < MergeTilesGame.gridSize; row++) {
      for (var column = 0; column < MergeTilesGame.gridSize; column++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              column * cell,
              row * cell,
              cell,
              cell,
            ).deflate(cell * 0.045),
            radius,
          ),
          _paint,
        );
      }
    }
  }
}
