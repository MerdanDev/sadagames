# Game backlog

Candidate games for the collection, roughly in the order they should be built. Each one is
sized to be finished in a single session and to meet the bar in `game-engagement.md`.

Ordering rules: vary the genre so consecutive additions do not feel like the same game, start
with the ones that reuse patterns already in the repo, and keep anything needing new art or
audio assets until the asset question is settled (see Blocked below).

Effort is rough: **S** ≈ a focused session, **M** ≈ a session plus tuning, **L** ≈ needs its own
design pass first.

## Next up

| # | Game | Genre | Core loop | Record | Effort |
|---|---|---|---|---|---|
| 1 | Odd One Out | Perception | Tap the one tile whose colour differs; grid grows and the difference shrinks | Highest level | S |
| 2 | Colour Sequence | Memory | Four pads flash a growing sequence, repeat it back | Longest sequence | S |
| 3 | Stack Tower | Timing | A block slides across, tap to drop it; overhang is trimmed off | Tallest tower | S |

**Why these three first.** Each is one mechanic, needs no assets, and reuses what exists:
Odd One Out is a grid of tappable shapes like `PuzzleTile`; Colour Sequence gets its whole
personality from the pitch-shifted `effect.mp3` trick already used in Star Catcher; Stack Tower
is one moving rectangle and a `MoveToEffect`.

## After that

| # | Game | Genre | Core loop | Record | Effort |
|---|---|---|---|---|---|
| 4 | Snake | Arcade | Swipe to steer, eat, grow, avoid yourself | Longest snake | M |
| 5 | Memory Pairs | Thinking | Flip cards two at a time to find matching pairs | Fewest flips | M |
| 6 | One Tap Flyer | Reflex | Tap to flap through gaps that keep narrowing | Gaps passed | M |
| 7 | 2048 | Puzzle | Swipe to merge equal tiles | Highest tile | M |
| 8 | Sky Hopper | Doodle/platformer | Auto-jump upward, drag to steer between platforms | Height climbed | L |
| 9 | Endless Runner | Doodle/runner | Auto-run, tap to jump obstacles that speed up | Distance | L |

Sky Hopper is the "doodle game" shape most people picture. It is last of the doodle set on
purpose: it needs a scrolling camera, procedural platform generation and a fall-death rule,
which is a genuine design pass rather than a single mechanic.

## Comeback mechanics to design in

Requirement 4 says a run must not be pure attrition. Per game:

- Odd One Out, Colour Sequence — one forgiving mistake per run, shown as a spare life
- Stack Tower, Snake — a rare bonus that widens the block or shrinks the tail
- One Tap Flyer, Sky Hopper, Endless Runner — a shield pickup that eats one collision
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
- **Rhythm games** — need licensed music, not one looping clip.
- **Two-player or online** — out of scope while the app is a single-player local collection.
- **Tic-tac-toe and similar** — no natural per-run record, so they fail requirement 5. Would
  need a streak-based framing to earn a slot.
