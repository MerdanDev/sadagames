import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/tile_tap/tile_tap.dart';

import '../../helpers/helpers.dart';

void main() {
  group('TileTapPage', () {
    testWidgets('starts the music with the page', (tester) async {
      final sounds = createTestSounds();

      await tester.pumpApp(const TileTapPage(), sounds: sounds);

      expect(sounds.played, contains('music:start'));
    });

    testWidgets('stops the music when the page goes away', (tester) async {
      final sounds = createTestSounds();
      await tester.pumpApp(const TileTapPage(), sounds: sounds);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(sounds.played, contains('music:stop'));
    });
  });
}
