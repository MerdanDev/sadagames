import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/block_fit/block_fit.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
BlockFitGame _buildGameWith(GameRecords records) {
  return BlockFitGame(sounds: createTestSounds(), records: records)
    ..overlays.addEntry(
      BlockFitGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

const _dot = BlockShape(cells: [(0, 0)], colour: Color(0xFF4CC9F0));

/// Fills every cell of [row] except [gap].
void _fillRowExcept(BlockFitGame game, int row, int gap) {
  for (var column = 0; column < BlockFitGame.gridSize; column++) {
    if (column == gap) continue;
    game.cells[row * BlockFitGame.gridSize + column] = const Color(0xFF123456);
  }
}

/// Leaves the board with no empty cell at all.
void _fillBoard(BlockFitGame game) {
  game.cells.fillRange(0, game.cells.length, const Color(0xFF123456));
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${BlockFitGame.recordGameId}.${BlockFitGame.recordMetric}': 500,
    });
  });

  BlockFitGame buildGame() => _buildGameWith(records);

  group('BlockFitGame', () {
    testWithGame<BlockFitGame>('starts empty with a full tray', buildGame, (
      game,
    ) async {
      expect(game.score, equals(0));
      expect(game.isGameOver, isFalse);
      expect(game.cells.every((cell) => cell == null), isTrue);
      expect(
        game.tray.whereType<BlockShape>(),
        hasLength(BlockFitGame.trySize),
      );
    });

    testWithGame<BlockFitGame>('lays a piece out per tray slot', buildGame, (
      game,
    ) async {
      expect(
        game.children.query<BlockPiece>(),
        hasLength(BlockFitGame.trySize),
      );
    });

    testWithGame<BlockFitGame>('fills the cells a piece covers', buildGame, (
      game,
    ) async {
      game.tray[0] = _dot;

      expect(game.placeFromTray(0, 3, 4), isTrue);

      expect(game.cellAt(3, 4), equals(_dot.colour));
      expect(game.tray[0], isNull);
    });

    testWithGame<BlockFitGame>('scores a point per cell placed', buildGame, (
      game,
    ) async {
      const shape = BlockShape(
        cells: [(0, 0), (1, 0), (2, 0)],
        colour: Color(0xFF4CC9F0),
      );
      game.tray[0] = shape;

      game.placeFromTray(0, 0, 0);

      expect(game.score, equals(3));
    });

    testWithGame<BlockFitGame>('refuses to place off the board', buildGame, (
      game,
    ) async {
      game.tray[0] = _dot;

      expect(game.placeFromTray(0, BlockFitGame.gridSize, 0), isFalse);
      expect(game.tray[0], equals(_dot));
    });

    testWithGame<BlockFitGame>(
      'refuses to place over a filled cell',
      buildGame,
      (game) async {
        game.tray[0] = _dot;
        game.placeFromTray(0, 2, 2);
        game.tray[1] = _dot;

        expect(game.placeFromTray(1, 2, 2), isFalse);
      },
    );

    testWithGame<BlockFitGame>(
      'refuses to place from an empty slot',
      buildGame,
      (game) async {
        game.tray[0] = null;

        expect(game.placeFromTray(0, 0, 0), isFalse);
      },
    );
  });

  group('clearing lines', () {
    testWithGame<BlockFitGame>('clears a full row', buildGame, (game) async {
      _fillRowExcept(game, 3, 7);
      game.tray[0] = _dot;

      game.placeFromTray(0, 7, 3);

      for (var column = 0; column < BlockFitGame.gridSize; column++) {
        expect(game.cellAt(column, 3), isNull);
      }
    });

    testWithGame<BlockFitGame>('clears a full column', buildGame, (game) async {
      for (var row = 0; row < BlockFitGame.gridSize - 1; row++) {
        game.cells[row * BlockFitGame.gridSize + 2] = const Color(0xFF123456);
      }
      game.tray[0] = _dot;

      game.placeFromTray(0, 2, BlockFitGame.gridSize - 1);

      for (var row = 0; row < BlockFitGame.gridSize; row++) {
        expect(game.cellAt(2, row), isNull);
      }
    });

    testWithGame<BlockFitGame>(
      'rewards a clear on top of the cells',
      buildGame,
      (game) async {
        _fillRowExcept(game, 0, 5);
        game.tray[0] = _dot;

        game.placeFromTray(0, 5, 0);

        // One cell placed, plus a single line worth one squared times the grid.
        expect(game.score, equals(1 + BlockFitGame.gridSize));
      },
    );

    testWithGame<BlockFitGame>(
      'rewards clearing two lines at once far more than one',
      buildGame,
      (game) async {
        _fillRowExcept(game, 0, 4);
        _fillRowExcept(game, 1, 4);
        const domino = BlockShape(
          cells: [(0, 0), (0, 1)],
          colour: Color(0xFF4CC9F0),
        );
        game.tray[0] = domino;

        game.placeFromTray(0, 4, 0);

        // Two cells placed, plus two squared times the grid.
        expect(game.score, equals(2 + 4 * BlockFitGame.gridSize));
      },
    );

    testWithGame<BlockFitGame>(
      'counts a row and a column that cross each other',
      buildGame,
      (game) async {
        _fillRowExcept(game, 0, 0);
        for (var row = 1; row < BlockFitGame.gridSize; row++) {
          game.cells[row * BlockFitGame.gridSize] = const Color(0xFF123456);
        }
        game.tray[0] = _dot;

        game.placeFromTray(0, 0, 0);

        expect(game.score, equals(1 + 4 * BlockFitGame.gridSize));
        expect(game.cells.every((cell) => cell == null), isTrue);
      },
    );
  });

  group('clear animation', () {
    testWithGame<BlockFitGame>(
      'spawns a fading cell per cleared square',
      buildGame,
      (game) async {
        _fillRowExcept(game, 3, 7);
        game.tray[0] = _dot;

        game.placeFromTray(0, 7, 3);
        await game.ready();

        expect(
          game.board.children.query<ClearedCell>(),
          hasLength(BlockFitGame.gridSize),
        );
      },
    );

    testWithGame<BlockFitGame>(
      'animates a square shared by a row and a column only once',
      buildGame,
      (game) async {
        _fillRowExcept(game, 0, 0);
        for (var row = 1; row < BlockFitGame.gridSize; row++) {
          game.cells[row * BlockFitGame.gridSize] = const Color(0xFF123456);
        }
        game.tray[0] = _dot;

        game.placeFromTray(0, 0, 0);
        await game.ready();

        // Both lines share the corner, so it is one short of two full lines.
        expect(
          game.board.children.query<ClearedCell>(),
          hasLength(BlockFitGame.gridSize * 2 - 1),
        );
      },
    );

    testWithGame<BlockFitGame>(
      'empties the board immediately, without waiting for the animation',
      buildGame,
      (game) async {
        _fillRowExcept(game, 3, 7);
        game.tray[0] = _dot;

        game.placeFromTray(0, 7, 3);

        for (var column = 0; column < BlockFitGame.gridSize; column++) {
          expect(game.cellAt(column, 3), isNull);
        }
      },
    );

    testWithGame<BlockFitGame>(
      'lets a cleared square be filled again while it is still fading',
      buildGame,
      (game) async {
        _fillRowExcept(game, 3, 7);
        game.tray[0] = _dot;
        game.placeFromTray(0, 7, 3);
        await game.ready();
        expect(game.board.children.query<ClearedCell>(), isNotEmpty);

        game.tray[1] = _dot;

        expect(game.placeFromTray(1, 0, 3), isTrue);
      },
    );

    testWithGame<BlockFitGame>('tidies the cells away when done', buildGame, (
      game,
    ) async {
      _fillRowExcept(game, 3, 7);
      game.tray[0] = _dot;
      game.placeFromTray(0, 7, 3);
      await game.ready();

      // Long enough for the last cell's stagger plus its pop and shrink.
      for (var i = 0; i < 60; i++) {
        game.update(0.02);
      }
      await game.ready();

      expect(game.board.children.query<ClearedCell>(), isEmpty);
    });
  });

  group('running out of room', () {
    testWithGame<BlockFitGame>('reports when nothing fits', buildGame, (
      game,
    ) async {
      _fillBoard(game);

      expect(game.hasAnyMove, isFalse);
    });

    testWithGame<BlockFitGame>('reports while a piece still fits', buildGame, (
      game,
    ) async {
      expect(game.hasAnyMove, isTrue);
    });

    testWithGame<BlockFitGame>(
      'ends the run when the tray refills with nothing playable',
      buildGame,
      (game) async {
        _fillBoard(game);
        game.tray[0] = _dot;
        // The board is full, so this placement fails and the run is stuck.
        expect(game.placeFromTray(0, 0, 0), isFalse);

        game.restart();
        _fillBoard(game);
        await game.ready();

        expect(game.hasAnyMove, isFalse);
      },
    );
  });

  group('swaps', () {
    testWithGame<BlockFitGame>('start empty and cannot be spent', buildGame, (
      game,
    ) async {
      expect(game.swaps, equals(0));
      expect(game.swapTray(), isFalse);
    });

    testWithGame<BlockFitGame>('are earned by clearing lines', buildGame, (
      game,
    ) async {
      for (var row = 0; row < BlockFitGame.linesPerSwap; row++) {
        _fillRowExcept(game, row, 0);
        game.tray[0] = _dot;
        game.placeFromTray(0, 0, row);
      }

      expect(game.swaps, equals(1));
    });

    testWithGame<BlockFitGame>('replace the tray when spent', buildGame, (
      game,
    ) async {
      for (var row = 0; row < BlockFitGame.linesPerSwap; row++) {
        _fillRowExcept(game, row, 0);
        game.tray[0] = _dot;
        game.placeFromTray(0, 0, row);
      }
      expect(game.swaps, equals(1));

      expect(game.swapTray(), isTrue);
      await game.ready();

      expect(game.swaps, equals(0));
      expect(
        game.tray.whereType<BlockShape>(),
        hasLength(BlockFitGame.trySize),
      );
    });
  });

  group('records', () {
    testWithGame<BlockFitGame>(
      'load the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestScore, equals(500));
      },
    );
  });

  group('restart', () {
    testWithGame<BlockFitGame>('clears the board and the score', buildGame, (
      game,
    ) async {
      game.tray[0] = _dot;
      game.placeFromTray(0, 1, 1);
      expect(game.score, greaterThan(0));

      game.restart();
      await game.ready();

      expect(game.score, equals(0));
      expect(game.swaps, equals(0));
      expect(game.isGameOver, isFalse);
      expect(game.cells.every((cell) => cell == null), isTrue);
      expect(
        game.tray.whereType<BlockShape>(),
        hasLength(BlockFitGame.trySize),
      );
    });
  });
}
