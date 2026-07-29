# Sliding Puzzle

`lib/games/sliding_puzzle/` — the classic three by three tile puzzle.

**The loop.** Tap a tile next to the gap to slide it. Get 1–8 back in order to win. There is no
losing state.

## The one rule that matters

**Every shuffle is solvable.** The board is scrambled by replaying `_shuffleMoves` (80) random
*legal* moves from the solved state, and reshuffled if it happens to land solved. A random
permutation would be unsolvable half the time — that is the classic trap with this puzzle.

## Record

Fewest **moves**, so this is the one game whose record uses `RecordGoal.lower`. Time is tracked
and shown but not recorded.

## Comeback

None, and none is needed: there is no clock and no failure state, so a bad position costs only
patience.

## Worth knowing

- The timer starts on the first move, not when the page opens.
- Tiles fade blue to purple in solved order, so the finished state reads as a gradient.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Slides feel sluggish | `_slideDuration` |
| Shuffles too easy or too brutal | `_shuffleMoves` |
| Want a bigger board | `gridSize` — but `tileCount` and the layout follow from it |
