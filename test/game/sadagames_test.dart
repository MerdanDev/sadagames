import 'package:flame/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sadagames/game/game.dart';
import 'package:sadagames/l10n/l10n.dart';

import '../helpers/helpers.dart';

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockImages extends Mock implements Images {}

Sadagames _buildGame() {
  return Sadagames(
    l10n: _MockAppLocalizations(),
    sounds: createTestSounds(),
    textStyle: const TextStyle(),
    images: _MockImages(),
  );
}

void main() {
  group('Sadagames', () {
    test('starts with no safe area', () {
      expect(_buildGame().safeArea, equals(EdgeInsets.zero));
    });

    test('takes a safe area before the first layout without throwing', () {
      // The view passes the insets down while building, which happens before
      // the game has a size to lay the counter out against.
      final game = _buildGame();

      expect(
        () => game.safeArea = const EdgeInsets.only(bottom: 34),
        returnsNormally,
      );
      expect(game.safeArea, equals(const EdgeInsets.only(bottom: 34)));
    });
  });
}
