# Colour Sequence

`lib/games/colour_sequence/` — Simon, and the first game to use the pitched audio properly.

**The loop.** Four pads flash a sequence; the player repeats it. Each round adds one pad.

**Each pad is a note.** Pad index maps to a scale degree, so the sequence is a little melody and
can be remembered by ear as well as by eye — which is the whole appeal of this game.

## How it gets harder

The sequence grows by one every round, and the flashes shorten with it, `0.50 → 0.22` s. Longer
*and* quicker.

## Comeback

`maxLives` is 2: the first slip only replays the same sequence, the second ends the run. One
forgiven mistake, which is enough to survive a lapse without making the game toothless.

## Worth knowing

- Taps are ignored while the sequence is playing, so a player cannot run ahead of it.
- The HUD says **Watch** or **Your turn**. A memory game with no state indicator feels broken.
- A mistake replays the sequence from the start rather than resuming mid-way.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Playback too slow to sit through | `_startFlash`, `_gapSeconds` |
| Unreadable at long lengths | `_minFlash` |
| Too long a wait before playback | `_leadInSeconds` |
