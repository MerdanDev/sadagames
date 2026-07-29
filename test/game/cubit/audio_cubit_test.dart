import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/game/cubit/cubit.dart';

import '../../helpers/helpers.dart';

void main() {
  group('AudioCubit', () {
    test('starts unmuted when nothing was saved', () async {
      final cubit = AudioCubit(
        sounds: createTestSounds(),
        settings: await createTestSettings(),
      );

      expect(cubit.state.volume, equals(1));
    });

    test('starts muted when the player muted it last time', () async {
      final cubit = AudioCubit(
        sounds: createTestSounds(),
        settings: await createTestSettings(isMuted: true),
      );

      expect(cubit.state.volume, equals(0));
    });

    test('silences the sounds as soon as it is built while muted', () async {
      final sounds = createTestSounds();

      AudioCubit(
        sounds: sounds,
        settings: await createTestSettings(isMuted: true),
      );

      expect(sounds.isMuted, isTrue);
    });

    test('leaves the sounds audible when it was not muted', () async {
      final sounds = createTestSounds();

      AudioCubit(sounds: sounds, settings: await createTestSettings());

      expect(sounds.isMuted, isFalse);
    });

    test('toggling mutes the sounds', () async {
      final sounds = createTestSounds();
      final cubit = AudioCubit(
        sounds: sounds,
        settings: await createTestSettings(),
      );

      await cubit.toggleVolume();

      expect(cubit.state.volume, equals(0));
      expect(sounds.isMuted, isTrue);
    });

    test('toggling back makes them audible again', () async {
      final sounds = createTestSounds();
      final cubit = AudioCubit(
        sounds: sounds,
        settings: await createTestSettings(isMuted: true),
      );

      await cubit.toggleVolume();

      expect(cubit.state.volume, equals(1));
      expect(sounds.isMuted, isFalse);
    });

    test('remembers a mute for the next time', () async {
      final settings = await createTestSettings();
      final cubit = AudioCubit.test(
        sounds: createTestSounds(),
        settings: settings,
      );

      await cubit.toggleVolume();

      expect(settings.isMuted, isTrue);
    });

    test('remembers unmuting too', () async {
      final settings = await createTestSettings(isMuted: true);
      final cubit = AudioCubit.test(
        sounds: createTestSounds(),
        settings: settings,
        volume: 0,
      );

      await cubit.toggleVolume();

      expect(settings.isMuted, isFalse);
    });
  });
}
