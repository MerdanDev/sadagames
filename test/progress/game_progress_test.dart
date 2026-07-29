import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/helpers.dart';

void main() {
  group('GameProgress', () {
    late GameProgress progress;

    setUp(() async {
      progress = await createTestProgress();
    });

    test('reads nothing before a run is saved', () {
      expect(progress.read('block_fit'), isNull);
    });

    test('gives back what was saved', () async {
      await progress.save('block_fit', {'score': 42});

      expect(progress.read('block_fit'), equals({'score': 42}));
    });

    test('keeps games apart', () async {
      await progress.save('block_fit', {'score': 42});

      expect(progress.read('merge_tiles'), isNull);
    });

    test('forgets a run once it is cleared', () async {
      await progress.save('block_fit', {'score': 42});

      await progress.clear('block_fit');

      expect(progress.read('block_fit'), isNull);
    });

    test('treats an unreadable snapshot as no run at all', () async {
      SharedPreferences.setMockInitialValues({
        'progress.block_fit': 'not json',
      });
      final store = GameProgress(await SharedPreferences.getInstance());

      expect(store.read('block_fit'), isNull);
    });
  });
}
