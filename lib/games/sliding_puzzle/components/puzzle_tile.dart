import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/sliding_puzzle/sliding_puzzle_game.dart';

/// A single numbered tile on the puzzle board.
class PuzzleTile extends PositionComponent
    with TapCallbacks, HasGameReference<SlidingPuzzleGame> {
  PuzzleTile({
    required this.value,
    required super.position,
    required double side,
  }) : super(size: Vector2.all(side));

  /// The number printed on the tile, starting at 1.
  final int value;

  late final TextComponent _label;

  /// Tiles fade from blue to purple so the solved order reads as a gradient.
  Paint get _paint => Paint()
    ..color = Color.lerp(
      const Color(0xFF2A48DF),
      const Color(0xFF9B5DE5),
      (value - 1) / (SlidingPuzzleGame.tileCount - 1),
    )!;

  @override
  Future<void> onLoad() async {
    _label = TextComponent(
      text: '$value',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: size.x * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    await add(_label);
  }

  /// Resizes the tile and keeps the label centred, used on screen rotation.
  void resize(double side) {
    size.setValues(side, side);
    _label
      ..position = size / 2
      ..textRenderer = TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: side * 0.38,
          fontWeight: FontWeight.w700,
        ),
      );
  }

  @override
  void onTapDown(TapDownEvent event) => game.tryMoveValue(value);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(size.x * 0.04),
        Radius.circular(size.x * 0.16),
      ),
      _paint,
    );
  }
}
