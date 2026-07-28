import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/tile_tap/tile_tap_game.dart';

/// One scrolling row, with a single dark tile the player has to hit.
class TileRow extends PositionComponent {
  TileRow({
    required this.column,
    required super.position,
    required super.size,
  }) : super(anchor: Anchor.topLeft);

  /// Which column holds the tile to tap.
  final int column;

  /// Whether the player has already dealt with this row.
  bool isTapped = false;

  static const _pending = Color(0xFF1B2050);
  static const _hit = Color(0xFF06D6A0);
  static const _line = Color(0x0DFFFFFF);

  @override
  void render(Canvas canvas) {
    final columnWidth = width / TileTapGame.columns;

    canvas
      // A hairline under each row, so the board reads as a track rather than
      // a wall of colour.
      ..drawRect(
        Rect.fromLTWH(0, height - 1, width, 1),
        Paint()..color = _line,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            column * columnWidth,
            0,
            columnWidth,
            height,
          ).deflate(3),
          const Radius.circular(8),
        ),
        Paint()..color = isTapped ? _hit : _pending,
      );
  }
}
