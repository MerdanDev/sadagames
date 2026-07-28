import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/tile_tap/tile_tap.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
TileTapGame _buildGameWith(GameRecords records) {
  return TileTapGame(sounds: createTestSounds(), records: records)
    ..overlays.addEntry(
      TileTapGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// A column that is not the one the player owes.
int _wrongColumn(TileTapGame game) =>
    (game.targetRow!.column + 1) % TileTapGame.columns;

/// Hits [count] tiles correctly, letting the board scroll between each.
Future<void> _hitTiles(TileTapGame game, int count) async {
  for (var i = 0; i < count; i++) {
    game
      ..tapColumn(game.targetRow!.column)
      ..update(0.016);
    await game.ready();
  }
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${TileTapGame.recordGameId}.${TileTapGame.recordMetric}': 250,
    });
  });

  TileTapGame buildGame() => _buildGameWith(records);

  group('TileTapGame', () {
    testWithGame<TileTapGame>('starts with a full track', buildGame, (
      game,
    ) async {
      expect(game.rows, isNotEmpty);
      expect(game.tiles, equals(0));
      expect(game.isGameOver, isFalse);
    });

    testWithGame<TileTapGame>('starts with no skips in hand', buildGame, (
      game,
    ) async {
      expect(game.skips, equals(0));
    });

    testWithGame<TileTapGame>('puts one tile in every row', buildGame, (
      game,
    ) async {
      for (final row in game.rows) {
        expect(row.column, inInclusiveRange(0, TileTapGame.columns - 1));
      }
    });

    testWithGame<TileTapGame>('owes the lowest untapped row', buildGame, (
      game,
    ) async {
      final lowest = game.rows
          .where((row) => !row.isTapped)
          .reduce((a, b) => a.position.y > b.position.y ? a : b);

      expect(game.targetRow, equals(lowest));
    });

    testWithGame<TileTapGame>(
      'gives the player a moment before the first row can slip past',
      buildGame,
      (game) async {
        // A second of doing nothing at the start must not end the run.
        for (var i = 0; i < 60; i++) {
          game.update(0.016);
        }

        expect(game.isGameOver, isFalse);
      },
    );

    testWithGame<TileTapGame>('scrolls the track downwards', buildGame, (
      game,
    ) async {
      final startY = game.rows.first.position.y;

      game.update(0.1);

      expect(game.rows.first.position.y, greaterThan(startY));
    });

    testWithGame<TileTapGame>('keeps the track topped up', buildGame, (
      game,
    ) async {
      for (var i = 0; i < 30; i++) {
        game
          ..tapColumn(game.targetRow!.column)
          ..update(0.05);
        await game.ready();
      }

      expect(game.rows, isNotEmpty);
    });
  });

  group('hitting tiles', () {
    testWithGame<TileTapGame>('counts a correct column', buildGame, (
      game,
    ) async {
      expect(game.tapColumn(game.targetRow!.column), isTrue);

      expect(game.tiles, equals(1));
    });

    testWithGame<TileTapGame>('marks the row as done', buildGame, (
      game,
    ) async {
      final target = game.targetRow!;

      game.tapColumn(target.column);

      expect(target.isTapped, isTrue);
      expect(game.targetRow, isNot(equals(target)));
    });

    testWithGame<TileTapGame>('speeds the track up as it goes', buildGame, (
      game,
    ) async {
      final startingSpeed = game.speed;

      await _hitTiles(game, 5);

      expect(game.speed, greaterThan(startingSpeed));
    });
  });

  group('mistakes', () {
    testWithGame<TileTapGame>('end the run on a wrong column', buildGame, (
      game,
    ) async {
      expect(game.tapColumn(_wrongColumn(game)), isFalse);

      expect(game.isGameOver, isTrue);
      expect(game.overlays.isActive(TileTapGame.gameOverOverlayId), isTrue);
    });

    testWithGame<TileTapGame>('end the run when a row slips past', buildGame, (
      game,
    ) async {
      // Long enough for the lowest row to leave the bottom untapped.
      for (var i = 0; i < 120 && !game.isGameOver; i++) {
        game.update(0.05);
      }

      expect(game.isGameOver, isTrue);
    });

    testWithGame<TileTapGame>('are ignored once the run is over', buildGame, (
      game,
    ) async {
      game.tapColumn(_wrongColumn(game));

      expect(game.tapColumn(game.rows.first.column), isFalse);
      expect(game.tiles, equals(0));
    });
  });

  group('skips', () {
    testWithGame<TileTapGame>('are earned by hitting tiles', buildGame, (
      game,
    ) async {
      await _hitTiles(game, TileTapGame.tilesPerSkip);

      expect(game.skips, equals(1));
    });

    testWithGame<TileTapGame>('cover a mistake instead of ending', buildGame, (
      game,
    ) async {
      await _hitTiles(game, TileTapGame.tilesPerSkip);
      expect(game.skips, equals(1));

      game.tapColumn(_wrongColumn(game));

      expect(game.isGameOver, isFalse);
      expect(game.skips, equals(0));
    });

    testWithGame<TileTapGame>('only cover one mistake each', buildGame, (
      game,
    ) async {
      await _hitTiles(game, TileTapGame.tilesPerSkip);
      game
        ..tapColumn(_wrongColumn(game))
        ..tapColumn(_wrongColumn(game));

      expect(game.isGameOver, isTrue);
    });

    testWithGame<TileTapGame>('never stack beyond the cap', buildGame, (
      game,
    ) async {
      await _hitTiles(
        game,
        TileTapGame.tilesPerSkip * (TileTapGame.maxSkips + 2),
      );

      expect(game.skips, equals(TileTapGame.maxSkips));
    });
  });

  group('records', () {
    testWithGame<TileTapGame>(
      'store the tiles hit when the run ends',
      buildGame,
      (game) async {
        await _hitTiles(game, 3);
        game.tapColumn(_wrongColumn(game));
        await game.ready();

        expect(
          records.read(TileTapGame.recordGameId, TileTapGame.recordMetric),
          equals(3),
        );
        expect(game.isNewRecord, isTrue);
      },
    );

    testWithGame<TileTapGame>(
      'load the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestTiles, equals(250));
      },
    );

    testWithGame<TileTapGame>(
      'are not flagged for a shorter run',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        game.tapColumn(_wrongColumn(game));
        await game.ready();

        expect(game.isNewRecord, isFalse);
        expect(game.bestTiles, equals(250));
      },
    );
  });

  group('restart', () {
    testWithGame<TileTapGame>('lays a fresh track', buildGame, (game) async {
      await _hitTiles(game, 2);
      game.tapColumn(_wrongColumn(game));
      expect(game.isGameOver, isTrue);

      await game.restart();
      await game.ready();

      expect(game.tiles, equals(0));
      expect(game.skips, equals(0));
      expect(game.isGameOver, isFalse);
      expect(game.rows, isNotEmpty);
      expect(game.rows.every((row) => !row.isTapped), isTrue);
      expect(game.overlays.isActive(TileTapGame.gameOverOverlayId), isFalse);
    });
  });
}
