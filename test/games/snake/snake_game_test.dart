import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/snake/snake.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// A source of chance that always takes the first option, so a fruit lands on
/// a known cell and a trim spawns whenever the game is willing to spawn one.
class _FirstChoice implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
SnakeGame _buildGameWith(GameRecords records, {Random? random}) {
  return SnakeGame(
      sounds: createTestSounds(),
      records: records,
      random: random,
    )
    ..overlays.addEntry(
      SnakeGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// The cell one step ahead of the snake, which is where a fruit has to sit for
/// the next step to eat it.
int _aheadOfHead(SnakeGame game) =>
    game.body.first + game.direction.dy * SnakeGame.columns + game.direction.dx;

/// A snake [length] long, laid along the middle row and heading right.
List<int> _lineSnake(int length) => [
  for (var i = 0; i < length; i++)
    (SnakeGame.rows ~/ 2) * SnakeGame.columns + length - i,
];

/// Sets the snake going without turning it, which is what the first swipe of
/// a run does.
void _start(SnakeGame game) => game.steer(SnakeDirection.right);

/// Eats [count] apples.
///
/// The snake is put back on a clear cell before each one: these tests are
/// after the count, not the shape the snake ends up in.
void _eatApples(SnakeGame game, int count) {
  final start = _lineSnake(1);
  for (var i = 0; i < count; i++) {
    game
      ..setBody(start)
      ..setFruit(start.first + 1)
      ..stepOnce();
  }
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${SnakeGame.recordGameId}.${SnakeGame.recordMetric}': 40,
    });
  });

  SnakeGame buildGame() => _buildGameWith(records);

  group('SnakeGame', () {
    testWithGame<SnakeGame>('starts with a snake on the board', buildGame, (
      game,
    ) async {
      expect(game.body, hasLength(SnakeGame.startingLength));
      expect(game.direction, equals(SnakeDirection.right));
      expect(game.apples, equals(0));
      expect(game.isGameOver, isFalse);
    });

    testWithGame<SnakeGame>('waits for the first swipe', buildGame, (
      game,
    ) async {
      final body = [...game.body];

      // Long enough to have crossed the board, had it been moving.
      game.update(game.tickInterval * 30);

      expect(game.isMoving, isFalse);
      expect(game.body, equals(body));
      expect(game.isGameOver, isFalse);
    });

    testWithGame<SnakeGame>('is set going by the first swipe', buildGame, (
      game,
    ) async {
      final head = game.body.first;

      // Even one asking for the way the snake is already pointing, which is
      // not a turn but is still the swipe that starts the run.
      expect(game.steer(SnakeDirection.right), isFalse);
      game.update(game.tickInterval);

      expect(game.isMoving, isTrue);
      expect(game.body.first, equals(head + 1));
    });

    testWithGame<SnakeGame>('lays the snake out head first', buildGame, (
      game,
    ) async {
      // Every segment sits one column left of the one in front of it.
      for (var i = 1; i < game.body.length; i++) {
        expect(game.body[i], equals(game.body[i - 1] - 1));
      }
    });

    testWithGame<SnakeGame>('puts a fruit somewhere off the snake', buildGame, (
      game,
    ) async {
      expect(game.fruitCell, isNotNull);
      expect(game.body, isNot(contains(game.fruitCell)));
    });

    testWithGame<SnakeGame>('starts with an ordinary apple', buildGame, (
      game,
    ) async {
      // A trim on the first fruit would be a gift with nothing to fix.
      expect(game.isFruitTrim, isFalse);
    });

    testWithGame<SnakeGame>('moves one cell per tick', buildGame, (game) async {
      final head = game.body.first;

      _start(game);
      game.update(game.tickInterval);

      expect(game.body.first, equals(head + 1));
      expect(game.body, hasLength(SnakeGame.startingLength));
    });

    testWithGame<SnakeGame>('holds still between ticks', buildGame, (
      game,
    ) async {
      final head = game.body.first;

      _start(game);
      game.update(game.tickInterval / 3);

      expect(game.body.first, equals(head));
      expect(game.tickProgress, greaterThan(0));
    });

    testWithGame<SnakeGame>('drags the tail along behind the head', buildGame, (
      game,
    ) async {
      final body = [...game.body];

      game.stepOnce();

      // Everything shuffles up one: the old head is now the second segment.
      expect(game.body.sublist(1), equals(body.sublist(0, body.length - 1)));
    });
  });

  group('steering', () {
    testWithGame<SnakeGame>('turns on the next step', buildGame, (game) async {
      expect(game.steer(SnakeDirection.down), isTrue);
      final head = game.body.first;

      game.stepOnce();

      expect(game.direction, equals(SnakeDirection.down));
      expect(game.body.first, equals(head + SnakeGame.columns));
    });

    testWithGame<SnakeGame>('refuses to double back', buildGame, (game) async {
      expect(game.steer(SnakeDirection.left), isFalse);

      game.stepOnce();

      expect(game.direction, equals(SnakeDirection.right));
      expect(game.isGameOver, isFalse);
    });

    testWithGame<SnakeGame>('ignores the way it is already going', buildGame, (
      game,
    ) async {
      expect(game.steer(SnakeDirection.right), isFalse);
    });

    testWithGame<SnakeGame>(
      'queues two turns rather than overwriting the first',
      buildGame,
      (game) async {
        expect(game.steer(SnakeDirection.down), isTrue);
        expect(game.steer(SnakeDirection.left), isTrue);

        game.stepOnce();
        expect(game.direction, equals(SnakeDirection.down));

        game.stepOnce();
        expect(game.direction, equals(SnakeDirection.left));
      },
    );

    testWithGame<SnakeGame>(
      'never lets a queued pair fold the snake into its own neck',
      buildGame,
      (game) async {
        game.steer(SnakeDirection.down);

        // Up is the opposite of the turn already queued, not of the direction
        // the snake is still travelling in, so it has to be turned away.
        expect(game.steer(SnakeDirection.up), isFalse);
      },
    );

    testWithGame<SnakeGame>('holds no more than two turns', buildGame, (
      game,
    ) async {
      game
        ..steer(SnakeDirection.down)
        ..steer(SnakeDirection.left);

      expect(game.steer(SnakeDirection.up), isFalse);
    });

    testWithGame<SnakeGame>('is ignored once the run is over', buildGame, (
      game,
    ) async {
      game
        ..setBody([SnakeGame.columns - 1])
        ..stepOnce();
      expect(game.isGameOver, isTrue);

      expect(game.steer(SnakeDirection.down), isFalse);
    });
  });

  group('eating', () {
    testWithGame<SnakeGame>('grows the snake by one', buildGame, (game) async {
      game
        ..setFruit(_aheadOfHead(game))
        ..stepOnce();

      expect(game.apples, equals(1));
      expect(game.length, equals(SnakeGame.startingLength + 1));
    });

    testWithGame<SnakeGame>('leaves the tail where it was', buildGame, (
      game,
    ) async {
      final tail = game.body.last;

      game
        ..setFruit(_aheadOfHead(game))
        ..stepOnce();

      expect(game.body.last, equals(tail));
      expect(game.grewLastStep, isTrue);
    });

    testWithGame<SnakeGame>('puts a fresh fruit on an empty cell', buildGame, (
      game,
    ) async {
      final eaten = _aheadOfHead(game);

      game
        ..setFruit(eaten)
        ..stepOnce();

      expect(game.fruitCell, isNot(equals(eaten)));
      expect(game.body, isNot(contains(game.fruitCell)));
    });

    testWithGame<SnakeGame>('speeds the snake up as it goes', buildGame, (
      game,
    ) async {
      final startingInterval = game.tickInterval;

      _eatApples(game, 5);

      expect(game.tickInterval, lessThan(startingInterval));
    });

    testWithGame<SnakeGame>('never speeds up past the floor', buildGame, (
      game,
    ) async {
      _eatApples(game, 60);
      final floor = game.tickInterval;

      _eatApples(game, 20);

      expect(game.tickInterval, equals(floor));
    });
  });

  group('crashing', () {
    testWithGame<SnakeGame>('into a wall ends the run', buildGame, (
      game,
    ) async {
      // A head in the rightmost column with nowhere right to go.
      game
        ..setBody([SnakeGame.columns - 1])
        ..stepOnce();

      expect(game.isGameOver, isTrue);
      expect(game.overlays.isActive(SnakeGame.gameOverOverlayId), isTrue);
    });

    testWithGame<SnakeGame>('into itself ends the run', buildGame, (
      game,
    ) async {
      // A square of five, with the head about to step onto its own middle.
      const head = 5 * SnakeGame.columns + 5;
      game
        ..setBody([
          head,
          head + SnakeGame.columns,
          head + SnakeGame.columns + 1,
          head + 1,
          head + 2,
        ])
        ..steer(SnakeDirection.down)
        ..stepOnce();

      expect(game.isGameOver, isTrue);
    });

    testWithGame<SnakeGame>(
      'into the cell the tail is leaving is fine',
      () {
        return _buildGameWith(records);
      },
      (game) async {
        // Head chasing its own tail around a square: the tail moves out of
        // the cell on the tick the head moves in, so this is not a crash.
        const head = 5 * SnakeGame.columns + 5;
        game
          ..setBody([
            head,
            head + 1,
            head + SnakeGame.columns + 1,
            head + SnakeGame.columns,
          ])
          // Nothing to eat nearby, so the tail is free to move.
          ..setFruit(0)
          ..steer(SnakeDirection.down)
          ..stepOnce();

        expect(game.isGameOver, isFalse);
        expect(game.body.first, equals(head + SnakeGame.columns));
      },
    );

    testWithGame<SnakeGame>('stops the snake moving', buildGame, (game) async {
      _start(game);
      game
        ..setBody([SnakeGame.columns - 1])
        ..stepOnce();
      final body = [...game.body];

      game.update(game.tickInterval * 3);

      expect(game.body, equals(body));
    });
  });

  group('the trim fruit', () {
    testWithGame<SnakeGame>('hands back a few segments', buildGame, (
      game,
    ) async {
      final body = _lineSnake(SnakeGame.trimUnlockLength);

      game
        ..setBody(body)
        ..setFruit(body.first + 1, isTrim: true)
        ..stepOnce();

      // One segment on for the bite, then the trim off the end.
      expect(
        game.length,
        equals(SnakeGame.trimUnlockLength + 1 - SnakeGame.trimAmount),
      );
    });

    testWithGame<SnakeGame>('still counts as an apple', buildGame, (
      game,
    ) async {
      final apples = game.apples;

      game
        ..setFruit(_aheadOfHead(game), isTrim: true)
        ..stepOnce();

      // The comeback must not cost the player the number they are chasing.
      expect(game.apples, equals(apples + 1));
    });

    testWithGame<SnakeGame>(
      'never trims below the starting length',
      buildGame,
      (
        game,
      ) async {
        game
          ..setFruit(_aheadOfHead(game), isTrim: true)
          ..stepOnce();

        expect(game.length, equals(SnakeGame.startingLength));
      },
    );

    testWithGame<SnakeGame>(
      'turns up once the snake is long enough to need it',
      () => _buildGameWith(records, random: _FirstChoice()),
      (game) async {
        game
          ..setBody(_lineSnake(SnakeGame.trimUnlockLength))
          ..setFruit(_aheadOfHead(game))
          ..stepOnce();

        expect(game.isFruitTrim, isTrue);
      },
    );

    testWithGame<SnakeGame>(
      'stays away while the snake is still short',
      () => _buildGameWith(records, random: _FirstChoice()),
      (game) async {
        // Same willing dice as above: it is the length that holds the trim
        // back, so a run that is not struggling for room never sees one.
        game
          ..setFruit(_aheadOfHead(game))
          ..stepOnce();

        expect(game.isFruitTrim, isFalse);
      },
    );
  });

  group('records', () {
    testWithGame<SnakeGame>(
      'store the apples eaten when the run ends',
      () {
        return _buildGameWith(records);
      },
      (game) async {
        _eatApples(game, 3);
        game
          ..setBody([SnakeGame.columns - 1])
          ..stepOnce();
        await game.ready();

        expect(
          records.read(SnakeGame.recordGameId, SnakeGame.recordMetric),
          equals(3),
        );
        expect(game.isNewRecord, isTrue);
      },
    );

    testWithGame<SnakeGame>(
      'load the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestApples, equals(40));
      },
    );

    testWithGame<SnakeGame>(
      'are not flagged for a shorter run',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        game
          ..setBody([SnakeGame.columns - 1])
          ..stepOnce();
        await game.ready();

        expect(game.isNewRecord, isFalse);
        expect(game.bestApples, equals(40));
      },
    );
  });

  group('restart', () {
    testWithGame<SnakeGame>('puts a fresh snake back on the board', buildGame, (
      game,
    ) async {
      _eatApples(game, 4);
      game
        ..setBody([SnakeGame.columns - 1])
        ..stepOnce();
      expect(game.isGameOver, isTrue);

      game.restart();
      await game.ready();

      expect(game.apples, equals(0));
      expect(game.length, equals(SnakeGame.startingLength));
      expect(game.direction, equals(SnakeDirection.right));
      expect(game.isGameOver, isFalse);
      expect(game.fruitCell, isNotNull);
      expect(game.overlays.isActive(SnakeGame.gameOverOverlayId), isFalse);
      // Waiting again, so the next run does not start while the player is
      // still reading the end of the last one.
      expect(game.isMoving, isFalse);
    });

    testWithGame<SnakeGame>('drops any turns left over', buildGame, (
      game,
    ) async {
      game
        ..steer(SnakeDirection.down)
        ..restart()
        ..stepOnce();

      expect(game.direction, equals(SnakeDirection.right));
    });
  });
}
