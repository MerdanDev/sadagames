import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/audio/audio.dart';

import '../../helpers/helpers.dart';

void main() {
  group('RewardedButton', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      required TestGameAds ads,
      required VoidCallback onReward,
      bool isOffered = true,
      GameSounds? sounds,
    }) {
      return tester.pumpApp(
        Scaffold(
          body: RewardedButton(
            label: 'Keep playing',
            isOffered: isOffered,
            onReward: onReward,
          ),
        ),
        ads: ads,
        sounds: sounds,
      );
    }

    testWidgets('shows nothing while no ad is loaded', (tester) async {
      await pumpButton(
        tester,
        ads: TestGameAds(isRewardReady: false),
        onReward: () {},
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('shows nothing once the run has spent its offer', (
      tester,
    ) async {
      await pumpButton(
        tester,
        ads: TestGameAds(),
        isOffered: false,
        onReward: () {},
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('names the ad on the button', (tester) async {
      await pumpButton(tester, ads: TestGameAds(), onReward: () {});

      expect(find.text('Keep playing (watch ad)'), findsOneWidget);
    });

    testWidgets('applies the reward once the ad is watched', (tester) async {
      final ads = TestGameAds();
      var rewards = 0;

      await pumpButton(tester, ads: ads, onReward: () => rewards++);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(ads.requested, contains('reward:show'));
      expect(rewards, equals(1));
    });

    testWidgets('leaves the run alone when the ad is closed early', (
      tester,
    ) async {
      final ads = TestGameAds(doesEarnReward: false);
      var rewards = 0;

      await pumpButton(tester, ads: ads, onReward: () => rewards++);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(ads.requested, contains('reward:show'));
      expect(rewards, isZero, reason: 'no reward was earned');
    });

    testWidgets('silences the app for the ad and restores the choice after', (
      tester,
    ) async {
      final sounds = createTestSounds();

      await pumpButton(
        tester,
        ads: TestGameAds(),
        onReward: () {},
        sounds: sounds,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Back to the player's own setting, which the test app leaves unmuted.
      expect(sounds.isMuted, isFalse);
    });
  });
}
