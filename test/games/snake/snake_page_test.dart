import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/snake/snake.dart';

import '../../helpers/helpers.dart';

void main() {
  group('SnakePage', () {
    testWidgets('starts the music with the page', (tester) async {
      final sounds = createTestSounds();

      await tester.pumpApp(const SnakePage(), sounds: sounds);

      expect(sounds.played, contains('music:start'));
    });

    testWidgets('stops the music when the page goes away', (tester) async {
      final sounds = createTestSounds();
      await tester.pumpApp(const SnakePage(), sounds: sounds);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(sounds.played, contains('music:stop'));
    });
  });
}
