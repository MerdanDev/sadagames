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

## Layout

- `lib/games/<game>/` — one directory per game: `<game>_game.dart`, `components/`, `view/`
- `lib/games/game_catalog.dart` — the list that drives the menu
- `lib/menu/` — the game list screen
- `lib/records/` — personal bests (shared_preferences) plus the shared record widget
- `lib/game/` — the template's original unicorn demo, kept as a catalog entry
- `lib/loading/`, `lib/title/` — preload and splash flow that runs before the menu
- `lib/gen/`, `lib/l10n/gen/` — generated; never edit by hand

## Architecture

Flow is Loading → Title → Menu → a game. The menu renders whatever `GameCatalog.entries`
contains, so **adding a game is one `const` entry plus its own directory** — no menu changes.

Each game is a `FlameGame` (simulation, drawing, input) paired with a page widget (Flutter
chrome). The game exposes `ValueNotifier`s for score-like values and the page renders them as
the HUD; the game never builds widgets. End-of-run panels are Flame overlays registered in the
page's `overlayBuilderMap`. Audio comes from `AudioCubit`, created per game page.

`GameRecords` is loaded once before `runApp` and shared through a `RepositoryProvider`. Reads
are synchronous, so a game decides whether a run was a record *before* showing its overlay and
lets the write settle in the background — never block the end-of-run panel on I/O.

## Conventions

- Barrel files at every level (`components/components.dart`, `<game>/<game>.dart`)
- Game logic tests use `testWithGame` with a factory that stubs the overlay and audio player
- l10n (`lib/l10n/arb/app_en.arb`) for app chrome; game names and in-game copy are plain
  strings in the catalog and game files
- Commit style: imperative subject, blank line, bullets explaining why

## Gotchas

- **Use `fvm flutter`, never bare `flutter`.** The system Flutter on this machine is 3.41.9
  (Dart 3.11.5) and is too old for this project — `very_good` hooks require Dart `^3.12.0`.
  `.fvmrc` pins stable; other repos in `~/development` intentionally stay on the system SDK.
- `overlays.add` asserts the overlay builder is registered, which only `GameWidget` does at
  runtime. Tests must call `overlays.addEntry(...)` when building the game.
- Only two audio assets exist, and `effect.mp3` runs for **three seconds** — far longer than any
  game event. Always play sounds through `GameSounds` (`lib/audio/`), which trims the clip to a
  blip and pitches it. Two traps it exists to avoid: playing the raw clip drones over itself,
  and `setPlaybackRate` is silently dropped unless it is called *after* playback starts.
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

- `.claude/docs/game-engagement.md` — required checklist and patterns for building a new game.
  Read it before writing any new game.
- `.claude/docs/game-backlog.md` — planned games in build order, plus cross-cutting work. Read
  it when picking what to build next; tick entries off as they ship.

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
