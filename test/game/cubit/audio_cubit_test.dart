import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadagames/game/cubit/cubit.dart';

import '../../helpers/helpers.dart';

class _MockAudioCache extends Mock implements AudioCache {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  group('AudioCubit', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late AudioCache audioCache;
    late AudioPlayer effectPlayer;

    setUp(() {
      audioCache = _MockAudioCache();
      effectPlayer = _MockAudioPlayer();
      when(() => effectPlayer.audioCache).thenReturn(audioCache);
      when(effectPlayer.dispose).thenAnswer((_) async {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'),
            (_) => null,
          );
    });

    test('can be instantiated', () async {
      when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});

      expect(
        AudioCubit(
          audioPlayer: effectPlayer,
          settings: await createTestSettings(),
        ),
        isA<AudioCubit>(),
      );
    });

    test('starts unmuted when nothing was saved', () async {
      when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});

      final cubit = AudioCubit(
        audioPlayer: effectPlayer,
        settings: await createTestSettings(),
      );

      expect(cubit.state.volume, equals(1));
    });

    test('starts muted when the player muted it last time', () async {
      when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});

      final cubit = AudioCubit(
        audioPlayer: effectPlayer,
        settings: await createTestSettings(isMuted: true),
      );

      expect(cubit.state.volume, equals(0));
    });

    test('silences the players as soon as it is built while muted', () async {
      when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});

      AudioCubit(
        audioPlayer: effectPlayer,
        settings: await createTestSettings(isMuted: true),
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => effectPlayer.setVolume(0)).called(1);
    });

    test('remembers a mute for the next time', () async {
      when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});
      final settings = await createTestSettings();

      final cubit = AudioCubit.test(
        effectPlayer: effectPlayer,
        settings: settings,
      );
      await cubit.toggleVolume();

      expect(settings.isMuted, isTrue);
    });

    test('remembers unmuting too', () async {
      when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});
      final settings = await createTestSettings(isMuted: true);

      final cubit = AudioCubit.test(
        effectPlayer: effectPlayer,
        settings: settings,
        volume: 0,
      );
      await cubit.toggleVolume();

      expect(settings.isMuted, isFalse);
    });

    blocTest<AudioCubit, AudioState>(
      'toggleVolume mutes the volume when the volume is not 0',
      setUp: () {
        when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});
      },
      build: () => AudioCubit.test(effectPlayer: effectPlayer),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => effectPlayer.setVolume(any(that: equals(0)))).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume unmutes the volume when the volume is 0',
      setUp: () {
        when(() => effectPlayer.setVolume(any())).thenAnswer((_) async {});
      },
      build: () {
        return AudioCubit.test(effectPlayer: effectPlayer, volume: 0);
      },
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState()],
      verify: (_) {
        verify(() => effectPlayer.setVolume(any(that: equals(1)))).called(1);
      },
    );
  });
}
