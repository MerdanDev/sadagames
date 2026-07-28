import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/records/records.dart';

import '../helpers/helpers.dart';

void main() {
  group('GameRecords', () {
    late GameRecords records;

    setUp(() async {
      records = await createTestRecords();
    });

    test('reads null before a game has ever ended', () {
      expect(records.read('star_catcher', 'score'), isNull);
    });

    test('counts the first result as a record', () async {
      final isRecord = await records.submit(
        'star_catcher',
        'score',
        7,
        goal: RecordGoal.higher,
      );

      expect(isRecord, isTrue);
      expect(records.read('star_catcher', 'score'), equals(7));
    });

    group('with a higher-is-better goal', () {
      test('stores a bigger result', () async {
        await records.submit('g', 'score', 5, goal: RecordGoal.higher);

        final isRecord = await records.submit(
          'g',
          'score',
          9,
          goal: RecordGoal.higher,
        );

        expect(isRecord, isTrue);
        expect(records.read('g', 'score'), equals(9));
      });

      test('keeps the best when a smaller result comes in', () async {
        await records.submit('g', 'score', 9, goal: RecordGoal.higher);

        final isRecord = await records.submit(
          'g',
          'score',
          4,
          goal: RecordGoal.higher,
        );

        expect(isRecord, isFalse);
        expect(records.read('g', 'score'), equals(9));
      });
    });

    group('with a lower-is-better goal', () {
      test('stores a smaller result', () async {
        await records.submit('g', 'moves', 40, goal: RecordGoal.lower);

        final isRecord = await records.submit(
          'g',
          'moves',
          22,
          goal: RecordGoal.lower,
        );

        expect(isRecord, isTrue);
        expect(records.read('g', 'moves'), equals(22));
      });

      test('keeps the best when a bigger result comes in', () async {
        await records.submit('g', 'moves', 22, goal: RecordGoal.lower);

        final isRecord = await records.submit(
          'g',
          'moves',
          58,
          goal: RecordGoal.lower,
        );

        expect(isRecord, isFalse);
        expect(records.read('g', 'moves'), equals(22));
      });
    });

    test('keeps records of different games and metrics apart', () async {
      await records.submit(
        'star_catcher',
        'score',
        12,
        goal: RecordGoal.higher,
      );
      await records.submit(
        'sliding_puzzle',
        'moves',
        30,
        goal: RecordGoal.lower,
      );

      expect(records.read('star_catcher', 'score'), equals(12));
      expect(records.read('sliding_puzzle', 'moves'), equals(30));
      expect(records.read('star_catcher', 'moves'), isNull);
    });

    test('reads a record left behind by an earlier launch', () async {
      final reloaded = await createTestRecords({'record.g.score': 15});

      expect(reloaded.read('g', 'score'), equals(15));
    });
  });
}
