import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  group('SilentGameSounds', () {
    test('records the cue a game asked for', () {
      final sounds = createTestSounds()
        ..note(3)
        ..tap()
        ..fail()
        ..win();

      expect(sounds.played, equals(['note:3', 'tap', 'fail', 'win']));
    });

    test('records the music being started and stopped', () {
      final sounds = createTestSounds()
        ..startMusic()
        ..stopMusic();

      expect(sounds.played, equals(['music:start', 'music:stop']));
    });

    test('remembers being muted', () {
      final sounds = createTestSounds()..setMuted(isMuted: true);

      expect(sounds.isMuted, isTrue);
    });
  });
}
