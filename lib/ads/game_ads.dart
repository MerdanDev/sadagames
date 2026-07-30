import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sadagames/ads/ad_pacing.dart';
import 'package:sadagames/ads/ad_units.dart';

/// The ads shown around the games.
///
/// Built once before `runApp` and shared through `RepositoryProvider`, the
/// same as `GameRecords` and `GameSounds`.
///
/// Nothing here ever blocks a player. An ad that has not loaded is simply not
/// offered, which is why [isRewardReady] exists: a "keep playing" button that
/// spins and then fails is worse than no button at all.
abstract class GameAds {
  /// Whether the SDK is up and consent allows requesting ads at all.
  ValueListenable<bool> get isReady;

  /// Whether a rewarded ad is loaded and could be shown this instant.
  ValueListenable<bool> get isRewardReady;

  /// The banner unit for the menu.
  String get menuBannerUnitId;

  /// Asks for the next rewarded ad. Call when a game page opens, so the ad is
  /// waiting by the time the run ends.
  void loadReward();

  /// Shows the rewarded ad, resolving to whether the player earned the reward.
  ///
  /// `false` covers every way this can go wrong — no ad loaded, the ad failed
  /// to show, the player closed it early — so callers only need one branch.
  Future<bool> showReward();

  /// Shows the between-runs interstitial when [AdPacing] allows one.
  ///
  /// Call at the moment the player *leaves* a finished run, tapping "play
  /// again" or heading back to the menu — never over the game over panel
  /// itself, which is still an interaction the player is in the middle of.
  Future<void> showBetweenRuns({required bool wasNewRecord});

  Future<void> dispose();
}

/// Builds the ads service and kicks its start up off in the background.
///
/// Deliberately not a `Future`: gathering consent can put a form in front of
/// the player, and start up must not sit behind that. Callers get a service
/// that reports itself not ready until it is.
///
/// [isLive] comes from the flavor — see [AdUnits.of].
GameAds startAds({required bool isLive}) {
  final ads = AdMobGameAds(units: AdUnits.of(isLive: isLive));
  unawaited(ads.start());
  return ads;
}

/// [GameAds] backed by AdMob.
class AdMobGameAds implements GameAds {
  AdMobGameAds({required this.units, AdPacing? pacing})
    : _pacing = pacing ?? AdPacing();

  final AdUnits units;
  final AdPacing _pacing;

  final ValueNotifier<bool> _isReady = ValueNotifier(false);
  final ValueNotifier<bool> _isRewardReady = ValueNotifier(false);

  RewardedAd? _reward;
  InterstitialAd? _interstitial;

  bool _isLoadingReward = false;
  bool _isLoadingInterstitial = false;
  bool _isShowingAd = false;

  @override
  ValueListenable<bool> get isReady => _isReady;

  @override
  ValueListenable<bool> get isRewardReady => _isRewardReady;

  @override
  String get menuBannerUnitId => units.menuBanner;

  /// Gathers consent, brings the SDK up and warms the first ads.
  ///
  /// Start up never awaits this. Consent can involve a form the player reads,
  /// and holding the loading screen behind that would be a poor first run;
  /// the menu renders without a banner and the banner appears when it lands.
  Future<void> start() async {
    try {
      await _gatherConsent();
      // The consent state decides this, not our own flags: outside the EEA it
      // is true without a form ever appearing.
      if (!await ConsentInformation.instance.canRequestAds()) return;

      await MobileAds.instance.initialize();
      _isReady.value = true;
      loadReward();
      _loadInterstitial();
    } on Object catch (error, stackTrace) {
      // A broken ads stack must never take the games down with it.
      log('ads failed to start: $error', stackTrace: stackTrace);
    }
  }

  Future<void> _gatherConsent() {
    final gathered = Completer<void>();
    void finish() {
      if (!gathered.isCompleted) gathered.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        finish();
      },
      // A failure here is not fatal. canRequestAds is checked either way and
      // stays true where no consent is required.
      (_) => finish(),
    );

