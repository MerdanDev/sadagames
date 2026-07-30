# Building a game that people actually replay

Read before writing a new game in `lib/games/`. The rules below are requirements, not
suggestions — a game that misses them does not go in the catalog.

The bar: **a player who taps the game from the menu is playing within two seconds, understands
it without being told, and wants one more run when it ends.**

## The six requirements

### 1. Playable in two seconds

No splash, no tutorial screen, no "tap to start". The game is live the moment the page opens,
and the first interaction teaches the rule. If a game needs written instructions to be
understood, redesign it instead of writing instructions.

### 2. Every input answers back

Each tap, drag or move produces an immediate change the player can see *and* hear — motion,
scale, colour, sound. Never let an input land silently; silence reads as a bug.

Ask `GameSounds` for what happened — `note`, `tap`, `fail`, `win` — never for a particular
sound. Walk `note` up the scale as a streak grows, so a good run turns into a tune. Animate
state changes with Flame effects (`MoveToEffect`, `ScaleEffect`) rather than snapping positions.

### 3. Difficulty climbs with the player

A run must get harder the better the player does — faster, smaller, denser, tighter. A game
that plays the same at score 2 and score 40 is a demo, not a game. Tie the curve to score, and
clamp it so it stays possible.

### 4. A way back from the brink

Pure attrition (three lives, then done) ends runs on a downer. Give skilled players a way to
recover — a rare pickup, a bonus, a streak reward — and gate it so it appears only when it
matters (`Star Catcher` drops hearts only after the unlock score and only when a life is
missing).

### 5. A number to beat

Every game keeps a personal best through `GameRecords`, shown during play, called out on the
end screen, and displayed on the game's menu tile. A run the player cannot compare to anything
is a run they have no reason to repeat.

Pick the metric the game is actually about and the direction that counts as better
(`RecordGoal.higher` for a score, `RecordGoal.lower` for moves or time). Decide the record
synchronously with `beatsRecord` so the end screen is instant, then persist with `submit` in
the background.

### 6. A clean ending with one tap back in

Every run ends in an overlay that states the result in the player's terms ("You caught 12
stars", "18 moves in 41s"), offers restart as the primary button, and leaves the menu one tap
away. Restart must reset state fully without rebuilding the page.

## Presentation rules

- **Edge to edge.** The canvas fills the screen; only the HUD row sits in a `SafeArea`. Never
  wrap `GameWidget` in one.
- **HUD in Flutter, not Flame.** Expose `ValueNotifier`s from the game and render them with
  `ValueListenableBuilder`, so the HUD inherits theme, fonts and safe-area insets for free.
- **Show progress at all times.** Score, lives, moves, time — whatever the player is chasing is
  on screen during play, not only at the end.
- **Never signal with colour alone.** Lives are heart *shapes*, not red dots. Filled vs outline
  must carry the meaning too.
- **Tap targets at least 44pt.** Anything smaller fails on a phone in one hand.
- **Background music plus a volume toggle** on every game page, matching the other games.

## Definition of done

- [ ] Meets all six requirements above
- [ ] Registered as a `const GameCatalogEntry` with a name, one-line description, icon, colour
- [ ] `fvm flutter analyze` clean and `fvm dart format` applied
- [ ] Game logic covered by `testWithGame` tests: scoring, failure, difficulty ramp, restart,
      records, and any comeback mechanic
- [ ] Played once on a simulator before calling it finished — tests do not catch a board that
      renders off screen

## Reference implementations

- `lib/games/star_catcher/` — reflex game: shrinking targets, heart pickups, pitched feedback,
  best score kept across launches
- `lib/games/sliding_puzzle/` — thinking game: animated slides, move and time counters, fewest
  moves kept as the record, shuffle-by-legal-moves so every board is solvable
