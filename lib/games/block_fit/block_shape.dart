import 'dart:math';

import 'package:flutter/material.dart';

/// A piece the player drops onto the board, described by the cells it fills.
///
/// Cells are `(column, row)` offsets from the shape's top left corner.
class BlockShape {
  const BlockShape({required this.cells, required this.colour});

  final List<(int, int)> cells;

  final Color colour;

  /// Cells the shape occupies.
  int get size => cells.length;

  int get width => cells.map((cell) => cell.$1).reduce(max) + 1;

  int get height => cells.map((cell) => cell.$2).reduce(max) + 1;
}

const _blue = Color(0xFF2A48DF);
const _purple = Color(0xFF9B5DE5);
const _green = Color(0xFF06D6A0);
const _yellow = Color(0xFFFFD166);
const _red = Color(0xFFE63946);
const _cyan = Color(0xFF4CC9F0);

/// Shapes that are easy to place, used heavily early on.
const smallShapes = <BlockShape>[
  BlockShape(cells: [(0, 0)], colour: _cyan),
  BlockShape(cells: [(0, 0), (1, 0)], colour: _green),
  BlockShape(cells: [(0, 0), (0, 1)], colour: _green),
  BlockShape(cells: [(0, 0), (1, 0), (2, 0)], colour: _blue),
  BlockShape(cells: [(0, 0), (0, 1), (0, 2)], colour: _blue),
  BlockShape(cells: [(0, 0), (1, 0), (0, 1), (1, 1)], colour: _yellow),
  BlockShape(cells: [(0, 0), (0, 1), (1, 1)], colour: _purple),
  BlockShape(cells: [(0, 0), (1, 0), (0, 1)], colour: _purple),
  BlockShape(cells: [(0, 0), (1, 0), (1, 1)], colour: _purple),
  BlockShape(cells: [(1, 0), (0, 1), (1, 1)], colour: _purple),
];

/// Shapes that are awkward to fit, which show up more as the score climbs.
const bigShapes = <BlockShape>[
  BlockShape(cells: [(0, 0), (1, 0), (2, 0), (3, 0)], colour: _red),
  BlockShape(cells: [(0, 0), (0, 1), (0, 2), (0, 3)], colour: _red),
  BlockShape(cells: [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)], colour: _red),
  BlockShape(cells: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)], colour: _red),
  BlockShape(cells: [(0, 0), (1, 0), (2, 0), (1, 1)], colour: _cyan),
  BlockShape(cells: [(1, 0), (2, 0), (0, 1), (1, 1)], colour: _cyan),
  BlockShape(cells: [(0, 0), (1, 0), (1, 1), (2, 1)], colour: _cyan),
  BlockShape(
    cells: [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)],
    colour: _yellow,
  ),
  BlockShape(
    cells: [(0, 0), (1, 0), (2, 0), (0, 1), (0, 2)],
    colour: _yellow,
  ),
  BlockShape(
    cells: [
      (0, 0),
      (1, 0),
      (2, 0),
      (0, 1),
      (1, 1),
      (2, 1),
      (0, 2),
      (1, 2),
      (2, 2),
    ],
    colour: _purple,
  ),
];
