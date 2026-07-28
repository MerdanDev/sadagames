import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// One numbered tile on the board.
class MergeTile extends PositionComponent {
  MergeTile({
    required this.slot,
    required super.position,
    required double side,
    required int value,
  }) : super(size: Vector2.all(side), anchor: Anchor.topLeft) {
    _value = value;
  }

  static const _palette = <int, Color>{
    2: Color(0xFF4CC9F0),
    4: Color(0xFF4895EF),
    8: Color(0xFF4361EE),
    16: Color(0xFF3F37C9),
    32: Color(0xFF7209B7),
    64: Color(0xFF9B5DE5),
    128: Color(0xFFB5179E),
    256: Color(0xFFE63946),
    512: Color(0xFFF3722C),
    1024: Color(0xFFF8961E),
    2048: Color(0xFFFFD166),
  };

  late int _value;

  /// Board slot the tile occupies, counted left to right and top to bottom.
  int slot;

  int get value => _value;

  late final TextComponent _label = TextComponent(
    text: '$_value',
    anchor: Anchor.center,
    position: size / 2,
    textRenderer: _rendererFor(_value),
  );

  Color get _colour => _palette[_value] ?? const Color(0xFFFFE29A);

  TextPaint _rendererFor(int value) {
    // Longer numbers have to shrink or they run past the tile edge.
    final digits = '$value'.length;
    return TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: size.x * (digits > 3 ? 0.26 : 0.36),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await add(_label);
  }

  /// Doubles the tile and pops it, so a merge is visible.
  void promoteTo(int newValue) {
    _value = newValue;
    _label
      ..text = '$newValue'
      ..textRenderer = _rendererFor(newValue);
    final pop = add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(1.18), EffectController(duration: 0.08)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.1)),
      ]),
    );
    if (pop is Future<void>) unawaited(pop);
  }

  /// Grows the tile in from nothing, for one that has just appeared.
  void appear() {
    scale.setValues(0.3, 0.3);
    final grow = add(
      ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.12)),
    );
    if (grow is Future<void>) unawaited(grow);
  }

  /// Resizes the tile when the board is laid out again.
  void resize(double side) {
    size = Vector2.all(side);
    _label
      ..position = size / 2
      ..textRenderer = _rendererFor(_value);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect().deflate(size.x * 0.045),
        Radius.circular(size.x * 0.14),
      ),
      Paint()..color = _colour,
    );
  }
}
