# Block Fit

`lib/games/block_fit/` — the `1010!` / Block Blast shape, and the genre currently doing the
numbers on the Play Store.

**The loop.** Three pieces sit in a tray. Drag one onto the eight by eight grid; fill a row or
a column and it clears. The run ends when none of the three pieces fits anywhere.

**No clock, by design.** The pressure is the board filling up. That is the genre, and adding a
timer would break it.

## How it gets harder

Bigger, more awkward pieces creep in as the score climbs: the chance of drawing from the large
set runs from 15% up to 55% (`score / 1500`, capped). Nothing else changes — the board itself
does the work.

## Scoring

One point per cell placed, then `lines² × 8` for a clear. One line is 8 points, two at once is
32. That gap is deliberate: setting a double up should beat taking two singles.

## Comeback

Eight cleared lines earn a **tray swap** (`linesPerSwap`, capped at `maxSwaps` = 3), which
replaces all three pieces. It is the way out when nothing fits.

## Worth knowing

- Pieces are matched to tray slots by an explicit `slot` index, not by shape. Shapes are
  `const` and repeat, so two identical pieces would otherwise collide.
- Clearing spawns a throwaway `ClearedCell` per square that pops and fades. The grid empties
  immediately: the animation is decoration and can never leave the board half cleared. A square
  can be refilled while its old cell is still fading.
- Cells clearing along a line are staggered by `_sweepPerCell` (0.022 s) so a clear sweeps.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Pieces get nasty too quickly | the `0.15 + score / 1500` curve in `_rollShape` |
| Clears feel unrewarding | the `cleared * cleared * gridSize` term |
| Swaps too rare or too generous | `linesPerSwap`, `maxSwaps` |
| The clear animation drags | `_sweepPerCell`, and the durations in `ClearedCell` |
