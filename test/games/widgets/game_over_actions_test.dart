import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:sadagames/games/widgets/widgets.dart';

import '../../helpers/helpers.dart';

void main() {
  group('GameOverActions', () {
    testWidgets('asks for the between-runs ad before playing again', (
      tester,
    ) async {
      final ads = TestGameAds();
      var restarts = 0;

      await tester.pumpApp(
        Scaffold(
          body: GameOverActions(
            onPlayAgain: () => restarts++,
            wasNewRecord: false,
          ),
        ),
        ads: ads,
      );
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();

      expect(ads.requested, equals(['betweenRuns:false']));
      expect(restarts, equals(1));
    });

    testWidgets('tells the pacing that the run set a record', (tester) async {
      final ads = TestGameAds();

      await tester.pumpApp(
        Scaffold(
          body: GameOverActions(onPlayAgain: () {}, wasNewRecord: true),
        ),
        ads: ads,
      );
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();

      expect(ads.requested, equals(['betweenRuns:true']));
    });

    testWidgets('takes the ad break on the way back to the menu too', (
      tester,
    ) async {
      final ads = TestGameAds();
      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(navigator.pop).thenReturn(null);

      await tester.pumpApp(
        Scaffold(
          body: GameOverActions(onPlayAgain: () {}, wasNewRecord: false),
        ),
        ads: ads,
        navigator: navigator,
      );
      await tester.tap(find.text('Back to games'));
      await tester.pumpAndSettle();

      expect(ads.requested, equals(['betweenRuns:false']));
      verify(navigator.pop).called(1);
    });

    testWidgets('uses the label the game asked for', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: GameOverActions(
            onPlayAgain: () {},
            wasNewRecord: false,
            playAgainLabel: 'Shuffle again',
          ),
        ),
        ads: TestGameAds(),
      );

      expect(find.text('Shuffle again'), findsOneWidget);
    });
  });
}