    return gathered.future;
  }

  @override
  void loadReward() {
    if (!_isReady.value || _isLoadingReward || _reward != null) return;
    _isLoadingReward = true;

    unawaited(
      RewardedAd.load(
        adUnitId: units.reward,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadingReward = false;
            _reward = ad;
            _isRewardReady.value = true;
          },
          onAdFailedToLoad: (error) {
            // No retry loop: the next game page asks again, and hammering a
            // unit that is out of fill just burns battery.
            _isLoadingReward = false;
            _isRewardReady.value = false;
            log('rewarded ad failed to load: $error');
          },
        ),
      ),
    );
  }

  @override
  Future<bool> showReward() async {
    final ad = _reward;
    if (ad == null || _isShowingAd) return false;

    // Taken before showing: an ad is good for one impression, and leaving it
    // in the field would let a second tap show a stale one.
    _reward = null;
    _isRewardReady.value = false;
    _isShowingAd = true;

    final dismissed = Completer<bool>();
    var didEarn = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _pacing.onRewardShown();
        unawaited(ad.dispose());
        if (!dismissed.isCompleted) dismissed.complete(didEarn);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('rewarded ad failed to show: $error');
        unawaited(ad.dispose());
        if (!dismissed.isCompleted) dismissed.complete(false);
      },
    );

    await ad.show(onUserEarnedReward: (_, _) => didEarn = true);
    final earned = await dismissed.future;

    _isShowingAd = false;
    loadReward();
    return earned;
  }

  void _loadInterstitial() {
    if (!_isReady.value || _isLoadingInterstitial || _interstitial != null) {
      return;
    }
    _isLoadingInterstitial = true;

    unawaited(
      InterstitialAd.load(
        adUnitId: units.runEndedInterstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadingInterstitial = false;
            _interstitial = ad;
          },
          onAdFailedToLoad: (error) {
            _isLoadingInterstitial = false;
            log('interstitial failed to load: $error');
          },
        ),
      ),
    );
  }

  @override
  Future<void> showBetweenRuns({required bool wasNewRecord}) async {
    _pacing.onRunEnded();
    if (!_pacing.allowsInterstitial(isAfterNewRecord: wasNewRecord)) {
      // Still worth warming one for the run after next.
      _loadInterstitial();
      return;
    }

    final ad = _interstitial;
    if (ad == null || _isShowingAd) {
      _loadInterstitial();
      return;
    }

    _interstitial = null;
    _isShowingAd = true;
    _pacing.onInterstitialShown();

    final dismissed = Completer<void>();
    void finish(InterstitialAd ad) {
      unawaited(ad.dispose());
      if (!dismissed.isCompleted) dismissed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('interstitial failed to show: $error');
        finish(ad);
      },
    );

    await ad.show();
    await dismissed.future;

    _isShowingAd = false;
    _loadInterstitial();
  }

  @override
  Future<void> dispose() async {
    await _reward?.dispose();
    await _interstitial?.dispose();
    _reward = null;
    _interstitial = null;
    _isReady.dispose();
    _isRewardReady.dispose();
  }
}

/// [GameAds] that shows nothing.
///
/// Used by every test, and as the fallback when the SDK cannot start, so the
/// rest of the app has one shape to code against rather than a nullable
/// service and a null check at every call site.
class NoGameAds implements GameAds {
  /// Records what was asked for, so a test can assert on it.
  final List<String> requested = [];

  @override
  final ValueListenable<bool> isReady = ValueNotifier(false);

  @override
  final ValueListenable<bool> isRewardReady = ValueNotifier(false);

  @override
  String get menuBannerUnitId => '';

  @override
  void loadReward() => requested.add('reward:load');

  @override
  Future<bool> showReward() async {
    requested.add('reward:show');
    return false;
  }

  @override
  Future<void> showBetweenRuns({required bool wasNewRecord}) async {
    requested.add('betweenRuns:$wasNewRecord');
  }

  @override
  Future<void> dispose() async {}
}
