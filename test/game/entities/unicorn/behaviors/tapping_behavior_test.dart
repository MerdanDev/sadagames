import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/entities/unicorn/behaviors/behaviors.dart';
import 'package:sadagames/game/game.dart';
import 'package:sadagames/l10n/l10n.dart';

import '../../../../helpers/helpers.dart';

class _MockImages extends Mock implements Images {}

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _Sadagames extends Sadagames {
  _Sadagames({
    required super.l10n,
    required super.sounds,
    required super.textStyle,
    required super.images,
  });

  @override
  Future<void> onLoad() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TappingBehavior', () {
    late AppLocalizations l10n;
    late Images images;
    late SilentGameSounds sounds;

    Sadagames createFlameGame() {
      return _Sadagames(
        l10n: l10n,
        sounds: sounds,
        textStyle: const TextStyle(),
        images: images,
      );
    }

    setUpAll(() async {});

    setUp(() async {
      l10n = _MockAppLocalizations();
      when(() => l10n.counterText(any())).thenReturn('counterText');

      sounds = createTestSounds();

      images = _MockImages();
      final image = await _fakeImage();
      when(() => images.fromCache(any())).thenReturn(image);
    });

    FlameTester(createFlameGame).testGameWidget(
      'when tapped, starts playing the animation',
      setUp: (game, tester) async {
        await game.ensureAdd(
          Unicorn.test(
            position: Vector2.zero(),
            behaviors: [TappingBehavior()],
          ),
        );
      },
      verify: (game, tester) async {
        await tester.tapAt(Offset.zero);

        /// Flush long press gesture timer
        game.pauseEngine();
        await tester.pumpAndSettle();
        game
          ..resumeEngine()
          ..update(0.1);

        final unicorn = game.firstChild<Unicorn>()!;
        expect(unicorn.animationTicker.currentIndex, equals(1));
        expect(unicorn.isAnimationPlaying(), equals(true));

        expect(sounds.played, contains('tap'));
      },
    );
  });
}

Future<Image> _fakeImage() async {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  return picture.toImage(1, 1);
}
