import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/star_catcher/star_catcher.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

class _AlwaysHeartRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
StarCatcherGame _buildGameWith(GameRecords records, {Random? random}) {
  return StarCatcherGame(
      sounds: createTestSounds(),
      records: records,
      random: random,
    )
    ..overlays.addEntry(
      StarCatcherGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

Star _missedStar(StarCatcherGame game) =>
    Star(position: Vector2(10, game.size.y + 100), speed: 0);

Future<void> _loseAllLives(StarCatcherGame game) async {
  for (var i = 0; i < StarCatcherGame.maxLives; i++) {
    await game.ensureAdd(_missedStar(game));
    game.update(0);
  }
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
  });

  setUp(() async {
    recordsWithBest = await createTestRecords({
      'record.${StarCatcherGame.recordGameId}.'
              '${StarCatcherGame.recordMetric}':
          42,
    });
  });

  StarCatcherGame buildGame({Random? random}) =>
      _buildGameWith(records, random: random);

  group('StarCatcherGame', () {
    testWithGame<StarCatcherGame>(
      'starts with a full set of lives and no score',
      buildGame,
      (game) async {
        expect(game.score, equals(0));
        expect(game.lives, equals(StarCatcherGame.maxLives));
        expect(game.isGameOver, isFalse);
      },
    );

    testWithGame<StarCatcherGame>(
      'spawns collectibles over time',
      buildGame,
      (game) async {
        game.update(1);
        await game.ready();

        expect(game.children.query<FallingCollectible>(), isNotEmpty);
      },
    );

    testWithGame<StarCatcherGame>(
      'scores a point when a star reaches the basket',
      buildGame,
      (game) async {
        final star = Star(position: game.basket.position.clone(), speed: 0);
        await game.ensureAdd(star);

        game.update(0);

        expect(game.score, equals(1));
        expect(star.isRemoving || star.isRemoved, isTrue);
      },
    );

    testWithGame<StarCatcherGame>(
      'loses a life when a star falls past the bottom',
      buildGame,
      (game) async {
        await game.ensureAdd(_missedStar(game));

        game.update(0);

        expect(game.lives, equals(StarCatcherGame.maxLives - 1));
      },
    );

    testWithGame<StarCatcherGame>(
      'ends the game once every life is lost',
      buildGame,
      (game) async {
        await _loseAllLives(game);

        expect(game.lives, equals(0));
        expect(game.isGameOver, isTrue);
        expect(
          game.overlays.isActive(StarCatcherGame.gameOverOverlayId),
          isTrue,
        );
      },
    );

    testWithGame<StarCatcherGame>(
      'restart resets the score, lives and overlay',
      buildGame,
      (game) async {
        await _loseAllLives(game);
        expect(game.isGameOver, isTrue);

        game.restart();

        expect(game.score, equals(0));
        expect(game.lives, equals(StarCatcherGame.maxLives));
        expect(game.isGameOver, isFalse);
        expect(
          game.overlays.isActive(StarCatcherGame.gameOverOverlayId),
          isFalse,
        );
      },
    );
  });

  group('hearts', () {
    testWithGame<StarCatcherGame>(
      'refill a life when caught',
      buildGame,
      (game) async {
        await game.ensureAdd(_missedStar(game));
        game.update(0);
        expect(game.lives, equals(StarCatcherGame.maxLives - 1));

        await game.ensureAdd(
          Heart(position: game.basket.position.clone(), speed: 0),
        );
        game.update(0);

        expect(game.lives, equals(StarCatcherGame.maxLives));
      },
    );

    testWithGame<StarCatcherGame>(
      'never take the player above the maximum lives',
      buildGame,
      (game) async {
        await game.ensureAdd(
          Heart(position: game.basket.position.clone(), speed: 0),
        );
        game.update(0);

        expect(game.lives, equals(StarCatcherGame.maxLives));
      },
    );

    testWithGame<StarCatcherGame>(
      'do not cost a life when missed',
      buildGame,
      (game) async {
        await game.ensureAdd(
          Heart(position: Vector2(10, game.size.y + 100), speed: 0),
        );
        game.update(0);

        expect(game.lives, equals(StarCatcherGame.maxLives));
      },
    );

    testWithGame<StarCatcherGame>(
      'only drop once the unlock score is reached and a life is missing',
      () => buildGame(random: _AlwaysHeartRandom()),
      (game) async {
        // Below the unlock score only stars drop, even with a life missing.
        await game.ensureAdd(_missedStar(game));
        game
          ..update(0)
          ..update(1);
        await game.ready();
        expect(game.children.query<Heart>(), isEmpty);

        // Once the score is high enough, hearts start dropping.
        for (var i = 0; i < StarCatcherGame.heartUnlockScore; i++) {
          await game.ensureAdd(
            Star(position: game.basket.position.clone(), speed: 0),
          );
          game.update(0);
        }
        game.update(1);
        await game.ready();

        expect(game.children.query<Heart>(), isNotEmpty);
      },
    );
  });

  group('records', () {
    testWithGame<StarCatcherGame>(
      'stores the score when the run ends',
      buildGame,
      (game) async {
        await game.ensureAdd(
          Star(position: game.basket.position.clone(), speed: 0),
        );
        game.update(0);
        await _loseAllLives(game);
        await game.ready();

        expect(
          records.read(
            StarCatcherGame.recordGameId,
            StarCatcherGame.recordMetric,
          ),
          equals(1),
        );
        expect(game.isNewRecord, isTrue);
        expect(game.bestScore, equals(1));
      },
    );

    testWithGame<StarCatcherGame>(
      'loads the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestScore, equals(42));
      },
    );

    testWithGame<StarCatcherGame>(
      'does not flag a record when the score falls short',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        await _loseAllLives(game);
        await game.ready();

        expect(game.isNewRecord, isFalse);
        expect(game.bestScore, equals(42));
      },
    );
  });

  group('stars', () {
    testWithGame<StarCatcherGame>(
      'shrink as the score grows',
      buildGame,
      (game) async {
        game.update(1);
        await game.ready();
        final initialDiameter = game.children.query<Star>().first.size.x;

        for (var i = 0; i < 10; i++) {
          await game.ensureAdd(
            Star(position: game.basket.position.clone(), speed: 0),
          );
          game.update(0);
        }
        game.update(1);
        await game.ready();

        final laterDiameter = game.children
            .query<Star>()
            .map((star) => star.size.x)
            .reduce(min);
        expect(laterDiameter, lessThan(initialDiameter));
      },
    );
  });

  group('Basket', () {
    testWithGame<StarCatcherGame>(
      'is drawn in front of the falling pieces',
      buildGame,
      (game) async {
        final star = Star(position: Vector2(10, 10), speed: 0);
        await game.ensureAdd(star);

        expect(game.basket.priority, greaterThan(star.priority));
      },
    );

    testWithGame<StarCatcherGame>(
      'stays inside the screen bounds',
      buildGame,
      (game) async {
        game.basket.moveTo(-500, game.size.x);
        expect(game.basket.position.x, equals(game.basket.size.x / 2));

        game.basket.moveTo(game.size.x + 500, game.size.x);
        expect(
          game.basket.position.x,
          equals(game.size.x - game.basket.size.x / 2),
        );
      },
    );
  });
}
