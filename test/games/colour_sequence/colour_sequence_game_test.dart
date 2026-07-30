import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/colour_sequence/colour_sequence.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
ColourSequenceGame _buildGameWith(GameRecords records) {
  return ColourSequenceGame(sounds: createTestSounds(), records: records)
    ..overlays.addEntry(
      ColourSequenceGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// Runs the clock until the game hands control back to the player.
void _watchPlayback(ColourSequenceGame game) {
  for (var i = 0; i < 400 && game.status == SequenceStatus.showing; i++) {
    game.update(0.05);
  }
}

/// Repeats the sequence correctly, which starts the next round.
void _answerCorrectly(ColourSequenceGame game) {
  [...game.sequence].forEach(game.pressPad);
}

/// A pad that is not the one expected next.
int _wrongPad(ColourSequenceGame game) =>
    (game.sequence.first + 1) % ColourSequenceGame.padCount;

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
    recordsWithBest = await createTestRecords({
      'record.${ColourSequenceGame.recordGameId}.'
              '${ColourSequenceGame.recordMetric}':
          25,
    });
  });

  ColourSequenceGame buildGame() => _buildGameWith(records);

  group('ColourSequenceGame', () {
    testWithGame<ColourSequenceGame>(
      'starts by showing a one pad sequence',
      buildGame,
      (game) async {
        expect(game.sequence, hasLength(1));
        expect(game.status, equals(SequenceStatus.showing));
        expect(game.completedRounds, equals(0));
        expect(game.lives, equals(ColourSequenceGame.maxLives));
      },
    );

    testWithGame<ColourSequenceGame>('lays out four pads', buildGame, (
      game,
    ) async {
      expect(
        game.children.query<SequencePad>(),
        hasLength(ColourSequenceGame.padCount),
      );
    });

    testWithGame<ColourSequenceGame>(
      'hands over to the player once playback finishes',
      buildGame,
      (game) async {
        _watchPlayback(game);

        expect(game.status, equals(SequenceStatus.awaitingInput));
      },
    );

    testWithGame<ColourSequenceGame>(
      'ignores presses while the sequence is playing',
      buildGame,
      (game) async {
        game.pressPad(_wrongPad(game));

        expect(game.lives, equals(ColourSequenceGame.maxLives));
        expect(game.status, equals(SequenceStatus.showing));
      },
    );

    testWithGame<ColourSequenceGame>(
      'grows the sequence when it is repeated correctly',
      buildGame,
      (game) async {
        _watchPlayback(game);

        _answerCorrectly(game);

        expect(game.completedRounds, equals(1));
        expect(game.sequence, hasLength(2));
        expect(game.status, equals(SequenceStatus.showing));
      },
    );

    testWithGame<ColourSequenceGame>(
      'keeps the earlier pads when the sequence grows',
      buildGame,
      (game) async {
        _watchPlayback(game);
        final firstPad = game.sequence.first;

        _answerCorrectly(game);

        expect(game.sequence.first, equals(firstPad));
      },
    );

    testWithGame<ColourSequenceGame>(
      'lights a pad up when it is pressed',
      buildGame,
      (game) async {
        _watchPlayback(game);
        final pad = game.children.query<SequencePad>().first;

        game.pressPad(pad.index);

        expect(pad.isLit, isTrue);
      },
    );
  });

  group('mistakes', () {
    testWithGame<ColourSequenceGame>(
      'cost a life and replay the same sequence',
      buildGame,
      (game) async {
        _watchPlayback(game);
        final sequence = [...game.sequence];

        game.pressPad(_wrongPad(game));

        expect(game.lives, equals(ColourSequenceGame.maxLives - 1));
        expect(game.sequence, equals(sequence));
        expect(game.status, equals(SequenceStatus.showing));
      },
    );

    testWithGame<ColourSequenceGame>(
      'let the player carry on after the forgiven slip',
      buildGame,
      (game) async {
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        _watchPlayback(game);

        _answerCorrectly(game);

        expect(game.completedRounds, equals(1));
        expect(game.isGameOver, isFalse);
      },
    );

    testWithGame<ColourSequenceGame>(
      'end the run on the second one',
      buildGame,
      (
        game,
      ) async {
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        _watchPlayback(game);

        game.pressPad(_wrongPad(game));

        expect(game.lives, equals(0));
        expect(game.isGameOver, isTrue);
        expect(
          game.overlays.isActive(ColourSequenceGame.gameOverOverlayId),
          isTrue,
        );
      },
    );

    testWithGame<ColourSequenceGame>(
      'are ignored once the run is over',
      buildGame,
      (game) async {
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        _watchPlayback(game);
        game
          ..pressPad(_wrongPad(game))
          ..pressPad(game.sequence.first);

        expect(game.completedRounds, equals(0));
      },
    );
  });

  group('difficulty', () {
    testWithGame<ColourSequenceGame>(
      'shortens the flashes as the sequence grows',
      buildGame,
      (game) async {
        final startingFlash = game.flashSeconds;

        for (var i = 0; i < 5; i++) {
          _watchPlayback(game);
          _answerCorrectly(game);
        }

        expect(game.flashSeconds, lessThan(startingFlash));
      },
    );

    testWithGame<ColourSequenceGame>(
      'never lets the flashes reach zero',
      buildGame,
      (game) async {
        for (var i = 0; i < 40; i++) {
          _watchPlayback(game);
          _answerCorrectly(game);
        }

        expect(game.flashSeconds, greaterThan(0));
      },
    );
  });

  group('records', () {
    testWithGame<ColourSequenceGame>(
      'store the rounds repeated when the run ends',
      buildGame,
      (game) async {
        _watchPlayback(game);
        _answerCorrectly(game);
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        await game.ready();

        expect(
          records.read(
            ColourSequenceGame.recordGameId,
            ColourSequenceGame.recordMetric,
          ),
          equals(1),
        );
        expect(game.isNewRecord, isTrue);
      },
    );

    testWithGame<ColourSequenceGame>(
      'load the stored best when the game opens',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestRounds, equals(25));
      },
    );

    testWithGame<ColourSequenceGame>(
      'are not flagged for a shorter run',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        await game.ready();

        expect(game.isNewRecord, isFalse);
        expect(game.bestRounds, equals(25));
      },
    );
  });

  group('restart', () {
    testWithGame<ColourSequenceGame>(
      'returns to a fresh one pad sequence',
      buildGame,
      (game) async {
        _watchPlayback(game);
        _answerCorrectly(game);
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
        expect(game.isGameOver, isTrue);

        game.restart();

        expect(game.sequence, hasLength(1));
        expect(game.completedRounds, equals(0));
        expect(game.lives, equals(ColourSequenceGame.maxLives));
        expect(game.status, equals(SequenceStatus.showing));
        expect(
          game.overlays.isActive(ColourSequenceGame.gameOverOverlayId),
          isFalse,
        );
      },
    );
  });

  group('rewarded continue', () {
    testWithGame<ColourSequenceGame>(
      'gives a life back and replays the sequence it kept',
      buildGame,
      (game) async {
        _watchPlayback(game);
        _answerCorrectly(game);
        _watchPlayback(game);
        final rounds = game.completedRounds;
        final sequence = [...game.sequence];

        for (var i = 0; i < ColourSequenceGame.maxLives; i++) {
          game.pressPad(_wrongPad(game));
          _watchPlayback(game);
        }
        expect(game.isGameOver, isTrue);

        game.continueRun();

        expect(game.isGameOver, isFalse);
        expect(game.lives, equals(1));
        expect(game.completedRounds, equals(rounds));
        expect(game.sequence, equals(sequence));
        expect(
          game.status,
          equals(SequenceStatus.showing),
          reason: 'the player just lost the thread, so show it again',
        );
      },
    );

    testWithGame<ColourSequenceGame>('is sold only once a run', buildGame, (
      game,
    ) async {
      for (var i = 0; i < ColourSequenceGame.maxLives; i++) {
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
      }
      game.continueRun();
      expect(game.canContinue, isFalse);

      for (var i = 0; i < ColourSequenceGame.maxLives; i++) {
        _watchPlayback(game);
        game.pressPad(_wrongPad(game));
      }
      game.continueRun();

      expect(game.isGameOver, isTrue);
    });
  });
}
