import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/stack_tower/stack_tower.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
StackTowerGame _buildGameWith(GameRecords records) {
  return StackTowerGame(sounds: createTestSounds(), records: records)
    ..overlays.addEntry(
      StackTowerGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// Slides the moving slab so its left edge sits [offset] from the top block.
void _aimAt(StackTowerGame game, double offset) {
  game.movingBlock!.position.x = game.blocks.last.left + offset;
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${StackTowerGame.recordGameId}.${StackTowerGame.recordMetric}':
          40,
    });
  });

  StackTowerGame buildGame() => _buildGameWith(records);

  group('StackTowerGame', () {
    testWithGame<StackTowerGame>('starts with a base and a slab', buildGame, (
      game,
    ) async {
      expect(game.blocks, hasLength(1));
      expect(game.height, equals(1));
      expect(game.movingBlock, isNotNull);
      expect(game.isGameOver, isFalse);
    });

    testWithGame<StackTowerGame>('slides the slab across', buildGame, (
      game,
    ) async {
      final startX = game.movingBlock!.position.x;

      game.update(0.2);

      expect(game.movingBlock!.position.x, isNot(equals(startX)));
    });

    testWithGame<StackTowerGame>('keeps the slab on screen', buildGame, (
      game,
    ) async {
      for (var i = 0; i < 200; i++) {
        game.update(0.05);
        expect(game.movingBlock!.left, greaterThanOrEqualTo(-0.01));
        expect(game.movingBlock!.right, lessThanOrEqualTo(game.size.x + 0.01));
      }
    });

    testWithGame<StackTowerGame>('stacks a slab when dropped', buildGame, (
      game,
    ) async {
      _aimAt(game, 20);

      expect(game.dropBlock(), isTrue);

      expect(game.blocks, hasLength(2));
      expect(game.height, equals(2));
    });

    testWithGame<StackTowerGame>(
      'hands out a fresh slab after a drop',
      buildGame,
      (game) async {
        _aimAt(game, 20);
        game.dropBlock();
        await game.ready();

        expect(game.movingBlock, isNotNull);
        expect(game.movingBlock!.width, equals(game.blocks.last.width));
      },
    );

    testWithGame<StackTowerGame>('speeds up as the tower grows', buildGame, (
      game,
    ) async {
      final startingSpeed = game.speed;

      for (var i = 0; i < 5; i++) {
        _aimAt(game, 0);
        game.dropBlock();
        await game.ready();
      }

      expect(game.speed, greaterThan(startingSpeed));
    });
  });

  group('trimming', () {
    testWithGame<StackTowerGame>(
      'cuts the overhang off a sloppy drop',
      buildGame,
      (game) async {
        final startWidth = game.blocks.last.width;
        _aimAt(game, 30);

        game.dropBlock();

        expect(game.blocks.last.width, closeTo(startWidth - 30, 0.01));
      },
    );

    testWithGame<StackTowerGame>(
      'lines the trimmed slab up with the overlap',
      buildGame,
      (game) async {
        final base = game.blocks.last;
        final expectedLeft = base.left + 30;
        _aimAt(game, 30);

        game.dropBlock();

        expect(game.blocks.last.left, closeTo(expectedLeft, 0.01));
      },
    );

    testWithGame<StackTowerGame>(
      'trims from the left when aimed short',
      buildGame,
      (game) async {
        final base = game.blocks.last;
        final baseLeft = base.left;
        final startWidth = base.width;
        _aimAt(game, -25);

        game.dropBlock();

        expect(game.blocks.last.left, closeTo(baseLeft, 0.01));
        expect(game.blocks.last.width, closeTo(startWidth - 25, 0.01));
      },
    );

    testWithGame<StackTowerGame>(
      'drops the sliced piece as decoration',
      buildGame,
      (game) async {
        _aimAt(game, 30);

        game.dropBlock();
        await game.ready();

        expect(game.tower.children.query<FallingCut>(), hasLength(1));
      },
    );
  });

  group('perfect drops', () {
    testWithGame<StackTowerGame>('keep the full width', buildGame, (
      game,
    ) async {
      final startWidth = game.blocks.last.width;
      _aimAt(game, StackTowerGame.perfectTolerance / 2);

      game.dropBlock();

      expect(game.blocks.last.width, greaterThanOrEqualTo(startWidth));
      expect(game.perfectDrops, equals(1));
    });

    testWithGame<StackTowerGame>('cut nothing off', buildGame, (game) async {
      _aimAt(game, 0);

      game.dropBlock();
      await game.ready();

      expect(game.tower.children.query<FallingCut>(), isEmpty);
    });

    testWithGame<StackTowerGame>(
      'win width back once some is lost',
      buildGame,
      (game) async {
        _aimAt(game, 40);
        game.dropBlock();
        await game.ready();
        final narrowed = game.blocks.last.width;

        _aimAt(game, 0);
        game.dropBlock();

        expect(game.blocks.last.width, greaterThan(narrowed));
      },
    );

    testWithGame<StackTowerGame>(
      'never widen past the starting slab',
      buildGame,
      (game) async {
        final startWidth = game.blocks.last.width;

        for (var i = 0; i < 6; i++) {
          _aimAt(game, 0);
          game.dropBlock();
          await game.ready();
        }

        expect(game.blocks.last.width, lessThanOrEqualTo(startWidth + 0.01));
      },
    );
  });

  group('missing the tower', () {
    testWithGame<StackTowerGame>('ends the run', buildGame, (game) async {
      _aimAt(game, game.blocks.last.width + 5);

      expect(game.dropBlock(), isFalse);

      expect(game.isGameOver, isTrue);
      expect(
        game.overlays.isActive(StackTowerGame.gameOverOverlayId),
        isTrue,
      );
    });

    testWithGame<StackTowerGame>('ignores further drops', buildGame, (
      game,
    ) async {
      _aimAt(game, game.blocks.last.width + 5);
      game.dropBlock();
      final height = game.height;

      expect(game.dropBlock(), isFalse);
      expect(game.height, equals(height));
    });
  });

  group('records', () {
    testWithGame<StackTowerGame>('store the height reached', buildGame, (
      game,
    ) async {
      _aimAt(game, 20);
      game.dropBlock();
      await game.ready();
      _aimAt(game, game.blocks.last.width + 5);
      game.dropBlock();

      expect(
        records.read(
          StackTowerGame.recordGameId,
          StackTowerGame.recordMetric,
        ),
        equals(2),
      );
      expect(game.isNewRecord, isTrue);
    });

    testWithGame<StackTowerGame>(
      'load the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestHeight, equals(40));
      },
    );

    testWithGame<StackTowerGame>(
      'are not flagged for a shorter tower',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        _aimAt(game, game.blocks.last.width + 5);
        game.dropBlock();

        expect(game.isNewRecord, isFalse);
        expect(game.bestHeight, equals(40));
      },
    );
  });

  group('restart', () {
    testWithGame<StackTowerGame>('starts a fresh tower', buildGame, (
      game,
    ) async {
      _aimAt(game, 30);
      game.dropBlock();
      await game.ready();
      _aimAt(game, game.blocks.last.width + 5);
      game.dropBlock();
      expect(game.isGameOver, isTrue);

      await game.restart();
      await game.ready();

      expect(game.height, equals(1));
      expect(game.perfectDrops, equals(0));
      expect(game.isGameOver, isFalse);
      expect(game.movingBlock, isNotNull);
      expect(
        game.overlays.isActive(StackTowerGame.gameOverOverlayId),
        isFalse,
      );
    });
  });
}
