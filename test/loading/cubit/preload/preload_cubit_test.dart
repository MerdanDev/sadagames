import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flame/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/loading/loading.dart';

class _MockImages extends Mock implements Images {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(PreloadCubit, () {
    group('loadSequentially', () {
      late Images images;

      blocTest<PreloadCubit, PreloadState>(
        'loads assets',
        setUp: () {
          images = _MockImages();
          when(
            () => images.loadAll([Assets.images.unicornAnimation.path]),
          ).thenAnswer((invocation) => Future.value(<Image>[]));
        },
        build: () => PreloadCubit(images),
        act: (bloc) => bloc.loadSequentially(),
        expect: () => [
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals(''))
              .having((s) => s.totalCount, 'totalCount', equals(1)),
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals('images'))
              .having((s) => s.isComplete, 'isComplete', isFalse)
              .having((s) => s.loadedCount, 'loadedCount', equals(0)),
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals('images'))
              .having((s) => s.isComplete, 'isComplete', isTrue)
              .having((s) => s.loadedCount, 'loadedCount', equals(1)),
        ],
        verify: (bloc) {
          verify(
            () => images.loadAll([Assets.images.unicornAnimation.path]),
          ).called(1);
        },
      );
    });
  });
}
