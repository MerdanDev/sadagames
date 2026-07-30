import 'package:flutter/foundation.dart';
import 'package:sadagames/ads/ads.dart';

/// Ads that never touch the network, with every outcome a test needs to set.
///
/// The real service needs the plugin's platform channels, which do not exist
/// under `flutter test`, so this stands in wherever a widget reads [GameAds].
class TestGameAds implements GameAds {
  TestGameAds({bool isRewardReady = true, this.doesEarnReward = true})
    : isRewardReady = ValueNotifier(isRewardReady);

  /// Whether watching the ad through to the end earns the reward. `false` is
  /// the player closing it early.
  final bool doesEarnReward;

  @override
  final ValueNotifier<bool> isRewardReady;

  @override
  final ValueListenable<bool> isReady = ValueNotifier(true);

  @override
  String get menuBannerUnitId => 'test-banner';

  /// What the app asked for, in order.
  final List<String> requested = [];

  @override
  void loadReward() => requested.add('reward:load');

  @override
  Future<bool> showReward() async {
    requested.add('reward:show');
    isRewardReady.value = false;
    return doesEarnReward;
  }

  @override
  Future<void> showBetweenRuns({required bool wasNewRecord}) async {
    requested.add('betweenRuns:$wasNewRecord');
  }

  @override
  Future<void> dispose() async {}
}
