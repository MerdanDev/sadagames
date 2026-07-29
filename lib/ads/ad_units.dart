import 'package:flutter/foundation.dart';

/// The AdMob unit ids the app asks for ads with, for one platform.
///
/// The *app* id is deliberately absent: the native SDK reads it straight out
/// of `AndroidManifest.xml` and `Info.plist` before any Dart runs, so it lives
/// there and nowhere else. Changing the units here without changing the app id
/// there is the usual reason ads go quiet.
@immutable
class AdUnits {
  const AdUnits({
    required this.menuBanner,
    required this.runEndedInterstitial,
    required this.reward,
  });

  /// Anchored banner under the game list.
  final String menuBanner;

  /// Full screen ad shown between runs, paced by `AdPacing`.
  final String runEndedInterstitial;

  /// Opt-in ad that buys a retry or a cleared tile.
  final String reward;

  /// Google's public test units, which serve real-looking ads that earn
  /// nothing and count against nothing.
  ///
  /// Every build but production uses these. Showing yourself a live unit is
  /// invalid traffic, and invalid traffic is what gets AdMob accounts
  /// suspended — so this is a safety rail, not a convenience.
  static const testAndroid = AdUnits(
    menuBanner: 'ca-app-pub-3940256099942544/6300978111',
    runEndedInterstitial: 'ca-app-pub-3940256099942544/1033173712',
    reward: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const testIos = AdUnits(
    menuBanner: 'ca-app-pub-3940256099942544/2934735716',
    runEndedInterstitial: 'ca-app-pub-3940256099942544/4411468910',
    reward: 'ca-app-pub-3940256099942544/1712485313',
  );

  /// The live units, from the AdMob app
  /// `ca-app-pub-3745366747328031~8813478913`.
  ///
  /// The reward unit is the one named "Retry": quantity 1, reward name
  /// `reward`. Nothing reads the quantity — a retry is a retry — but AdMob
  /// requires the unit to declare one.
  static const liveAndroid = AdUnits(
    menuBanner: 'ca-app-pub-3745366747328031/8171883453',
    runEndedInterstitial: 'ca-app-pub-3745366747328031/7796599070',
    reward: 'ca-app-pub-3745366747328031/7097906713',
  );

  /// AdMob issues a separate app id and a separate set of units per platform,
  /// and only the one set above exists so far.
  // TODO(merdan): register the iOS app in AdMob, then put its three units here
  // and its app id in `ios/Runner/Info.plist`. Until then an iOS release
  // serves test ads, which earn nothing.
  static const AdUnits liveIos = testIos;

  /// The units this build should use.
  ///
  /// [isLive] comes from the flavor rather than from `kReleaseMode`, so a
  /// release build of the development flavor still serves test ads.
  static AdUnits of({required bool isLive}) {
    // defaultTargetPlatform rather than dart:io, so a widget test can pick a
    // platform instead of inheriting the host's.
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (isLive) return isIos ? liveIos : liveAndroid;
    return isIos ? testIos : testAndroid;
  }
}
