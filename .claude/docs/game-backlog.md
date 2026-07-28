# Game backlog

Candidate games for the collection, roughly in the order they should be built. Each one is
sized to be finished in a single session and to meet the bar in `game-engagement.md`.

Ordering rules: vary the genre so consecutive additions do not feel like the same game, start
with the ones that reuse patterns already in the repo, and keep anything needing new art or
audio assets until the asset question is settled (see Blocked below).

Effort is rough: **S** ≈ a focused session, **M** ≈ a session plus tuning, **L** ≈ needs its own
design pass first.

## Shipped

- **Odd One Out** — `lib/games/odd_one_out/`. Perception; record is the furthest level.
- **Colour Sequence** — `lib/games/colour_sequence/`. Memory; record is rounds repeated.
- **Block Fit** — `lib/games/block_fit/`. Block puzzle; record is the high score.
- **Stack Tower** — `lib/games/stack_tower/`. Timing; record is the tallest tower.

## What actually sells on the Play Store

Checked July 2026. The pattern behind the top simple games is worth copying even though the
titles are not:

- **Block Blast** (300M+ downloads) and the whole `1010!`-style block-fitting genre are the
  clearest hit shape right now: drag pieces onto a grid, clear lines, no timer, endless.
- **Subway Surfers** (4B+ lifetime) and **Slice It All** are the endless-runner and
  satisfying-physics shapes; already covered below by Endless Runner.
- **Magic Tiles 3** shows the piano-tile shape still performs — and it maps neatly onto the
  pitch-shifted audio trick this repo already uses.
- **Crossy Road** remains the reference for tap-to-hop arcade.
- Merge and match-3 (**Merge Mansion**, **Candy Crush**) dominate by revenue, but both need
  content pipelines and art, which is the wrong shape for this collection.

Common thread: one mechanic, playable offline in seconds, endless rather than level-packed.
That is the same bar as `game-engagement.md`, so the list below is ordered to match.

## Next up

| # | Game | Genre | Core loop | Record | Effort |
|---|---|---|---|---|---|
| 1 | Tile Tap | Rhythm/reflex | Tap the dark tiles as the column scrolls, faster each row | Tiles tapped | S |

**Why this next.** It is one mechanic, needs no assets, and gets its whole feel from pitching
`effect.mp3` per column, which costs nothing.

## After that

| # | Game | Genre | Core loop | Record | Effort |
|---|---|---|---|---|---|
| 4 | Snake | Arcade | Swipe to steer, eat, grow, avoid yourself | Longest snake | M |
| 5 | Memory Pairs | Thinking | Flip cards two at a time to find matching pairs | Fewest flips | M |
| 6 | One Tap Flyer | Reflex | Tap to flap through gaps that keep narrowing | Gaps passed | M |
| 7 | 2048 | Puzzle | Swipe to merge equal tiles | Highest tile | M |
| 8 | Road Hop | Arcade | Tap to hop forward, dodge the traffic, never stop | Squares crossed | M |
| 9 | Sky Hopper | Doodle/platformer | Auto-jump upward, drag to steer between platforms | Height climbed | L |
| 10 | Endless Runner | Doodle/runner | Auto-run, tap to jump obstacles that speed up | Distance | L |

Sky Hopper is the "doodle game" shape most people picture. It is last of the doodle set on
purpose: it needs a scrolling camera, procedural platform generation and a fall-death rule,
which is a genuine design pass rather than a single mechanic.

## Comeback mechanics to design in

Requirement 4 says a run must not be pure attrition. Per game:

- Tile Tap — one skipped row, earned rather than given (Block Fit ships the earned tray swap)
- Snake — a rare bonus that shrinks the tail (Stack Tower ships the perfect-drop widening)
- One Tap Flyer, Road Hop, Sky Hopper, Endless Runner — a shield that eats one collision
- Memory Pairs, 2048 — a single undo, since these are thinking games rather than reflex ones

## Cross-cutting work

Worth doing between games rather than saving up:

- **Sound.** Everything shares one `effect.mp3` pitched up and down. A handful of small clips
  (catch, fail, win, tick) would lift every game at once. Needs sourcing licensed audio.
- **Haptics.** `HapticFeedback.selectionClick()` on hits and `heavyImpact()` on failure is a
  couple of lines per game and makes taps feel real.
- **Records screen.** Once there are more than about six games, a single screen listing every
  personal best is more satisfying than a line per tile.
- **Menu polish.** Group games by genre, or sort recently played first, when the list gets long
  enough to scroll.
- **Localisation.** Game names and in-game copy are currently plain strings. Move them into the
  `l10n` ARB files before the copy spreads much further.
- **CI.** The template ships GitHub Actions in `.github/`; wire it up so analyze and tests run
  on every push.

## Blocked or deliberately skipped

- **Word games** — need an offline dictionary, which is a real asset decision (size, licence,
  language). Revisit if the collection goes in a word direction.
- **Rhythm games proper** — need licensed music, not one looping clip. Tile Tap above is the
  cheap version: it uses pitch, not a song.
- **Match-3 and merge** — the biggest earners on the store, but both need an art and content
  pipeline that a shapes-only collection cannot feed.
- **Two-player or online** — out of scope while the app is a single-player local collection.
- **Tic-tac-toe and similar** — no natural per-run record, so they fail requirement 5. Would
  need a streak-based framing to earn a slot.
