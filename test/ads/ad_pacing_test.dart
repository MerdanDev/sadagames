import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/ads/ads.dart';

void main() {
  /// A clock the test moves by hand, so the gaps can be checked without
  /// waiting minutes for them.
  var now = DateTime(2026);

  setUp(() => now = DateTime(2026));

  AdPacing buildPacing() => AdPacing(clock: () => now);

  void endRuns(AdPacing pacing, int count) {
    for (var i = 0; i < count; i++) {
      pacing.onRunEnded();
    }
  }

  group('AdPacing', () {
    test('shows nothing before the run count is reached', () {
      final pacing = buildPacing();

      for (var runs = 0; runs < AdPacing.runsBetweenAds; runs++) {
        expect(
          pacing.allowsInterstitial(isAfterNewRecord: false),
          isFalse,
          reason: 'an ad was allowed after only $runs runs',
        );
        pacing.onRunEnded();
      }

      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isTrue);
    });

    test('suppresses the ad on a new personal best', () {
      final pacing = buildPacing()..onRunEnded();
      endRuns(pacing, AdPacing.runsBetweenAds);

      expect(pacing.allowsInterstitial(isAfterNewRecord: true), isFalse);
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isTrue);
    });

    test('restarts the run count once an ad is shown', () {
      final pacing = buildPacing();
      endRuns(pacing, AdPacing.runsBetweenAds);

      pacing.onInterstitialShown();

      expect(pacing.runsSinceLastAd, isZero);
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isFalse);
    });

    test('holds the wall-clock gap even when the runs pile up', () {
      final pacing = buildPacing();
      endRuns(pacing, AdPacing.runsBetweenAds);
      pacing.onInterstitialShown();

      // A burst of very short runs must not pull the next ad forward.
      endRuns(pacing, AdPacing.runsBetweenAds * 3);
      now = now.add(AdPacing.gapBetweenAds - const Duration(seconds: 1));
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isFalse);

      now = now.add(const Duration(seconds: 2));
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isTrue);
    });

    test('stays quiet for a while after a rewarded ad', () {
      final pacing = buildPacing();
      endRuns(pacing, AdPacing.runsBetweenAds);
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isTrue);

      // Following an ad the player chose with one they did not is exactly the
      // sequence this rule exists to prevent.
      pacing.onRewardShown();
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isFalse);

      now = now.add(AdPacing.quietAfterReward + const Duration(seconds: 1));
      expect(pacing.allowsInterstitial(isAfterNewRecord: false), isTrue);
    });
  });
}
