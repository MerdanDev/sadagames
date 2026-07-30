import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/merge_tiles/merge_tiles.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// Spawns a two in the lowest empty slot every time, so a board can be driven
/// into a genuine dead end.
class _FixedRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) => 0;
}

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
MergeTilesGame _buildGameWith(
  GameRecords records, {
  Random? random,
  GameProgress? progress,
}) {
  return MergeTilesGame(
      sounds: createTestSounds(),
      records: records,
      random: random,
      progress: progress,
    )
    ..overlays.addEntry(
      MergeTilesGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// The values of one row, top row first.
List<int> _row(MergeTilesGame game, int row) => game.values.sublist(
  row * MergeTilesGame.gridSize,
  (row + 1) * MergeTilesGame.gridSize,
);

/// A board with everything empty except the values given for the top row.
List<int> _topRow(List<int> values) => [...values, ...List.filled(12, 0)];

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${MergeTilesGame.recordGameId}.${MergeTilesGame.recordMetric}':
          9000,
    });
  });

  MergeTilesGame buildGame() => _buildGameWith(records);

  group('MergeTilesGame', () {
    testWithGame<MergeTilesGame>('starts with two tiles', buildGame, (
      game,
    ) async {
      expect(game.values.where((value) => value > 0), hasLength(2));
      expect(game.score, equals(0));
      expect(game.isGameOver, isFalse);
    });

    testWithGame<MergeTilesGame>('only spawns twos and fours', buildGame, (
      game,
    ) async {
      for (final value in game.values.where((value) => value > 0)) {
        expect(value, anyOf(equals(2), equals(4)));
      }
    });

    testWithGame<MergeTilesGame>('starts with one undo in hand', buildGame, (
      game,
    ) async {
      expect(game.undosLeft, equals(MergeTilesGame.startingUndos));
    });

    testWithGame<MergeTilesGame>('draws the empty board', buildGame, (
      game,
    ) async {
      expect(game.children.query<BoardGrid>(), hasLength(1));
    });

    testWithGame<MergeTilesGame>('keeps the board under the tiles', buildGame, (
      game,
    ) async {
      final tile = game.board.firstWhere((tile) => tile != null)!;

      expect(game.grid.priority, lessThan(tile.priority));
    });
  });

  group('sliding', () {
    testWithGame<MergeTilesGame>('packs tiles against the edge', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([0, 2, 0, 4]));

      expect(game.move(SwipeDirection.left), isTrue);

      expect(_row(game, 0).take(2), equals([2, 4]));
    });

    testWithGame<MergeTilesGame>('packs the other way too', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([2, 0, 4, 0]));

      game.move(SwipeDirection.right);

      expect(_row(game, 0).skip(2), equals([2, 4]));
    });

    testWithGame<MergeTilesGame>('slides down a column', buildGame, (
      game,
    ) async {
      await game.setBoard([2, 0, 0, 0, ...List.filled(12, 0)]);

      game.move(SwipeDirection.down);

      expect(game.values[12], equals(2));
    });

    testWithGame<MergeTilesGame>(
      'reports no move when nothing would shift',
      buildGame,
      (game) async {
        await game.setBoard(_topRow([2, 4, 2, 4]));

        expect(game.move(SwipeDirection.left), isFalse);
      },
    );

    testWithGame<MergeTilesGame>(
      'adds a tile only when the board changed',
      buildGame,
      (game) async {
        await game.setBoard(_topRow([2, 4, 2, 4]));
        final before = game.values.where((value) => value > 0).length;

        game.move(SwipeDirection.left);
        await game.ready();

        expect(game.values.where((value) => value > 0), hasLength(before));
      },
    );
  });

  group('merging', () {
    testWithGame<MergeTilesGame>('joins two equal tiles', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([2, 2, 0, 0]));

      game.move(SwipeDirection.left);

      expect(_row(game, 0).first, equals(4));
    });

    testWithGame<MergeTilesGame>('scores the merged value', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([8, 8, 0, 0]));

      game.move(SwipeDirection.left);

      expect(game.score, equals(16));
    });

    testWithGame<MergeTilesGame>(
      'merges a tile only once per swipe',
      buildGame,
      (game) async {
        await game.setBoard(_topRow([2, 2, 4, 0]));

        game.move(SwipeDirection.left);

        // The four must not immediately swallow the freshly merged four.
        expect(_row(game, 0).take(2), equals([4, 4]));
      },
    );

    testWithGame<MergeTilesGame>('merges both pairs in a row', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([2, 2, 4, 4]));

      game.move(SwipeDirection.left);

      expect(_row(game, 0).take(2), equals([4, 8]));
      expect(game.score, equals(12));
    });

    testWithGame<MergeTilesGame>(
      'merges the pair nearest the swipe first',
      buildGame,
      (game) async {
        await game.setBoard(_topRow([4, 4, 4, 0]));

        game.move(SwipeDirection.left);

        expect(_row(game, 0).take(2), equals([8, 4]));
      },
    );

    testWithGame<MergeTilesGame>('tracks the biggest tile made', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([16, 16, 0, 0]));

      game.move(SwipeDirection.left);

      expect(game.highestTile, equals(32));
    });
  });

  group('running out of moves', () {
    testWithGame<MergeTilesGame>(
      'still has a move while a pair touches',
      buildGame,
      (game) async {
        await game.setBoard([
          2, 2, 4, 8, //
          16, 32, 64, 128, //
          256, 512, 1024, 2048, //
          4, 8, 16, 32,
        ]);

        expect(game.hasAnyMove, isTrue);
      },
    );

    testWithGame<MergeTilesGame>(
      'has no move on a full board of neighbours that differ',
      buildGame,
      (game) async {
        await game.setBoard([
          2, 4, 2, 4, //
          4, 2, 4, 2, //
          2, 4, 2, 4, //
          4, 2, 4, 2,
        ]);

        expect(game.hasAnyMove, isFalse);
      },
    );

    testWithGame<MergeTilesGame>(
      'ignores swipes once over',
      () => _buildGameWith(records, random: _FixedRandom()),
      (game) async {
        await game.setBoard([
          2, 4, 2, 4, //
          4, 2, 4, 2, //
          2, 4, 2, 4, //
          2, 2, 2, 4,
        ]);
        game.move(SwipeDirection.left);
        await game.ready();
        expect(game.isGameOver, isTrue);

        expect(game.move(SwipeDirection.left), isFalse);
      },
    );
  });

  group('undo', () {
    testWithGame<MergeTilesGame>('puts the board back', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([2, 2, 0, 0]));
      final before = game.values;
      game.move(SwipeDirection.left);
      await game.ready();

      expect(game.undo(), isTrue);
      await game.ready();

      expect(game.values, equals(before));
    });

    testWithGame<MergeTilesGame>('puts the score back', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([8, 8, 0, 0]));
      game.move(SwipeDirection.left);
      await game.ready();
      expect(game.score, equals(16));

      game.undo();

      expect(game.score, equals(0));
    });

    testWithGame<MergeTilesGame>('costs one of the undos held', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([2, 2, 0, 0]));
      game.move(SwipeDirection.left);
      await game.ready();

      game.undo();

      expect(game.undosLeft, equals(MergeTilesGame.startingUndos - 1));
    });

    testWithGame<MergeTilesGame>('cannot be used twice in a row', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([2, 2, 0, 0]));
      game.move(SwipeDirection.left);
      await game.ready();
      game.undo();

      expect(game.undo(), isFalse);
    });

    testWithGame<MergeTilesGame>('is not available before a move', buildGame, (
      game,
    ) async {
      expect(game.undo(), isFalse);
    });

    testWithGame<MergeTilesGame>(
      'is earned again by making a new biggest tile',
      buildGame,
      (game) async {
        await game.setBoard(_topRow([32, 32, 0, 0]));

        game.move(SwipeDirection.left);
        await game.ready();

        expect(game.undosLeft, equals(MergeTilesGame.startingUndos + 1));
      },
    );

    testWithGame<MergeTilesGame>(
      'brings a lost run back',
      () => _buildGameWith(records, random: _FixedRandom()),
      (game) async {
        await game.setBoard([
          2, 4, 2, 4, //
          4, 2, 4, 2, //
          2, 4, 2, 4, //
          2, 2, 2, 4,
        ]);
        game.move(SwipeDirection.left);
        await game.ready();
        expect(game.isGameOver, isTrue);

        expect(game.undo(), isTrue);

        expect(game.isGameOver, isFalse);
        expect(
          game.overlays.isActive(MergeTilesGame.gameOverOverlayId),
          isFalse,
        );
      },
    );
  });

  group('records', () {
    testWithGame<MergeTilesGame>(
      'load the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestScore, equals(9000));
      },
    );

    testWithGame<MergeTilesGame>(
      'store the score when the run ends',
      () => _buildGameWith(records, random: _FixedRandom()),
      (game) async {
        await game.setBoard([
          2, 4, 2, 4, //
          4, 2, 4, 2, //
          2, 4, 2, 4, //
          2, 2, 2, 4,
        ]);
        game.move(SwipeDirection.left);
        await game.ready();

        expect(
          records.read(
            MergeTilesGame.recordGameId,
            MergeTilesGame.recordMetric,
          ),
          equals(game.score),
        );
        expect(game.isNewRecord, isTrue);
      },
    );
  });

  group('restart', () {
    testWithGame<MergeTilesGame>('deals a fresh board', buildGame, (
      game,
    ) async {
      await game.setBoard(_topRow([8, 8, 0, 0]));
      game.move(SwipeDirection.left);
      await game.ready();

      await game.restart();
      await game.ready();

      expect(game.score, equals(0));
      expect(game.highestTile, greaterThan(0));
      expect(game.undosLeft, equals(MergeTilesGame.startingUndos));
      expect(game.values.where((value) => value > 0), hasLength(2));
      expect(game.isGameOver, isFalse);
    });
  });

  group('saved runs', () {
    late GameProgress progress;

    setUp(() async {
      progress = await createTestProgress();
    });

    testWithGame<MergeTilesGame>(
      'keep the board after a move',
      () => _buildGameWith(records, progress: progress),
      (game) async {
        await game.setBoard(_topRow([2, 2, 0, 0]));
        game.move(SwipeDirection.left);
        await game.ready();

        final saved = progress.read(MergeTilesGame.recordGameId);
        expect(saved, isNotNull);
        expect(saved!['score'], equals(4));
      },
    );

    testWithGame<MergeTilesGame>(
      'are forgotten once the run is over',
      () => _buildGameWith(records, progress: progress, random: _FixedRandom()),
      (game) async {
        await game.setBoard([
          2, 4, 2, 4, //
          4, 2, 4, 2, //
          2, 4, 2, 4, //
          2, 2, 2, 4,
        ]);
        game.move(SwipeDirection.left);
        await game.ready();
        expect(game.isGameOver, isTrue);

        expect(progress.read(MergeTilesGame.recordGameId), isNull);
      },
    );

    testWithGame<MergeTilesGame>(
      'start fresh when nothing was saved',
      () => _buildGameWith(records, progress: progress),
      (game) async {
        expect(game.values.where((value) => value > 0), hasLength(2));
      },
    );
  });

  group('resuming a saved run', () {
    late GameProgress progress;

    setUp(() async {
      progress = await createTestProgress();
      // Saved before the game is built, which is how a real resume happens.
      await progress.save(MergeTilesGame.recordGameId, {
        'board': [8, 4, 0, 0, ...List.filled(12, 0)],
        'score': 120,
        'undos': 2,
      });
    });

    testWithGame<MergeTilesGame>(
      'puts the board back',
      () => _buildGameWith(records, progress: progress),
      (game) async {
        expect(game.values.take(2), equals([8, 4]));
        expect(game.values.where((value) => value > 0), hasLength(2));
      },
    );

    testWithGame<MergeTilesGame>(
      'puts the score and undos back',
      () => _buildGameWith(records, progress: progress),
      (game) async {
        expect(game.score, equals(120));
        expect(game.undosLeft, equals(2));
      },
    );

    testWithGame<MergeTilesGame>(
      'works out the biggest tile from the board',
      () => _buildGameWith(records, progress: progress),
      (game) async {
        expect(game.highestTile, equals(8));
      },
    );
  });

  group('rewarded rescue', () {
    /// Fills the board to a position with no merge left in it.
    Future<void> jam(MergeTilesGame game) async {
      await game.setBoard([
        2, 4, 2, 4, //
        4, 2, 4, 2, //
        2, 4, 2, 4, //
        2, 2, 2, 4,
      ]);
      game.move(SwipeDirection.left);
      await game.ready();
    }

    testWithGame<MergeTilesGame>(
      'takes the lowest tile and hands the board back',
      () => _buildGameWith(records, random: _FixedRandom()),
      (game) async {
        await jam(game);
        expect(game.isGameOver, isTrue);

        final before = game.values.where((value) => value != 0).toList();
        final lowest = before.reduce(min);
        final score = game.score;

        expect(game.removeTileForContinue(), isTrue);

        final after = game.values.where((value) => value != 0).toList();
        expect(after, hasLength(before.length - 1));
        expect(
          after.where((value) => value == lowest),
          hasLength(before.where((value) => value == lowest).length - 1),
          reason: 'the small wedged tiles are what jammed the board',
        );
        expect(game.isGameOver, isFalse);
        expect(game.hasAnyMove, isTrue);
        expect(game.score, equals(score));
        expect(
          game.overlays.isActive(MergeTilesGame.gameOverOverlayId),
          isFalse,
        );
      },
    );

    testWithGame<MergeTilesGame>(
      'is sold only once a run',
      () => _buildGameWith(records, random: _FixedRandom()),
      (game) async {
        await jam(game);
        expect(game.removeTileForContinue(), isTrue);
        expect(game.canContinue, isFalse);

        await jam(game);
        expect(game.removeTileForContinue(), isFalse);
        expect(game.isGameOver, isTrue);
      },
    );

    testWithGame<MergeTilesGame>(
      'is on offer again next run',
      () => _buildGameWith(records, random: _FixedRandom()),
      (game) async {
        await jam(game);
        game.removeTileForContinue();
        await game.restart();

        expect(game.canContinue, isTrue);
      },
    );
  });
}
