import 'package:meta/meta.dart';

/// Decides when a between-runs interstitial is allowed to interrupt.
///
/// Runs in this collection are short — ten seconds to a couple of minutes — so
/// the obvious rule, an ad on every game over, would fire every half minute
/// and drive players off. Everything here exists to make the ad rare: it is
/// the price of a *session*, not of a run.
///
/// Pure logic on purpose. The plugin cannot run under `flutter test`, so the
/// part worth getting right is the part that does not need it.
class AdPacing {
  AdPacing({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  /// Finished runs between one interstitial and the next. Because the counter
  /// starts at zero, this is also how many runs a player gets for free when
  /// the app opens.
  static const runsBetweenAds = 3;

  /// Wall-clock gap enforced on top of the run count, so a burst of very short
  /// runs cannot pull the next ad forward.
  static const gapBetweenAds = Duration(minutes: 3);

  /// Quiet period after the player watches a rewarded ad. Following an ad they
  /// *chose* with one they did not is the fastest way to sour the trade.
  static const quietAfterReward = Duration(minutes: 2);

  final DateTime Function() _now;

  int _runsSinceLastAd = 0;
  DateTime? _lastInterstitial;
  DateTime? _lastReward;

  @visibleForTesting
  int get runsSinceLastAd => _runsSinceLastAd;

  /// Records that a run finished.
  void onRunEnded() => _runsSinceLastAd++;

  /// Records that the player watched a rewarded ad.
  void onRewardShown() => _lastReward = _now();

  /// Records that an interstitial was shown, restarting both counters.
  void onInterstitialShown() {
    _runsSinceLastAd = 0;
    _lastInterstitial = _now();
  }

  /// Whether an interstitial may be shown right now.
  ///
  /// [isAfterNewRecord] suppresses it: a personal best is the one moment a
  /// player is enjoying, and covering it with an ad trades a habit for a cent.
  bool allowsInterstitial({required bool isAfterNewRecord}) {
    if (isAfterNewRecord) return false;
    if (_runsSinceLastAd < runsBetweenAds) return false;

    final now = _now();
    final sinceLast = _lastInterstitial;
    if (sinceLast != null && now.difference(sinceLast) < gapBetweenAds) {
      return false;
    }

    final sinceReward = _lastReward;
    if (sinceReward != null && now.difference(sinceReward) < quietAfterReward) {
      return false;
    }

    return true;
  }
}
