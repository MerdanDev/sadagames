import 'package:audioplayers/audioplayers.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadagames/games/odd_one_out/odd_one_out.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

_MockAudioPlayer _audioPlayer() {
  final player = _MockAudioPlayer();
  when(() => player.setPlaybackRate(any())).thenAnswer((_) async {});
  when(() => player.play(any())).thenAnswer((_) async {});
  return player;
}

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
OddOneOutGame _buildGameWith(GameRecords records) {
  return OddOneOutGame(effectPlayer: _audioPlayer(), records: records)
    ..overlays.addEntry(
      OddOneOutGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// Any tile index that is not the odd one.
int _wrongIndex(OddOneOutGame game) =>
    game.oddIndex == 0 ? 1 : game.oddIndex - 1;

/// Clears [levels] levels by tapping the odd tile each time.
Future<void> _clearLevels(OddOneOutGame game, int levels) async {
  for (var i = 0; i < levels; i++) {
    game.chooseTile(game.oddIndex);
    await game.ready();
  }
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUpAll(() {
    registerFallbackValue(AssetSource('effect.mp3'));
  });

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${OddOneOutGame.recordGameId}.${OddOneOutGame.recordMetric}': 30,
    });
  });

  OddOneOutGame buildGame() => _buildGameWith(records);

  group('OddOneOutGame', () {
    testWithGame<OddOneOutGame>(
      'starts on level one with a full set of lives',
      buildGame,
      (game) async {
        expect(game.level, equals(1));
        expect(game.lives, equals(OddOneOutGame.maxLives));
        expect(game.isGameOver, isFalse);
      },
    );

    testWithGame<OddOneOutGame>('lays out a full grid of tiles', buildGame, (
      game,
    ) async {
      expect(
        game.children.query<ColourTile>(),
        hasLength(game.gridSize * game.gridSize),
      );
    });

    testWithGame<OddOneOutGame>(
      'gives exactly one tile the odd colour',
      buildGame,
      (game) async {
        final tiles = game.children.query<ColourTile>();
        final colours = tiles.map((tile) => tile.colour).toSet();
        final oddColour = tiles
            .firstWhere((tile) => tile.index == game.oddIndex)
            .colour;

        expect(colours, hasLength(2));
        expect(
          tiles.where((tile) => tile.colour == oddColour),
          hasLength(1),
        );
      },
    );

    testWithGame<OddOneOutGame>(
      'advances a level when the odd tile is tapped',
      buildGame,
      (game) async {
        game.chooseTile(game.oddIndex);

        expect(game.level, equals(2));
        expect(game.lives, equals(OddOneOutGame.maxLives));
      },
    );

    testWithGame<OddOneOutGame>(
      'costs a life when the wrong tile is tapped',
      buildGame,
      (game) async {
        game.chooseTile(_wrongIndex(game));

        expect(game.lives, equals(OddOneOutGame.maxLives - 1));
        expect(game.level, equals(1));
      },
    );

    testWithGame<OddOneOutGame>(
      'costs a life when the timer runs out',
      buildGame,
      (game) async {
        game.update(30);

        expect(game.lives, equals(OddOneOutGame.maxLives - 1));
      },
    );

    testWithGame<OddOneOutGame>(
      'ignores taps once the run is over',
      buildGame,
      (game) async {
        for (var i = 0; i < OddOneOutGame.maxLives; i++) {
          game.chooseTile(_wrongIndex(game));
        }
        expect(game.isGameOver, isTrue);

        game.chooseTile(game.oddIndex);

        expect(game.level, equals(1));
      },
    );

    testWithGame<OddOneOutGame>(
      'ends the run once every life is spent',
      buildGame,
      (game) async {
        for (var i = 0; i < OddOneOutGame.maxLives; i++) {
          game.chooseTile(_wrongIndex(game));
        }

        expect(game.lives, equals(0));
        expect(game.isGameOver, isTrue);
        expect(
          game.overlays.isActive(OddOneOutGame.gameOverOverlayId),
          isTrue,
        );
      },
    );

    testWithGame<OddOneOutGame>(
      'restart returns to level one with a clean board',
      buildGame,
      (game) async {
        for (var i = 0; i < OddOneOutGame.maxLives; i++) {
          game.chooseTile(_wrongIndex(game));
        }

        game.restart();
        await game.ready();

        expect(game.level, equals(1));
        expect(game.lives, equals(OddOneOutGame.maxLives));
        expect(game.isGameOver, isFalse);
        expect(
          game.overlays.isActive(OddOneOutGame.gameOverOverlayId),
          isFalse,
        );
      },
    );
  });

  group('difficulty', () {
    testWithGame<OddOneOutGame>(
      'grows the grid as levels are cleared',
      buildGame,
      (game) async {
        final startingGrid = game.gridSize;

        await _clearLevels(game, 6);

        expect(game.gridSize, greaterThan(startingGrid));
        expect(
          game.children.query<ColourTile>(),
          hasLength(game.gridSize * game.gridSize),
        );
      },
    );

    testWithGame<OddOneOutGame>(
      'narrows the colour gap as levels are cleared',
      buildGame,
      (game) async {
        final startingGap = game.colourGap;

        await _clearLevels(game, 6);

        expect(game.colourGap, lessThan(startingGap));
      },
    );

    testWithGame<OddOneOutGame>(
      'never lets the colour gap reach zero',
      buildGame,
      (game) async {
        await _clearLevels(game, 40);

        expect(game.colourGap, greaterThan(0));
      },
    );
  });

  group('comeback', () {
    testWithGame<OddOneOutGame>(
      'gives a life back after a run of cleared levels',
      buildGame,
      (game) async {
        game.chooseTile(_wrongIndex(game));
        expect(game.lives, equals(OddOneOutGame.maxLives - 1));

        await _clearLevels(game, OddOneOutGame.levelsPerExtraLife);

        expect(game.lives, equals(OddOneOutGame.maxLives));
      },
    );

    testWithGame<OddOneOutGame>(
      'never takes the player above the maximum lives',
      buildGame,
      (game) async {
        await _clearLevels(game, OddOneOutGame.levelsPerExtraLife * 2);

        expect(game.lives, equals(OddOneOutGame.maxLives));
      },
    );
  });

  group('records', () {
    testWithGame<OddOneOutGame>(
      'stores the level reached when the run ends',
      buildGame,
      (game) async {
        await _clearLevels(game, 2);
        for (var i = 0; i < OddOneOutGame.maxLives; i++) {
          game.chooseTile(_wrongIndex(game));
        }
        await game.ready();

        expect(
          records.read(
            OddOneOutGame.recordGameId,
            OddOneOutGame.recordMetric,
          ),
          equals(3),
        );
        expect(game.isNewRecord, isTrue);
      },
    );

    testWithGame<OddOneOutGame>(
      'loads the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestLevel, equals(30));
      },
    );

    testWithGame<OddOneOutGame>(
      'does not flag a record for a shorter run',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        for (var i = 0; i < OddOneOutGame.maxLives; i++) {
          game.chooseTile(_wrongIndex(game));
        }
        await game.ready();

        expect(game.isNewRecord, isFalse);
        expect(game.bestLevel, equals(30));
      },
    );
  });
}
