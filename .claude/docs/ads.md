# Ads

AdMob, through `google_mobile_ads`. Three formats, each in one place:

| Format | Where | Unit |
|---|---|---|
| Banner | anchored below the menu list | `menuBanner` |
| Interstitial | leaving a finished run | `runEndedInterstitial` |
| Rewarded | game over panels | `reward` |

No app-open ads and no rewarded interstitials, by choice. App-open ads are brutal on an app
people open for a twenty-second session, and a rewarded interstitial is just an interstitial
wearing a consent screen — it earns less than a real opt-in reward and is a second full screen
format to keep alive.

## Layout

- `lib/ads/ad_units.dart` — the unit ids, per platform and per flavor
- `lib/ads/ad_pacing.dart` — when an interstitial is allowed. Pure logic, so it is the part
  that is actually tested
- `lib/ads/game_ads.dart` — the `GameAds` interface, the AdMob implementation, `NoGameAds`
- `lib/ads/view/` — `MenuBanner`, `RewardedButton`, and the `duringAdBreak` helper
- `lib/games/widgets/game_over_actions.dart` — the shared "play again / back to games" pair,
  which is where the interstitial is triggered

`GameAds` is built once before `runApp` and shared through `RepositoryProvider`, the same as
`GameRecords`, `GameSettings` and `GameSounds`. `startAds` deliberately returns synchronously
and starts the SDK in the background: gathering consent can put a form in front of the player,
and start up must not sit behind that.

## Ids

The AdMob app id lives in `AndroidManifest.xml` and `Info.plist` — the native SDK reads it
before any Dart runs, and a missing or mismatched value crashes on launch. Only the *units*
are in Dart.

Android is live under app id `ca-app-pub-3745366747328031~8813478913`. **iOS is not
registered yet**: `AdUnits.liveIos` falls back to Google's test units and `Info.plist` carries
Google's test app id, so an iOS release currently serves ads that earn nothing. Registering the
iOS app means putting its three units in `AdUnits.liveIos` and its app id in `Info.plist`.

Development and staging always use test units (`startAds(isLive: false)` in `main_*.dart`).
This is a safety rail, not a convenience: showing yourself a live ad is invalid traffic, and
invalid traffic is what gets AdMob accounts suspended. `AdUnits.of` keys off the flavor, not
`kReleaseMode`, so a release build of the development flavor still serves test ads.

## Pacing

Runs here last ten seconds to a couple of minutes, so "an interstitial on every game over"
would fire every half minute and drive players off. `AdPacing` makes it rare — three runs and
three minutes between ads, two minutes of quiet after a rewarded ad, and never on a run that
set a personal best. Tune those four constants together; they only make sense as a set.

The interstitial fires when the player *leaves* a finished run, never over the game over panel
itself, which they are still reading.

## Rewards

Every game offers exactly **one** rewarded continue per run (`maxContinues`). A run the player
can keep buying back stops being a run, and the record it sets stops meaning anything. A
revived run does count for the personal best — the record was already banked when the run first
ended, so continuing can only beat it.

| Game | Reward | Method |
|---|---|---|
| Star Catcher, Odd One Out, Colour Sequence | a life back | `continueRun` |
| Block Fit | clears the fullest lines until a piece fits | `clearForContinue` |
| Merge Tiles | takes the lowest tile off the board | `removeTileForContinue` |

Each one hands back the *position*, not a fresh set of tools, and scores nothing: a line or a
tile the player did not earn must not move the number they are trying to beat. Each also does
the small favour that makes the bought life real — Star Catcher sweeps the sky so the new life
is not spent on a star already landing, Odd One Out resets the clock to full, Colour Sequence
replays the sequence the player just lost track of.

`RewardedButton` renders **nothing** unless an ad is loaded and the game still has an offer
left, so a player never taps a deal the app cannot honour. Pages call `loadReward()` in
`initState` so the ad is warm by the time the run ends; loading at game over would show a
button that appears seconds late.

## Gotchas

- **The plugin cannot run under `flutter test`.** Its platform channels do not exist there, so
  every test goes through `NoGameAds` (via `pumpApp`) or `TestGameAds` (`test/helpers/`).
  Anything worth asserting on therefore has to live outside `AdMobGameAds` — which is why
  `AdPacing` is a separate, pure class.
- **A full screen ad takes the screen but not the audio session.** Without `duringAdBreak` the
  game keeps ticking and its notes play under the ad. It restores the mute to whatever the
  player had chosen, never to "on".
- **Consent (UMP) must resolve before the first ad request.** `canRequestAds()` decides, not our
  own flags — outside the EEA it is true without a form ever appearing. iOS also needs the ATT
  prompt (`NSUserTrackingUsageDescription`); without it ads still serve, they just pay less.
- **`app-ads.txt`** has to be published on the developer domain listed in the Play/App Store
  entry, or a large share of demand refuses to bid. It lives in a separate repo,
  `MerdanDev/MerdanDev.github.io`, because a crawler only reads the *host root* and a project
  Pages site always publishes under the repo name — see [PAGES.md](../../PAGES.md). Nothing in
  it is secret: the publisher id is in every unit id above and in every shipped APK, and
  `f08c47fec0942fa0` is Google's TAG id, identical for every AdMob publisher.
- Banners are on the menu and nowhere else. Game canvases run edge to edge, and a banner next
  to a tap target invites the mis-taps AdMob counts as invalid traffic.
- **`google_mobile_ads` must be 9.x — never downgrade it.** Every version through 6.0.0
  configures with `configurations.all`, which Gradle 9 removed, so they fail at *configuration*
  time with `Could not get unknown property 'all' for configuration container for project
  ':google_mobile_ads'`, before a line of Dart compiles. 9.0.0 switched to `configurations.any`.
  The wrapper here is Gradle 9.4.1.
- 9.x deprecated `AdSize.getAnchoredAdaptiveBannerAdSize` in favour of
  `getLargeAnchoredAdaptiveBannerAdSizeWithOrientation`, which is what the banner uses.
- Check `ios/Runner.xcodeproj` against the SDK's minimum deployment target on the first iOS
  build; the project sits at 13.0 and has never been built against the ads SDK.
