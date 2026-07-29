# Sadagames — agent guide

**What it is:** A collection of small mobile games behind one menu. Players open the app, pick
a game from the list, and play a short session.
**Stack:** Flutter 3.44 / Dart 3.12 (pinned by FVM), Flame for the games, flutter_bloc for app
state, very_good_analysis for lints. Android + iOS.

## Commands

Every command must run through `fvm` — see Gotchas.

| Task | Command |
|---|---|
| Install | `fvm flutter pub get` |
| Run (dev) | `fvm flutter run --flavor development -t lib/main_development.dart` |
| Test | `fvm flutter test` |
| Lint | `fvm flutter analyze` |
| Format | `fvm dart format lib test` |
| Regenerate l10n | `fvm flutter gen-l10n` |
| Regenerate app icons | `fvm dart run flutter_launcher_icons` |

## Layout

- `lib/games/<game>/` — one directory per game: `<game>_game.dart`, `components/`, `view/`
- `lib/games/game_catalog.dart` — the list that drives the menu
- `lib/menu/` — the game list screen
- `lib/records/` — personal bests (shared_preferences) plus the shared record widget
- `lib/progress/` — interrupted runs, so a long game can be picked back up
- `lib/settings/` — player preferences that outlive a run (currently the mute switch)
- `lib/ads/` — AdMob: the banner, the between-runs interstitial and the rewarded continue
- `lib/audio/` — the synthesised sound engine, shared app wide
- `lib/game/` — the template's original unicorn demo, kept as a catalog entry
- `lib/loading/` — the preload screen that runs before the menu
- `lib/gen/`, `lib/l10n/gen/` — generated; never edit by hand

## Architecture

Flow is Loading → Menu → a game; there is no title screen. The menu renders whatever `GameCatalog.entries`
contains, so **adding a game is one `const` entry plus its own directory** — no menu changes.

Each game is a `FlameGame` (simulation, drawing, input) paired with a page widget (Flutter
chrome). The game exposes `ValueNotifier`s for score-like values and the page renders them as
the HUD; the game never builds widgets. End-of-run panels are Flame overlays registered in the
page's `overlayBuilderMap`. `AudioCubit` is created per page but owns only the mute switch.

`GameRecords`, `GameSettings`, `GameSounds`, `GameProgress` and `GameAds` are built once before
`runApp` and shared through `RepositoryProvider`. Record reads are synchronous on purpose, so a game knows whether a run was
a record *before* showing its overlay and lets the write settle in the background — never block
the end-of-run panel on I/O.

## Conventions

- Barrel files at every level (`components/components.dart`, `<game>/<game>.dart`)
- Game logic tests use `testWithGame` with a factory that stubs the overlay and passes
  `createTestSounds()`, which records cues instead of making noise
- l10n (`lib/l10n/arb/app_en.arb`) for app chrome; game names and in-game copy are plain
  strings in the catalog and game files
- Commit style: imperative subject, blank line, bullets explaining why

## Gotchas

- **Use `fvm flutter`, never bare `flutter`.** The system Flutter on this machine is 3.41.9
  (Dart 3.11.5) and is too old for this project — `very_good` hooks require Dart `^3.12.0`.
  `.fvmrc` pins stable; other repos in `~/development` intentionally stay on the system SDK.
- `overlays.add` asserts the overlay builder is registered, which only `GameWidget` does at
  runtime. Tests must call `overlays.addEntry(...)` when building the game.
- **There are no audio files.** Every cue is synthesised by `flutter_soloud` in `lib/audio/`.
  Games ask for what happened — `note`, `tap`, `fail`, `win` — never for a sound, so the whole
  collection can be retuned in one place. Notes come from a pentatonic scale, which is what
  keeps any order the player produces consonant. SoLoud holds frequency on the *source*, so
  each note owns an oscillator; sharing one would make overlapping notes steal each other's
  pitch. There is no background music, by choice.
- **Cubits must not import `package:flutter/...`** — bloc lint fails CI on it. Reach for
  `package:meta/meta.dart` for `@immutable` / `@visibleForTesting` and write function types out
  rather than borrowing Flutter's typedefs. `avoid_public_fields` is deliberately off in
  `analysis_options.yaml`: cubits take collaborators as final fields, which is not state.
- A damaged local NDK fails Gradle *configuration* with `[CXX1101] ... did not have a
  source.properties file`, naming a version the SDK Manager left half-downloaded. Point
  `sadagames.ndkVersion` (in `~/.gradle/gradle.properties`) or `SADAGAMES_NDK_VERSION` at an
  install that has `source.properties`. Unset by default, so CI keeps its own SDK's default.
  The override in `android/build.gradle.kts` covers *every* module, not just `:app` — plugins
  that build native code resolve their own AGP default, so an app-level pin never reaches them.
- CI enforces a **coverage floor of 55%** (`min_coverage` in `.github/workflows/main.yaml`,
  against a real figure of 56.5%). Ratchet it up as coverage improves; never down to pass a run.
- Game pages deliberately have **no** `SafeArea` around `GameWidget` — the canvas is
  edge-to-edge and only the HUD row is inset. Don't "fix" this by wrapping the whole page.
  Content drawn *inside* Flame gets no such inset, so anything pinned to an edge has to be
  offset by hand: `Sadagames.safeArea` takes the insets from the view. Guard any such setter
  with `hasLayout` — the view passes them down before the game has a `size`.

## Decisions

- Every game is reachable only through `GameCatalog` — no direct routes from the title screen,
  so the menu stays the single source of truth.
- New games must meet the engagement bar in `.claude/docs/game-engagement.md` — the collection
  lives or dies on whether individual games are fun in the first ten seconds.
- Keep the unicorn demo in the catalog until there are enough real games to replace it.

## Deeper notes

- `.claude/docs/games/` — one file per game: how it plays, how it gets harder, how a player
  claws a run back, and which constant to reach for when it feels wrong. Read the one you are
  touching, not the rest; `games/README.md` is the index.
- `.claude/docs/game-engagement.md` — required checklist and patterns for building a new game.
  Read it before writing any new game.
- `.claude/docs/game-backlog.md` — planned games in build order, plus cross-cutting work. Read
  it when picking what to build next; tick entries off as they ship.
- `.claude/docs/ads.md` — which AdMob format goes where, how rarely the interstitial fires, and
  what each game's rewarded continue hands back. Read it before touching `lib/ads/` or a game
  over panel.

---

## Working rules for agents

This file is the map for this repo. Trust it as the starting point — don't re-survey what it
already answers. But verify a specific before relying on it; if a path, command, or version has
drifted, fix it here as part of your change. A doc that lies costs more than no doc.

**Keep it current in the same change that makes it stale** — new command, moved module, changed
convention, discovered gotcha. Never leave it for later.

- Corrections and durable facts → the section above where they belong.
- Over ~30 lines, or specific to one subsystem → `.claude/docs/<topic>.md`, linked under
  **Deeper notes** with a one-line hook. Load those only when touching that area.
- Prune as readily as you add. Delete what's no longer true.
- This is an index, not an encyclopedia. Past ~100 lines, the excess belongs in `.claude/docs/`.
