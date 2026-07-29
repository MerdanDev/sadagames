import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/sliding_puzzle/sliding_puzzle.dart';
import 'package:sadagames/records/records.dart';

import '../../helpers/helpers.dart';

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
SlidingPuzzleGame _buildGameWith(GameRecords records) {
  return SlidingPuzzleGame(sounds: createTestSounds(), records: records)
    ..overlays.addEntry(
      SlidingPuzzleGame.solvedOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

/// Puts the board one move away from being solved.
void _setUpAlmostSolved(SlidingPuzzleGame game) {
  const last = SlidingPuzzleGame.tileCount;
  for (var slot = 0; slot < game.board.length; slot++) {
    game.board[slot] = slot + 1;
  }
  // Swap the final tile out to the empty slot.
  game.board[last - 1] = 0;
  game.board[last] = last;
}

void main() {
  late GameRecords records;
  late GameRecords recordsWithBest;

  setUp(() async {
    records = await createTestRecords();
  });

  setUp(() async {
    recordsWithBest = await createTestRecords({
      'record.${SlidingPuzzleGame.recordGameId}.'
              '${SlidingPuzzleGame.recordMetric}':
          1,
    });
  });

  SlidingPuzzleGame buildGame() => _buildGameWith(records);

  group('SlidingPuzzleGame', () {
    testWithGame<SlidingPuzzleGame>(
      'starts shuffled, unsolved and with no moves played',
      buildGame,
      (game) async {
        expect(game.moves, equals(0));
        expect(game.isSolved, isFalse);
        expect(game.board, hasLength(9));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'holds every tile exactly once plus the empty slot',
      buildGame,
      (game) async {
        final sorted = [...game.board]..sort();
        expect(sorted, equals([0, 1, 2, 3, 4, 5, 6, 7, 8]));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'moves a tile that sits next to the empty slot',
      buildGame,
      (game) async {
        final movableSlot = List.generate(
          game.board.length,
          (slot) => slot,
        ).firstWhere((slot) => game.canMoveSlot(slot) && game.board[slot] != 0);
        final value = game.board[movableSlot];
        final emptyBefore = game.emptySlot;

        expect(game.tryMoveValue(value), isTrue);

        expect(game.board[emptyBefore], equals(value));
        expect(game.emptySlot, equals(movableSlot));
        expect(game.moves, equals(1));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'refuses to move a tile that is not next to the empty slot',
      buildGame,
      (game) async {
        final blockedSlot =
            List.generate(
              game.board.length,
              (slot) => slot,
            ).firstWhere(
              (slot) => !game.canMoveSlot(slot) && game.board[slot] != 0,
            );
        final board = [...game.board];

        expect(game.tryMoveValue(game.board[blockedSlot]), isFalse);

        expect(game.board, equals(board));
        expect(game.moves, equals(0));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'marks the puzzle solved when the last tile slides home',
      buildGame,
      (game) async {
        _setUpAlmostSolved(game);

        expect(game.tryMoveValue(SlidingPuzzleGame.tileCount), isTrue);

        expect(game.isSolved, isTrue);
        expect(
          game.overlays.isActive(SlidingPuzzleGame.solvedOverlayId),
          isTrue,
        );
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'ignores moves once solved',
      buildGame,
      (game) async {
        _setUpAlmostSolved(game);
        game.tryMoveValue(SlidingPuzzleGame.tileCount);
        final movesWhenSolved = game.moves;

        expect(game.tryMoveValue(1), isFalse);
        expect(game.moves, equals(movesWhenSolved));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'restart reshuffles and clears the counters',
      buildGame,
      (game) async {
        _setUpAlmostSolved(game);
        game.tryMoveValue(SlidingPuzzleGame.tileCount);
        expect(game.isSolved, isTrue);

        game.restart();

        expect(game.isSolved, isFalse);
        expect(game.moves, equals(0));
        expect(game.secondsNotifier.value, equals(0));
        expect(
          game.overlays.isActive(SlidingPuzzleGame.solvedOverlayId),
          isFalse,
        );
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'shuffle never leaves the board already solved',
      buildGame,
      (game) async {
        for (var i = 0; i < 20; i++) {
          game.shuffle();
          final solvedOrder = [
            for (var slot = 0; slot < SlidingPuzzleGame.tileCount; slot++)
              slot + 1,
            0,
          ];
          expect(game.board, isNot(equals(solvedOrder)));
        }
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'stores the move count when the puzzle is solved',
      buildGame,
      (game) async {
        _setUpAlmostSolved(game);
        game.tryMoveValue(SlidingPuzzleGame.tileCount);
        await game.ready();

        expect(
          records.read(
            SlidingPuzzleGame.recordGameId,
            SlidingPuzzleGame.recordMetric,
          ),
          equals(1),
        );
        expect(game.isNewRecord, isTrue);
        expect(game.bestMoves, equals(1));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'keeps a better stored record when solved in more moves',
      () => _buildGameWith(recordsWithBest),
      (game) async {
        expect(game.bestMoves, equals(1));

        _setUpAlmostSolved(game);
        // Waste a couple of moves before finishing.
        game
          ..tryMoveValue(SlidingPuzzleGame.tileCount - 1)
          ..tryMoveValue(SlidingPuzzleGame.tileCount - 1)
          ..tryMoveValue(SlidingPuzzleGame.tileCount);
        await game.ready();

        expect(game.isNewRecord, isFalse);
        expect(game.bestMoves, equals(1));
      },
    );

    testWithGame<SlidingPuzzleGame>(
      'counts up the timer only after the first move',
      buildGame,
      (game) async {
        game.update(3);
        expect(game.secondsNotifier.value, equals(0));

        final movable = List.generate(game.board.length, (slot) => slot)
            .firstWhere(
              (slot) => game.canMoveSlot(slot) && game.board[slot] != 0,
            );
        game
          ..tryMoveValue(game.board[movable])
          ..update(3);

        expect(game.secondsNotifier.value, equals(3));
      },
    );
  });
}
