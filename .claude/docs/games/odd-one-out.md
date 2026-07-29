# Odd One Out

`lib/games/odd_one_out/` — a perception game, and the quickest of the collection to build.

**The loop.** One tile in the grid is a shade off. Tap it before the timer runs out. A wrong tap
or a timeout costs a life; three lost and the run ends.

## How it gets harder

Three things tighten at once, all tied to the level:

- the grid grows, 2×2 up to 5×5, every three levels
- the colours converge, gap `0.30 → 0.045` in lightness
- the clock shortens, `6.0 → 2.5` seconds

## Comeback

A life comes back every `levelsPerExtraLife` (5) levels cleared, capped at `maxLives`. An early
slip therefore does not doom a good run.

## Worth knowing

- The hue rotates per level (`level * 37`), so consecutive boards do not look alike.
- The odd tile is always *lighter*, never darker — one direction is easier to learn than two.
- The time bar turns red under 30%, so the warning is not carried by position alone.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Impossible late on | `_minColourGap`, `_minSeconds` |
| Too easy early | `_startColourGap`, `_startSeconds` |
| Grid grows too fast | the `(level - 1) ~/ 3` step in `gridSize` |
